import AVFoundation
import UIKit

/// Every sound in Trasher is synthesized at launch — no bundled audio
/// files — so the whole game stays tiny and fully offline. Ambient layers
/// crossfade as the story moves through city -> drain -> canal -> facility
/// -> park; a couple of one-shot buffers cover impacts and success.
@MainActor
final class SoundEngine {

    private enum Layer: CaseIterable {
        case city, rain, water, machinery, sparkle
    }

    private let engine = AVAudioEngine()
    private let sampleRate: Double = 24_000

    private var loopPlayers: [Layer: AVAudioPlayerNode] = [:]
    private var currentVolume: [Layer: Float] = [:]
    private var rampGeneration = 0

    private let impactPlayers = [AVAudioPlayerNode(), AVAudioPlayerNode(), AVAudioPlayerNode()]
    private var nextImpactIndex = 0
    private let successPlayer = AVAudioPlayerNode()

    private var impactSample: AVAudioPCMBuffer!
    private var successSample: AVAudioPCMBuffer!

    init() {
        configureSession()
        buildBuffersAndGraph()
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
        // --- Ambient loop layers -------------------------------------------------
        let city = makeBuffer(duration: 5.0, fadeEdges: true) { t in
            let hum = 0.5 * sin(2 * .pi * 55 * t)
                + 0.3 * sin(2 * .pi * 110.5 * t)
                + 0.15 * sin(2 * .pi * 220 * t)
            let tremolo = 0.85 + 0.15 * sin(2 * .pi * 0.2 * t)
            return Float(hum * tremolo) * 0.18
        }

        var rainLP: Float = 0
        let rain = makeBuffer(duration: 3.0, fadeEdges: true) { _ in
            let n = Float.random(in: -1...1)
            rainLP = rainLP * 0.86 + n * 0.14
            return rainLP * 0.7
        }

        var waterLP: Float = 0
        let water = makeBuffer(duration: 4.0, fadeEdges: true) { t in
            let n = Float.random(in: -1...1)
            waterLP = waterLP * 0.93 + n * 0.07
            let swell = 0.7 + 0.3 * sin(2 * .pi * 0.1 * t)
            return Float(waterLP) * Float(swell) * 0.55
        }

        let machinery = makeBuffer(duration: 2.0, fadeEdges: true) { t in
            let hum = sin(2 * .pi * 90 * t) * 0.15
            let phase = (t * 2.5).truncatingRemainder(dividingBy: 1.0)
            let clank = phase < 0.08 ? sin(.pi * phase / 0.08) * 0.45 : 0
            return Float(hum + clank)
        }

        let sparkle = makeBuffer(duration: 4.0, fadeEdges: true) { t in
            let a = sin(2 * .pi * 880 * t) * 0.06
            let b = sin(2 * .pi * 1320 * t + 0.5) * 0.04
            let trem = 0.5 + 0.5 * sin(2 * .pi * 0.3 * t)
            return Float((a + b) * trem)
        }

        let buffers: [Layer: AVAudioPCMBuffer] = [
            .city: city, .rain: rain, .water: water, .machinery: machinery, .sparkle: sparkle
        ]

        for layer in Layer.allCases {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: monoFormat())
            node.volume = 0
            loopPlayers[layer] = node
            currentVolume[layer] = 0
        }

        // --- One-shot SFX ---------------------------------------------------------
        impactSample = makeBuffer(duration: 0.18) { t in
            var lp: Float = 0
            let n = Float.random(in: -1...1)
            lp = lp * 0.7 + n * 0.3
            let env = Float(exp(-t * 18))
            return lp * env * 0.9
        }

        let notes: [Double] = [523.25, 659.25, 783.99, 1046.5]
        let noteDuration = 0.14
        successSample = makeBuffer(duration: noteDuration * Double(notes.count)) { t in
            let idx = min(notes.count - 1, Int(t / noteDuration))
            let freq = notes[idx]
            let localT = t - Double(idx) * noteDuration
            let env = sin(.pi * min(1, localT / noteDuration))
            return Float(sin(2 * .pi * freq * t) * env) * 0.5
        }

        for node in impactPlayers {
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: monoFormat())
        }
        engine.attach(successPlayer)
        engine.connect(successPlayer, to: engine.mainMixerNode, format: monoFormat())

        engine.prepare()
        try? engine.start()

        for (layer, node) in loopPlayers {
            node.scheduleBuffer(buffers[layer]!, at: nil, options: .loops)
            node.play()
        }
    }

    // MARK: - Public API

    func transition(to phase: GameState.Phase) {
        let target: [Layer: Float]
        var masterVolume: Float = 1.0

        switch phase {
        case .opening:
            target = [.city: 0.45, .rain: 0, .water: 0, .machinery: 0, .sparkle: 0.05]
        case .streetToDrain:
            target = [.city: 0.22, .rain: 0.55, .water: 0.12, .machinery: 0, .sparkle: 0]
        case .canal:
            target = [.city: 0.05, .rain: 0.12, .water: 0.5, .machinery: 0, .sparkle: 0]
        case .seaFailure:
            target = [.city: 0, .rain: 0.05, .water: 0.25, .machinery: 0, .sparkle: 0]
            masterVolume = 0.5
        case .recycling:
            target = [.city: 0, .rain: 0, .water: 0.08, .machinery: 0.5, .sparkle: 0.15]
        case .ending:
            target = [.city: 0.08, .rain: 0, .water: 0.05, .machinery: 0, .sparkle: 0.45]
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

    func success() {
        successPlayer.stop()
        successPlayer.scheduleBuffer(successSample, at: nil)
        successPlayer.play()
    }

    func muffle() {
        // Reserved for future use; sea-route hush is handled by transition(to:).
    }
}

/// Haptics used only for obstacle collisions and recycling success, per spec.
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
