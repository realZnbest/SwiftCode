import AVFoundation
import UIKit

/// Every sound in Trasher is synthesized at launch — no bundled audio
/// files — so the whole game stays tiny and fully offline. Ambient noise
/// layers (city hum, rain, water, machinery, sparkle) crossfade as the
/// story moves through title -> city -> drain -> canal -> facility ->
/// montage -> park, plus impact/success one-shots for feedback — no
/// background music or melodic score, just atmosphere and SFX, run through
/// a shared reverb send so everything feels like it's in the same space
/// instead of dry synthesizer test tones.
@MainActor
final class SoundEngine {

    private enum Layer: CaseIterable {
        case city, rain, water, machinery, sparkle
    }

    private let engine = AVAudioEngine()
    private let reverb = AVAudioUnitReverb()
    private let sampleRate: Double = 24_000

    private var loopPlayers: [Layer: AVAudioPlayerNode] = [:]
    private var currentVolume: [Layer: Float] = [:]
    private var rampGeneration = 0

    private let impactPlayers = [AVAudioPlayerNode(), AVAudioPlayerNode(), AVAudioPlayerNode()]
    private var nextImpactIndex = 0
    private let successPlayer = AVAudioPlayerNode()
    private let thunderPlayer = AVAudioPlayerNode()

    private var impactSample: AVAudioPCMBuffer!
    private var successSample: AVAudioPCMBuffer!
    private var thunderSample: AVAudioPCMBuffer!

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

        // Filtered noise with a fluttering amplitude, not tones — reads as
        // an airy glinting texture rather than a chime or musical interval.
        // A single slow, gentle swell — not the fast dual-rate flutter this
        // had before, which beat together into an irregular pattering
        // rhythm that read as footsteps running in the background instead
        // of a quiet ambient shimmer.
        var sparkleLP: Float = 0
        let sparkle = makeBuffer(duration: 4.0, fadeEdges: true) { t in
            let n = Float.random(in: -1...1)
            sparkleLP = sparkleLP * 0.7 + n * 0.3
            let shimmer = 0.6 + 0.4 * sin(2 * .pi * 0.4 * t)
            return sparkleLP * Float(shimmer) * 0.07
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

        // A bright noise burst, not a melodic phrase — a fast attack and
        // fluttering texture reads as a satisfying "success" sting on its
        // dynamics alone, without spelling out any notes.
        var successLP: Float = 0
        successSample = makeBuffer(duration: 0.45) { t in
            let n = Float.random(in: -1...1)
            successLP = successLP * 0.4 + n * 0.6
            let env = Float(min(1, t / 0.03)) * Float(exp(-t * 5))
            let flutter = 0.6 + 0.4 * sin(2 * .pi * 14 * t)
            return successLP * env * Float(flutter) * 0.9
        }

        // A distant, low thunder rumble for the storm's occasional lightning.
        var thunderLP: Float = 0
        thunderSample = makeBuffer(duration: 1.4) { t in
            let n = Float.random(in: -1...1)
            thunderLP = thunderLP * 0.975 + n * 0.025
            let env = Float(min(1, t / 0.08)) * Float(exp(-t * 1.6))
            let rumble = sin(2 * .pi * 42 * t) * 0.3
            return (thunderLP * 1.6 + Float(rumble)) * env * 0.8
        }

        for node in impactPlayers {
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: monoFormat())
        }
        engine.attach(successPlayer)
        engine.connect(successPlayer, to: engine.mainMixerNode, format: monoFormat())
        engine.attach(thunderPlayer)
        engine.connect(thunderPlayer, to: engine.mainMixerNode, format: monoFormat())

        // Shared reverb send: routes the whole mix through a bright plate
        // reverb before it reaches the speakers, so every layer feels like
        // it's in the same wide, glossy space instead of dry test tones.
        engine.attach(reverb)
        reverb.loadFactoryPreset(.plate)
        reverb.wetDryMix = 24
        engine.connect(engine.mainMixerNode, to: reverb, format: nil)
        engine.connect(reverb, to: engine.outputNode, format: nil)

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
        case .title:
            target = [.city: 0.28, .rain: 0, .water: 0, .machinery: 0, .sparkle: 0.08]
        case .factoryOrigin:
            target = [.city: 0.1, .rain: 0, .water: 0, .machinery: 0.3, .sparkle: 0.1]
        case .opening:
            target = [.city: 0.45, .rain: 0, .water: 0, .machinery: 0, .sparkle: 0.05]
        case .streetToDrain:
            target = [.city: 0.22, .rain: 0.55, .water: 0.12, .machinery: 0, .sparkle: 0]
        case .stormDrainTunnel:
            target = [.city: 0.05, .rain: 0.3, .water: 0.35, .machinery: 0.1, .sparkle: 0]
            masterVolume = 0.8
        case .landfillFailure:
            target = [.city: 0, .rain: 0.04, .water: 0.04, .machinery: 0.18, .sparkle: 0]
            masterVolume = 0.5
        case .secondBottleMirror:
            target = [.city: 0, .rain: 0.08, .water: 0.35, .machinery: 0, .sparkle: 0]
            masterVolume = 0.6
        case .canal:
            target = [.city: 0.05, .rain: 0.12, .water: 0.5, .machinery: 0, .sparkle: 0]
        case .seaFailure:
            target = [.city: 0, .rain: 0.05, .water: 0.25, .machinery: 0, .sparkle: 0]
            masterVolume = 0.5
        case .nightIntoDay:
            target = [.city: 0.05, .rain: 0, .water: 0.3, .machinery: 0, .sparkle: 0.2]
        case .fishingNetRescue:
            target = [.city: 0, .rain: 0, .water: 0.25, .machinery: 0.1, .sparkle: 0.25]
        case .sortingLine:
            target = [.city: 0, .rain: 0, .water: 0.05, .machinery: 0.4, .sparkle: 0.12]
        case .recycling:
            target = [.city: 0, .rain: 0, .water: 0.08, .machinery: 0.5, .sparkle: 0.15]
        case .pelletReveal:
            target = [.city: 0, .rain: 0, .water: 0.05, .machinery: 0.25, .sparkle: 0.35]
        case .truckDelivery:
            target = [.city: 0.15, .rain: 0, .water: 0, .machinery: 0.2, .sparkle: 0.2]
        case .montage:
            target = [.city: 0.1, .rain: 0, .water: 0.05, .machinery: 0, .sparkle: 0.3]
        case .communityCleanup:
            target = [.city: 0.1, .rain: 0, .water: 0.08, .machinery: 0, .sparkle: 0.4]
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

    /// A distant rumble timed to the street scene's occasional lightning
    /// flash, for a bit of storm drama.
    func thunder() {
        thunderPlayer.stop()
        thunderPlayer.scheduleBuffer(thunderSample, at: nil)
        thunderPlayer.play()
    }

    func muffle() {
        // Reserved for future use; failure-route hush is handled by transition(to:).
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
