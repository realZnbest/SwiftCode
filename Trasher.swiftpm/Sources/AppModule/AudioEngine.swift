import AVFoundation
import UIKit

@MainActor
final class SoundEngine {

    private enum Layer: CaseIterable {
        case city, rain, deepWater, machinery, birds
    }

    private let engine = AVAudioEngine()
    private let reverb = AVAudioUnitReverb()
    private let sampleRate: Double = 24_000

    private var loopPlayers: [Layer: AVAudioPlayerNode] = [:]
    private var loopBuffers: [Layer: AVAudioPCMBuffer] = [:]
    private var currentVolume: [Layer: Float] = [:]
    private var rampGeneration = 0
    private var suspended = false
    private var observers: [Any] = []
    private var currentPhase: GameState.Phase = .title

    private let impactPlayers = [AVAudioPlayerNode(), AVAudioPlayerNode(), AVAudioPlayerNode()]
    private var nextImpactIndex = 0
    private let successPlayer = AVAudioPlayerNode()
    private let chompPlayer = AVAudioPlayerNode()
    private let splashPlayer = AVAudioPlayerNode()

    private var impactSample: AVAudioPCMBuffer!
    private var successSample: AVAudioPCMBuffer!
    private var chompSample: AVAudioPCMBuffer!
    private var splashSample: AVAudioPCMBuffer!

    init() {
        configureSession()
        buildBuffersAndGraph()
        setupNotificationObservers()
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    private func monoFormat() -> AVAudioFormat {
        AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    }

    private func makeBuffer(duration: Double, fadeEdges: Bool = false, generator: (Double) -> Float) -> AVAudioPCMBuffer {
        let frameCount = max(1, Int(duration * sampleRate))
        let buffer = AVAudioPCMBuffer(pcmFormat: monoFormat(), frameCapacity: AVAudioFrameCount(frameCount))!
        buffer.frameLength = AVAudioFrameCount(frameCount)
        let data = buffer.floatChannelData![0]
        let fadeSamples = fadeEdges ? Int(0.04 * sampleRate) : 0
        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            var v = generator(t)
            if fadeEdges {
                if i < fadeSamples { v *= Float(i) / Float(max(fadeSamples, 1)) }
                if i > frameCount - fadeSamples { v *= Float(frameCount - i) / Float(max(fadeSamples, 1)) }
            }
            data[i] = v
        }
        return buffer
    }

    private func buildBuffersAndGraph() {

        let city = makeBuffer(duration: 6.0, fadeEdges: true) { t in
            let hum = 0.55 * sin(2 * .pi * 55 * t)
                + 0.28 * sin(2 * .pi * 110.5 * t)
                + 0.08 * sin(2 * .pi * 220 * t)
            let breathe = 0.88 + 0.12 * sin(2 * .pi * 0.11 * t)
            return Float(hum * breathe) * 0.18
        }

        var rainLP: Float = 0
        let rain = makeBuffer(duration: 3.0, fadeEdges: true) { _ in
            let n = Float.random(in: -1...1)
            rainLP = rainLP * 0.94 + n * 0.06
            return rainLP * 0.6
        }

        let deepWater = makeBuffer(duration: 10.0, fadeEdges: true) { t in
            let wobble = 2.5 * sin(2 * .pi * 0.13 * t)
            let fundamental = sin(2 * .pi * (58 + wobble) * t)
            let partial = 0.35 * sin(2 * .pi * 87 * t + 0.7)
            let swell = 0.82 + 0.18 * sin(2 * .pi * 0.07 * t)
            return Float((fundamental + partial) * swell) * 0.24
        }

        let machinery = makeBuffer(duration: 3.2, fadeEdges: true) { t in
            let hum = 0.14 * sin(2 * .pi * 80 * t) + 0.05 * sin(2 * .pi * 160 * t)
            let phase = t.truncatingRemainder(dividingBy: 1.6)
            let thump = phase < 0.25 ? sin(2 * .pi * 55 * phase) * exp(-phase * 14) * 0.3 : 0
            return Float(hum + thump)
        }

        func chirp(_ t: Double, start: Double, dur: Double, f0: Double, f1: Double, amp: Double) -> Double {
            let x = (t - start) / dur
            guard x >= 0 && x < 1 else { return 0 }
            let f = f0 + (f1 - f0) * x
            let env = sin(.pi * x)
            let warble = 1 + 0.05 * sin(2 * .pi * 28 * (t - start))
            return sin(2 * .pi * f * warble * (t - start)) * env * amp
        }
        let birds = makeBuffer(duration: 10.0, fadeEdges: true) { t in
            var v = 0.0
            v += chirp(t, start: 0.7, dur: 0.14, f0: 2900, f1: 3500, amp: 0.05)
            v += chirp(t, start: 0.95, dur: 0.1, f0: 3300, f1: 2800, amp: 0.04)
            v += chirp(t, start: 4.3, dur: 0.18, f0: 2500, f1: 3100, amp: 0.05)
            v += chirp(t, start: 7.6, dur: 0.12, f0: 3100, f1: 3600, amp: 0.045)
            v += chirp(t, start: 7.85, dur: 0.1, f0: 3600, f1: 3000, amp: 0.035)
            return Float(v)
        }

        let buffers: [Layer: AVAudioPCMBuffer] = [
            .city: city, .rain: rain, .deepWater: deepWater, .machinery: machinery, .birds: birds
        ]
        loopBuffers = buffers

        for layer in Layer.allCases {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: monoFormat())
            node.volume = 0
            loopPlayers[layer] = node
            currentVolume[layer] = 0
        }

        var impactLP: Float = 0
        impactSample = makeBuffer(duration: 0.18) { t in
            let n = Float.random(in: -1...1)
            impactLP = impactLP * 0.75 + n * 0.25
            let env = Float(exp(-t * 20))
            let body = Float(sin(2 * .pi * 70 * t)) * Float(exp(-t * 24)) * 0.5
            return impactLP * env * 0.7 + body
        }

        var chompLP: Float = 0
        chompSample = makeBuffer(duration: 0.16) { t in
            let n = Float.random(in: -1...1)
            chompLP = chompLP * 0.6 + n * 0.4
            let crunch = t < 0.04 ? chompLP * Float(1 - t / 0.04) * 0.5 : 0
            let f = 160.0 - 95.0 * min(1, t / 0.12)
            let body = Float(sin(2 * .pi * f * t)) * Float(exp(-t * 26)) * 0.8
            return body + crunch
        }

        var splashLP: Float = 0
        splashSample = makeBuffer(duration: 0.55) { t in
            let n = Float.random(in: -1...1)
            let c = Float(min(0.94, 0.6 + t * 1.0))
            splashLP = splashLP * c + n * (1 - c)
            let env = Float(exp(-t * 7))
            let bloopF = 220.0 - 140.0 * min(1, t / 0.18)
            let bloop = t < 0.2 ? Float(sin(2 * .pi * bloopF * t)) * Float(exp(-t * 12)) * 0.4 : 0
            return splashLP * env * 1.1 + bloop
        }

        var popLP: Float = 0
        func pop(_ t: Double, start: Double, coeff: Float, amp: Float) -> Float {
            let x = t - start
            guard x >= 0 && x < 0.09 else { return 0 }
            let n = Float.random(in: -1...1)
            popLP = popLP * coeff + n * (1 - coeff)
            return popLP * Float(exp(-x * 45)) * amp
        }
        successSample = makeBuffer(duration: 0.5) { t in
            var v = pop(t, start: 0, coeff: 0.8, amp: 0.55)
            v += pop(t, start: 0.16, coeff: 0.55, amp: 0.6)
            if t >= 0.16 && t < 0.3 {
                let x = (t - 0.16) / 0.14
                let f = 480 + 380 * x
                v += Float(sin(2 * .pi * f * (t - 0.16))) * Float(sin(.pi * x)) * 0.18
            }
            return v
        }

        for node in impactPlayers {
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: monoFormat())
        }
        for node in [successPlayer, chompPlayer, splashPlayer] {
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: monoFormat())
        }

        engine.attach(reverb)
        reverb.loadFactoryPreset(.plate)
        reverb.wetDryMix = 18
        engine.connect(engine.mainMixerNode, to: reverb, format: nil)
        engine.connect(reverb, to: engine.outputNode, format: nil)

        engine.prepare()
        try? engine.start()

        for (layer, node) in loopPlayers {
            node.scheduleBuffer(buffers[layer]!, at: nil, options: .loops)
            node.play()
        }
    }

    func transition(to phase: GameState.Phase) {
        currentPhase = phase
        let target: [Layer: Float]
        var masterVolume: Float = 1.0

        switch phase {
        case .title:
            target = [.city: 0.22, .rain: 0, .deepWater: 0, .machinery: 0, .birds: 0]
        case .factoryOrigin:
            target = [.city: 0.06, .rain: 0, .deepWater: 0, .machinery: 0.28, .birds: 0]
        case .deliveryTruck:
            target = [.city: 0.18, .rain: 0, .deepWater: 0, .machinery: 0.12, .birds: 0]
        case .vendingAndDiscard:
            target = [.city: 0.3, .rain: 0.15, .deepWater: 0, .machinery: 0.08, .birds: 0]
        case .streetToDrain:
            target = [.city: 0.15, .rain: 0.5, .deepWater: 0, .machinery: 0, .birds: 0]
        case .stormDrainTunnel:
            target = [.city: 0, .rain: 0, .deepWater: 0.4, .machinery: 0, .birds: 0]
            masterVolume = 0.8
        case .landfillFailure:
            target = [.city: 0, .rain: 0, .deepWater: 0.1, .machinery: 0.14, .birds: 0]
            masterVolume = 0.5
        case .secondBottleMirror:
            target = [.city: 0, .rain: 0, .deepWater: 0.32, .machinery: 0, .birds: 0]
            masterVolume = 0.65
        case .canal:
            target = [.city: 0.04, .rain: 0, .deepWater: 0.35, .machinery: 0, .birds: 0]
        case .seaFailure:
            target = [.city: 0, .rain: 0, .deepWater: 0.22, .machinery: 0, .birds: 0]
            masterVolume = 0.5
        case .nightIntoDay:
            target = [.city: 0, .rain: 0, .deepWater: 0.08, .machinery: 0, .birds: 0.14]
        case .fishingNetRescue:
            target = [.city: 0, .rain: 0, .deepWater: 0.15, .machinery: 0, .birds: 0.12]
        case .sortingLine:
            target = [.city: 0, .rain: 0, .deepWater: 0, .machinery: 0.32, .birds: 0]
        case .recycling:
            target = [.city: 0, .rain: 0, .deepWater: 0, .machinery: 0.42, .birds: 0]
        case .pelletReveal:
            target = [.city: 0, .rain: 0, .deepWater: 0, .machinery: 0.1, .birds: 0.12]
        case .truckDelivery:
            target = [.city: 0.14, .rain: 0, .deepWater: 0, .machinery: 0.16, .birds: 0.06]
        case .montage:
            target = [.city: 0.07, .rain: 0, .deepWater: 0, .machinery: 0, .birds: 0.2]
        case .communityCleanup:
            target = [.city: 0, .rain: 0, .deepWater: 0, .machinery: 0, .birds: 0.28]
        case .ending:
            target = [.city: 0, .rain: 0, .deepWater: 0, .machinery: 0, .birds: 0.32]
        }

        rampVolumes(to: target, master: masterVolume, duration: 1.4)
    }

    private func rampVolumes(to target: [Layer: Float], master: Float, duration: Double) {
        rampGeneration += 1
        let generation = rampGeneration
        let start = currentVolume
        let startMaster = engine.mainMixerNode.outputVolume
        let steps = 24
        let stepDuration = duration / Double(steps)

        for step in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(step)) { [weak self] in
                guard let self, self.rampGeneration == generation else { return }
                let f = Float(step) / Float(steps)
                for layer in Layer.allCases {
                    let from = start[layer] ?? 0
                    let to = target[layer] ?? 0
                    let v = from + (to - from) * f
                    self.loopPlayers[layer]?.volume = v
                    self.currentVolume[layer] = v
                }
                self.engine.mainMixerNode.outputVolume = startMaster + (master - startMaster) * f
            }
        }
    }

    func impactThud() {
        let node = impactPlayers[nextImpactIndex]
        nextImpactIndex = (nextImpactIndex + 1) % impactPlayers.count
        node.stop()
        node.scheduleBuffer(impactSample, at: nil)
        node.play()
    }

    func chomp() {
        chompPlayer.stop()
        chompPlayer.scheduleBuffer(chompSample, at: nil)
        chompPlayer.play()
    }

    func splash() {
        splashPlayer.stop()
        splashPlayer.scheduleBuffer(splashSample, at: nil)
        splashPlayer.play()
    }

    func success() {
        successPlayer.stop()
        successPlayer.scheduleBuffer(successSample, at: nil)
        successPlayer.play()
    }

    func muffle() {
    }

    func suspend() {
        guard !suspended else { return }
        suspended = true
        rampGeneration += 1

        for node in loopPlayers.values {
            node.stop()
            node.volume = 0
        }
        for node in impactPlayers { node.stop() }
        for node in [successPlayer, chompPlayer, splashPlayer] { node.stop() }
        for layer in Layer.allCases { currentVolume[layer] = 0 }

        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    func resume() {
        guard suspended else { return }
        suspended = false

        configureSession()
        engine.prepare()
        try? engine.start()

        for (layer, node) in loopPlayers {
            guard let buffer = loopBuffers[layer] else { continue }
            node.scheduleBuffer(buffer, at: nil, options: .loops)
            node.volume = 0
            node.play()
        }
        
        transition(to: currentPhase)
    }

    private func setupNotificationObservers() {
        let center = NotificationCenter.default
        
        let stopResign = center.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.suspend()
            }
        }
        
        let stopBackground = center.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.suspend()
            }
        }
        
        let stopTerminate = center.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.suspend()
            }
        }
        
        let startActive = center.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.resume()
            }
        }
        
        observers = [stopResign, stopBackground, stopTerminate, startActive]
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        for node in loopPlayers.values {
            node.stop()
        }
        for node in impactPlayers {
            node.stop()
        }
        successPlayer.stop()
        chompPlayer.stop()
        splashPlayer.stop()
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }
}

enum Haptics {
    static func collision() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    static func warning() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred(intensity: 0.6)
    }
}
