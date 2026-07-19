import SwiftUI

/// One continuous street beat, combining what used to be two separate
/// scenes: five passersby kick the bottle along, one at a time — each one
/// fully arrives, kicks, and walks off before the next one enters, never
/// overlapping — two kicks sending it left, three sending it right, net
/// drifting right; then a stray dog trots in from the right, grabs it,
/// gives it a shake, and carries it all the way off the left edge of the
/// frame. Purely auto-paced, nothing for the player to do but watch it
/// get kicked around and then stolen. Unhurried on purpose — five distinct
/// people need room to each have their moment — before the actual choice
/// (the storm drain fork, down the grate toward the canal or swept toward
/// a passing garbage truck and landfill) arrives.
struct StreetToDrainScene: View {
    @EnvironmentObject var game: GameState

    private enum Stage { case intro, fork, resolving }

    private struct Kick {
        let time: Double
        let distance: CGFloat
    }

    private let bottleRowFrac: CGFloat = 0.80
    private let kickStartX: CGFloat = 0.15
    // Five kicks — right, left, right, left, right — 2 left/3 right, net
    // drift toward the right so the dog (entering from the right edge)
    // has somewhere to find the bottle. Spaced 2.3s apart: a KickerFigure
    // is only ever on screen for about 2s (see its own -1.15...0.85 local
    // window), so this gap guarantees one walker is fully gone before the
    // next arrives — never two people kicking at once.
    private let kicks: [Kick] = [
        Kick(time: 0.3, distance: 0.18),
        Kick(time: 2.6, distance: -0.08),
        Kick(time: 4.9, distance: 0.20),
        Kick(time: 7.2, distance: -0.07),
        Kick(time: 9.5, distance: 0.35)
    ]
    private var kickEndX: CGFloat { kicks.reduce(kickStartX) { $0 + $1.distance } }

    // Phase boundaries, in seconds since the scene appeared — see
    // `introState(at:)` for what happens in each. Kicks resolve by
    // `pounceStart` (the last kicker's walked fully off by then); the dog
    // then does its whole pounce/bite/shake/carry-off-left at an equally
    // unhurried pace afterward.
    private let pounceStart: Double = 10.8
    private let biteAt: Double = 11.4
    private let shakeEnd: Double = 11.8
    private let carryEnd: Double = 13.8
    private let dogExitEnd: Double = 14.2
    private let sequenceDuration: Double = 14.4

    @State private var stage: Stage = .intro
    @State private var sceneStart = Date()
    @State private var triggeredEvents: Set<String> = []
    @State private var flashOpacity: Double = 0
    @State private var choiceMade = false
    @State private var idleTask: Task<Void, Never>? = nil

    // Drag-to-drop fork, matching the recycling facility's own bottle-drag
    // mechanic: the bottle starts up top and the two outcomes sit as real
    // targets at the bottom, instead of a horizontal swipe-and-launch.
    @State private var forkBottlePos = CGPoint(x: 0.5, y: 0.22)
    @State private var forkDragBase = CGPoint(x: 0.5, y: 0.22)
    @State private var forkWrongFeedback = false
    private let landfillForkRect = CGRect(x: 0.08, y: 0.55, width: 0.30, height: 0.3)
    private let drainForkRect = CGRect(x: 0.62, y: 0.55, width: 0.30, height: 0.3)

    private var reduceMotion: Bool { game.reduceMotion }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                background

                RainCanvas(intensity: 1, reduceMotion: reduceMotion)
                GutterFlowCanvas(reduceMotion: reduceMotion, bottleRowFrac: bottleRowFrac)
                TrafficStreakCanvas(reduceMotion: reduceMotion)

                if stage == .intro {
                    TimelineView(.animation(minimumInterval: reduceMotion ? 0.2 : 1.0 / 45)) { context in
                        let raw = context.date.timeIntervalSince(sceneStart)
                        let elapsed = reduceMotion ? min(raw * 2.2, sequenceDuration) : raw
                        let s = introState(at: elapsed)

                        ZStack {
                            ForEach(Array(kicks.enumerated()), id: \.offset) { _, kick in
                                KickerFigure(
                                    localTime: elapsed - kick.time,
                                    footX: kickedXFrac(at: kick.time) * size.width,
                                    groundY: size.height * bottleRowFrac,
                                    direction: kick.distance >= 0 ? 1 : -1
                                )
                            }

                            // StrayDogView's own feet sit near the bottom of
                            // its frame (see its contact shadow), not at its
                            // center — offset upward here so `dogPos.y`
                            // means "where the paws touch the ground," not
                            // "where the frame's midpoint is." Mirrored
                            // horizontally since it was built facing right
                            // but this time runs in from the right and
                            // exits left.
                            StrayDogView(legPhase: s.legPhase)
                                .frame(width: 132 * s.dogScale, height: 100 * s.dogScale)
                                .scaleEffect(x: -1, y: 1)
                                .opacity(s.dogOpacity)
                                .position(x: s.dogPos.x * size.width, y: s.dogPos.y * size.height - 0.42 * 100 * s.dogScale)

                            BottleView(
                                vibrancy: game.vibrancy, dirt: game.grime, showEyes: false, glow: 0,
                                width: 62, height: 152, tilt: s.bottleTilt
                            )
                            .blur(radius: s.bottleBlur)
                            .position(x: s.bottlePos.x * size.width, y: s.bottlePos.y * size.height)
                        }
                        .onChange(of: elapsed) { _, newValue in
                            handleEvents(at: newValue)
                            if newValue > sequenceDuration {
                                enterFork()
                            }
                        }
                    }
                    .transition(.opacity)
                }

                if stage == .fork || stage == .resolving {
                    forkView(size: size)
                        .transition(.opacity.combined(with: .scale(scale: 0.94)))
                }

                Vignette(strength: 0.5)

                Color.white
                    .opacity(flashOpacity)
                    .blendMode(.plusLighter)
                    .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(stage == .intro
            ? "A rainy sidewalk. Passersby kick the bottle along, one at a time, until a stray dog runs in, grabs it, shakes it, and carries it off screen."
            : "The storm drain. Drag the bottle down into the garbage truck on the left, or the drain grate on the right toward the canal.")
        .onAppear(perform: setup)
    }

    private var background: some View {
        ZStack {
            LinearGradient(colors: [Theme.deepNavy, Theme.nearBlack], startPoint: .top, endPoint: .bottom)
            SkylineCanvas()
                .opacity(0.55)
            NeonStreakField(colors: [Theme.neonCyan, Theme.neonPurple, Theme.neonPink], reduceMotion: reduceMotion)
                .opacity(0.85)

            groundPlane

            // Wet pavement: a soft reflective band across the lower third.
            LinearGradient(colors: [.clear, Color.white.opacity(0.05), Color.white.opacity(0.02)],
                           startPoint: .top, endPoint: .bottom)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .frame(height: 260)
                .blendMode(.plusLighter)
        }
    }

    /// A concrete sidewalk slab at `bottleRowFrac`, the same treatment as
    /// the earlier sidewalk-kick beat — without it, the dog and bottle had
    /// nothing to actually stand on and read as floating in front of the
    /// skyline instead of running along a street.
    private var groundPlane: some View {
        GeometryReader { geo in
            let size = geo.size
            let groundY = size.height * bottleRowFrac
            ZStack(alignment: .top) {
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.06, blue: 0.08), Color(red: 0.02, green: 0.02, blue: 0.03)],
                    startPoint: .top, endPoint: .bottom
                )
                Rectangle().fill(Color.white.opacity(0.1)).frame(height: 2)
            }
            .frame(width: size.width, height: size.height - groundY)
            .position(x: size.width / 2, y: groundY + (size.height - groundY) / 2)
        }
    }

    /// The bottle starts up top and the two outcomes are real drop targets
    /// at the bottom — the same drag-a-bottle-into-a-bin mechanic as the
    /// recycling facility, instead of a horizontal swipe-and-launch, so the
    /// interaction feels identical everywhere the game asks the player to
    /// choose a fate for the bottle.
    private func forkView(size: CGSize) -> some View {
        let landfillBlocked = game.mustRouteToDrain
        let hoveringLandfill = !choiceMade && !landfillBlocked && landfillForkRect.contains(forkBottlePos)
        let hoveringDrain = !choiceMade && drainForkRect.contains(forkBottlePos)

        return ZStack {
            // Landfill / garbage truck path (left) — the wrong turn.
            PathChoiceIndicator(
                kind: .landfill,
                bright: hoveringLandfill,
                dim: landfillBlocked,
                containerSize: size
            )
            .position(x: landfillForkRect.midX * size.width, y: landfillForkRect.midY * size.height)

            // Storm drain path (right) — continues the story correctly.
            PathChoiceIndicator(
                kind: .stormDrain,
                bright: hoveringDrain,
                containerSize: size
            )
            .position(x: drainForkRect.midX * size.width, y: drainForkRect.midY * size.height)

            if forkWrongFeedback {
                Label("A truck already came through. Try the drain.", systemImage: "exclamationmark.triangle.fill")
                    .font(Theme.line(16))
                    .foregroundStyle(Theme.neonAmber)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Theme.nearBlack.opacity(0.78), in: Capsule())
                    .position(x: size.width * 0.5, y: size.height * 0.36)
                    .transition(.opacity)
            }

            BottleView(vibrancy: game.vibrancy, dirt: game.grime, showEyes: false, width: 62, height: 152)
                .position(x: forkBottlePos.x * size.width, y: forkBottlePos.y * size.height)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard !choiceMade else { return }
                    forkBottlePos = CGPoint(
                        x: min(0.95, max(0.05, forkDragBase.x + value.translation.width / size.width)),
                        y: min(0.95, max(0.05, forkDragBase.y + value.translation.height / size.height))
                    )
                }
                .onEnded { _ in
                    guard !choiceMade else { return }
                    evaluateForkDrop(landfillBlocked: landfillBlocked)
                }
        )
    }

    private func evaluateForkDrop(landfillBlocked: Bool) {
        forkDragBase = forkBottlePos
        if drainForkRect.contains(forkBottlePos) {
            resolveFork(towardDrain: true)
        } else if landfillForkRect.contains(forkBottlePos) {
            if landfillBlocked {
                withAnimation(.easeOut(duration: 0.35)) {
                    forkBottlePos = CGPoint(x: 0.5, y: 0.22)
                    forkWrongFeedback = true
                }
                forkDragBase = forkBottlePos
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1.6))
                    guard stage == .fork else { return }
                    withAnimation(.easeOut(duration: 0.25)) { forkWrongFeedback = false }
                }
            } else {
                resolveFork(towardDrain: false)
            }
        }
    }

    private func setup() {
        sceneStart = Date()
        choiceMade = false
        forkBottlePos = CGPoint(x: 0.5, y: 0.22)
        forkDragBase = forkBottlePos
        forkWrongFeedback = false
        triggeredEvents = []
        flashOpacity = 0
        if game.mustRouteToDrain {
            stage = .fork
            armIdleAutoAdvance()
        } else {
            stage = .intro
        }
    }

    private func enterFork() {
        guard stage == .intro else { return }
        withAnimation(reduceMotion ? .easeInOut(duration: 0.35) : .easeInOut(duration: 0.6)) {
            stage = .fork
        }
        armIdleAutoAdvance()
    }

    private func armIdleAutoAdvance() {
        idleTask?.cancel()
        idleTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(6))
            guard !Task.isCancelled, !choiceMade else { return }
            resolveFork(towardDrain: true)
        }
    }

    /// Where the bottle sits after every kick that's already landed in
    /// full, with the one currently in flight animating in on an ease-out
    /// settle. Shared by the bottle's own position and by each
    /// `KickerFigure`, which times its stride to plant its foot here at
    /// exactly the kick's timestamp.
    private func kickedXFrac(at t: Double) -> CGFloat {
        var x = kickStartX
        for kick in kicks {
            guard t >= kick.time else { break }
            let localT = min(1, (t - kick.time) / 0.3)
            let eased = 1 - pow(1 - localT, 3)
            x += kick.distance * eased
        }
        return x
    }

    /// A real kicked bottle doesn't just slide — it pops into a short low
    /// hop before skidding to a stop. Scaled by how hard this particular
    /// kick sent it, so the big rightward kicks visibly launch it while
    /// the small ones barely leave the ground.
    private func kickHopOffset(at t: Double) -> CGFloat {
        var offset: CGFloat = 0
        for kick in kicks {
            guard t >= kick.time else { break }
            let localT = (t - kick.time) / 0.3
            guard localT < 1 else { continue }
            let hopHeight = min(0.045, abs(kick.distance) * 0.11)
            offset = -sin(.pi * localT) * hopHeight
        }
        return offset
    }

    /// A bottle isn't a wheel — it doesn't roll cleanly, it tumbles
    /// unevenly off-axis. This layers a fast, sharply-decaying wobble on
    /// top of the base rolling rotation right as each kick lands, so the
    /// spin reads as an erratic tumble instead of a perfectly smooth roll.
    private func kickWobble(at t: Double) -> Double {
        var wobble = 0.0
        for kick in kicks {
            guard t >= kick.time else { break }
            let localT = t - kick.time
            guard localT < 0.6 else { continue }
            let decay = exp(-localT * 7)
            let dir = kick.distance >= 0 ? 1.0 : -1.0
            wobble = sin(localT * 26) * decay * 18 * dir
        }
        return wobble
    }

    /// The one-shot beat in this sequence: the dog's bite (a thunder crack
    /// for the surprise grab, plus a grime hit). The kicks themselves stay
    /// silent/cosmetic, same as before. `registerObstacleHit()` already
    /// plays the impact sound/haptic and bumps grime — reused here rather
    /// than adding a parallel method, since a dog's teeth are just another
    /// physical impact on the bottle.
    private func handleEvents(at elapsed: Double) {
        if elapsed >= biteAt && !triggeredEvents.contains("bite") {
            triggeredEvents.insert("bite")
            game.registerObstacleHit()
            game.sound.thunder()
            withAnimation(.easeOut(duration: 0.06)) { flashOpacity = 0.55 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.easeIn(duration: 0.5)) { flashOpacity = 0 }
            }
        }
    }

    /// Every visual in this beat — where the bottle is while being kicked,
    /// dog position/scale/opacity, how the bottle's tilted/blurred while
    /// carried — is a pure function of elapsed time, so the whole thing is
    /// one timeline instead of a pile of manually-toggled animation state.
    /// The dog's feet stay on `bottleRowFrac` throughout; only its X
    /// changes as it runs in from the right and off the left.
    private func introState(at elapsed: Double) -> SnatchState {
        let groundY = Double(bottleRowFrac)
        let mouthY = groundY - 0.06
        let dogStartX = 1.15
        let exitX = -0.25

        var dogX = dogStartX
        var dogScale = 0.6
        var dogOpacity = 0.0
        var bottleX = Double(kickedXFrac(at: elapsed))
        // A short hop on top of the ground line, plus a decaying wobble
        // layered onto the base rolling rotation — see `kickHopOffset`/
        // `kickWobble` — so getting kicked reads as an actual impact
        // instead of the bottle gliding flat along the pavement.
        var bottleY = groundY + Double(kickHopOffset(at: elapsed))
        // While being kicked, the bottle tumbles proportionally to how far
        // it's traveled from its starting spot — a rolling-tumble read,
        // not a literal physics spin — plus the wobble for the "not a
        // wheel" unevenness.
        var tiltDeg = (bottleX - Double(kickStartX)) * 220 + kickWobble(at: elapsed)
        var blur = 0.0

        switch elapsed {
        case ..<pounceStart:
            break

        case pounceStart..<biteAt:
            let frac = min(1, max(0, (elapsed - pounceStart) / (biteAt - pounceStart)))
            let eased = frac * frac
            dogX = lerp(dogStartX, Double(kickEndX), eased)
            dogScale = lerp(0.6, 1.0, eased)
            dogOpacity = min(1, frac * 3)

        case biteAt..<shakeEnd:
            let shakeT = elapsed - biteAt
            dogX = Double(kickEndX) + sin(shakeT * 40) * 0.01
            dogScale = 1.0
            dogOpacity = 1
            let mx = dogX - 0.05
            bottleX = mx + sin(shakeT * 30) * 0.025
            bottleY = mouthY + cos(shakeT * 22) * 0.02
            tiltDeg = 90 + 25 * sin(shakeT * 34)
            blur = max(0, min(7, shakeT / 0.15 * 5) + 2 * sin(shakeT * 10))

        case shakeEnd..<carryEnd:
            let frac = min(1, max(0, (elapsed - shakeEnd) / (carryEnd - shakeEnd)))
            dogX = lerp(Double(kickEndX), exitX, frac)
            dogScale = lerp(1.0, 0.8, frac)
            dogOpacity = 1
            bottleX = dogX - 0.05
            bottleY = mouthY
            tiltDeg = 90 + 6 * sin(elapsed * 20)
            let settleT = min(1, (elapsed - shakeEnd) / 0.3)
            blur = max(0.8, 4 * (1 - settleT))

        case carryEnd..<dogExitEnd:
            let frac = min(1, max(0, (elapsed - carryEnd) / (dogExitEnd - carryEnd)))
            dogX = exitX
            dogScale = 0.8
            dogOpacity = 1 - frac
            bottleX = exitX - 0.05
            bottleY = mouthY
            tiltDeg = 90
            blur = 0.8 * (1 - frac)

        default:
            dogOpacity = 0
        }

        let legPhase = elapsed * (elapsed < biteAt ? 20 : 18)

        return SnatchState(
            dogPos: CGPoint(x: dogX, y: groundY),
            dogScale: CGFloat(dogScale),
            dogOpacity: dogOpacity,
            legPhase: legPhase,
            bottlePos: CGPoint(x: bottleX, y: bottleY),
            bottleTilt: .degrees(tiltDeg),
            bottleBlur: CGFloat(blur)
        )
    }

    /// Settles the bottle into the chosen bin and holds briefly — the same
    /// drop-then-pause beat as the recycling facility's `succeed()` — before
    /// the scene actually transitions.
    private func resolveFork(towardDrain: Bool) {
        guard !choiceMade else { return }
        choiceMade = true
        idleTask?.cancel()
        stage = .resolving

        let target = towardDrain ? drainForkRect : landfillForkRect
        withAnimation(reduceMotion ? .easeInOut(duration: 0.4) : .easeInOut(duration: 0.6)) {
            forkBottlePos = CGPoint(x: target.midX, y: target.midY)
        }
        game.sound.impactThud()
        Haptics.collision()

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.5 : 0.85))
            if towardDrain {
                game.chooseDrain()
            } else {
                game.chooseLandfill()
            }
        }
    }
}

private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }

private struct SnatchState {
    var dogPos: CGPoint
    var dogScale: CGFloat
    var dogOpacity: Double
    var legPhase: Double
    var bottlePos: CGPoint
    var bottleTilt: Angle
    var bottleBlur: CGFloat
}

/// A full walking figure timed to plant its kicking foot on the bottle at
/// `localTime == 0`. Outside the kick window it just walks (a simple
/// two-leg scissor cycle); through the kick window the lead leg swings
/// from a cocked-back windup into a forward follow-through, so the impact
/// reads as something a person did, not a disembodied leg popping in.
private struct KickerFigure: View {
    var localTime: Double
    var footX: CGFloat
    var groundY: CGFloat
    // +1 for a kick sent rightward, -1 for leftward. Whoever sends the
    // bottle left has to be walking leftward themselves to plausibly kick
    // it that way — entering from the right, not strolling in from the
    // left and somehow booting it backward past themselves.
    var direction: CGFloat = 1

    private let walkSpeed: CGFloat = 150
    // A cool blue-gray rather than flat black — reads as a figure caught
    // in the street's neon and rain rather than a silhouette cutout that
    // blends into the near-black background.
    private let skin = Color(red: 0.34, green: 0.37, blue: 0.44)

    var body: some View {
        if localTime > -1.15 && localTime < 0.85 {
            let bodyX = footX + direction * (walkSpeed * CGFloat(localTime) - 13)
            let fadeIn = min(1, max(0, (localTime + 1.15) / 0.3))
            let fadeOut = min(1, max(0, (0.85 - localTime) / 0.3))
            ZStack {
                Ellipse()
                    .fill(Color.black.opacity(0.35))
                    .frame(width: 86, height: 20)
                    .offset(y: 9)

                ZStack(alignment: .bottom) {
                    Capsule().fill(skin).frame(width: 18, height: 83)
                        .overlay(Capsule().stroke(Theme.neonCyan.opacity(0.18), lineWidth: 1.5))
                        .rotationEffect(.degrees(backLegAngle), anchor: .top)
                        .offset(x: -13)
                    Capsule().fill(skin).frame(width: 18, height: 83)
                        .overlay(Capsule().stroke(Theme.neonCyan.opacity(0.18), lineWidth: 1.5))
                        .rotationEffect(.degrees(frontLegAngle), anchor: .top)
                        .offset(x: 13)
                    VStack(spacing: 7) {
                        Circle().fill(skin).frame(width: 41, height: 41)
                        RoundedRectangle(cornerRadius: 10).fill(skin.opacity(0.92)).frame(width: 49, height: 68)
                    }
                    .overlay(
                        VStack(spacing: 7) {
                            Circle().stroke(Theme.neonCyan.opacity(0.2), lineWidth: 1.5).frame(width: 41, height: 41)
                            RoundedRectangle(cornerRadius: 10).stroke(Theme.neonCyan.opacity(0.2), lineWidth: 1.5).frame(width: 49, height: 68)
                        }
                    )
                    .offset(y: -83)
                }
            }
            // Mirrors the whole figure — including which leg (front/back)
            // leads the kick — so it visibly faces and leads with the
            // direction it's actually walking and kicking.
            .scaleEffect(x: direction, y: 1)
            .opacity(min(fadeIn, fadeOut))
            .position(x: bodyX, y: groundY - 22)
        }
    }

    /// Mid-kick (roughly -0.12...0.26s of local time) overrides the normal
    /// walk cycle for the front leg with a windup-to-follow-through swing;
    /// otherwise both legs just scissor back and forth for an ordinary gait.
    private var kickPhase: Double? {
        guard localTime > -0.12 && localTime < 0.26 else { return nil }
        return min(1, max(0, (localTime + 0.12) / 0.38))
    }

    private var backLegAngle: Double {
        if kickPhase != nil { return -18 }
        return sin(localTime * 9) * 24
    }

    private var frontLegAngle: Double {
        if let k = kickPhase { return -55 + k * 100 }
        return -sin(localTime * 9) * 24
    }
}

/// A stray dog rendered from simple layered shapes rather than a Canvas
/// path. Unlike the human passerby (a cool blue-gray caught in neon), this
/// needs to read clearly as an animal against the same near-black street —
/// a warm, muddy fur tone plus a bright rim light and two glinting eyes,
/// so it doesn't just dissolve into the shadows the way a darker, cooler
/// silhouette did in testing. Always runs left-to-right, matching the
/// snatch sequence's blocking, and is sized/posed entirely by the caller
/// via `.frame()` and `legPhase`.
private struct StrayDogView: View {
    var legPhase: Double

    private let fur = Color(red: 0.48, green: 0.36, blue: 0.23)
    private let furDark = Color(red: 0.3, green: 0.21, blue: 0.13)
    private let rim = Theme.neonAmber.opacity(0.4)

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Ellipse()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: w * 0.75, height: h * 0.14)
                    .position(x: w * 0.52, y: h * 0.92)
                    .blur(radius: 2)

                leg(originX: w * 0.24, phase: legPhase, w: w, h: h)
                leg(originX: w * 0.19, phase: legPhase + .pi, w: w, h: h)

                // Tail, curved and tapering rather than a straight rod —
                // reads as a tail instead of another bottle-like capsule.
                TailShape()
                    .fill(furDark)
                    .frame(width: w * 0.24, height: h * 0.16)
                    .rotationEffect(.degrees(-18 + 10 * sin(legPhase)), anchor: .trailing)
                    .position(x: w * 0.02, y: h * 0.35)

                leg(originX: w * 0.58, phase: legPhase + .pi, w: w, h: h)
                leg(originX: w * 0.63, phase: legPhase, w: w, h: h)

                // One continuous silhouette for torso, neck, head and
                // muzzle — an arched back and a tapered snout instead of
                // two stacked capsules, which is what read as a bottle
                // with legs rather than an actual dog. Taller relative to
                // its length than the first pass, which read as too flat
                // and long — an otter/gator silhouette, not a dog.
                DogBodyShape()
                    .fill(
                        LinearGradient(colors: [fur, furDark], startPoint: .top, endPoint: .bottom)
                    )
                    .overlay(DogBodyShape().stroke(rim, lineWidth: 1.6))
                    .frame(width: w, height: h * 0.85)
                    .position(x: w * 0.5, y: h * 0.45)

                // Floppy ear, hanging alongside the skull — smaller and
                // higher than the first pass, which sat low enough to
                // blob into the neck and read as a second hump.
                Ellipse()
                    .fill(furDark)
                    .frame(width: w * 0.07, height: h * 0.13)
                    .rotationEffect(.degrees(20))
                    .position(x: w * 0.74, y: h * 0.1)

                Circle()
                    .fill(Theme.neonAmber)
                    .frame(width: w * 0.018, height: w * 0.018)
                    .position(x: w * 0.8, y: h * 0.12)
            }
        }
    }

    private func leg(originX: CGFloat, phase: Double, w: CGFloat, h: CGFloat) -> some View {
        Capsule()
            .fill(fur)
            .frame(width: w * 0.042, height: h * 0.42)
            .rotationEffect(.degrees(28 * sin(phase)), anchor: .top)
            .position(x: originX, y: h * 0.53)
    }
}

/// A dog's side-profile silhouette in one continuous path — arched back,
/// sloped neck, a distinct skull-to-muzzle taper, and a tucked belly —
/// instead of primitive shapes stacked together. Faces right; the caller
/// mirrors it for leftward travel.
private struct DogBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * w, y: rect.minY + y * h) }

        var p = Path()
        p.move(to: pt(0.08, 0.40))
        p.addQuadCurve(to: pt(0.30, 0.20), control: pt(0.14, 0.16))
        p.addQuadCurve(to: pt(0.54, 0.15), control: pt(0.42, 0.14))
        p.addQuadCurve(to: pt(0.68, 0.08), control: pt(0.60, 0.09))
        p.addQuadCurve(to: pt(0.80, 0.04), control: pt(0.74, 0.02))
        p.addQuadCurve(to: pt(1.0, 0.20), control: pt(0.96, 0.06))
        p.addQuadCurve(to: pt(0.88, 0.31), control: pt(0.96, 0.30))
        p.addLine(to: pt(0.77, 0.33))
        p.addQuadCurve(to: pt(0.64, 0.42), control: pt(0.70, 0.36))
        p.addQuadCurve(to: pt(0.58, 0.60), control: pt(0.60, 0.52))
        p.addQuadCurve(to: pt(0.36, 0.55), control: pt(0.46, 0.60))
        p.addQuadCurve(to: pt(0.22, 0.61), control: pt(0.28, 0.56))
        p.addQuadCurve(to: pt(0.06, 0.56), control: pt(0.12, 0.63))
        p.addQuadCurve(to: pt(0.08, 0.40), control: pt(0.0, 0.48))
        p.closeSubpath()
        return p
    }
}

/// A tapered, curved tail — wide at the base, narrowing to a point — used
/// instead of a straight capsule so it reads as an actual tail.
private struct TailShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * w, y: rect.minY + y * h) }

        var p = Path()
        p.move(to: pt(1.0, 0.35))
        p.addQuadCurve(to: pt(0.55, 0.0), control: pt(0.85, 0.0))
        p.addQuadCurve(to: pt(0.0, 0.45), control: pt(0.2, 0.05))
        p.addQuadCurve(to: pt(0.42, 0.7), control: pt(0.15, 0.75))
        p.addQuadCurve(to: pt(1.0, 0.55), control: pt(0.75, 0.85))
        p.closeSubpath()
        return p
    }
}

/// Streaks of gutter water rushing downhill toward the drain, converging
/// slightly toward center as they near it — visual reinforcement that the
/// rain is actively carrying the bottle along, not just falling on it.
private struct GutterFlowCanvas: View {
    var reduceMotion: Bool
    var bottleRowFrac: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1.0 / 30)) { context in
            Canvas { ctx, size in
                guard !reduceMotion else { return }
                let t = context.date.timeIntervalSinceReferenceDate
                let floorY = size.height * bottleRowFrac
                let span = size.height - floorY + 60
                let count = 24
                for i in 0..<count {
                    let seed = rnd(i, 210)
                    let baseX = rnd(i, 211) * size.width
                    let speed = 260.0 + Double(rnd(i, 212)) * 190
                    let travel = CGFloat((t * speed).truncatingRemainder(dividingBy: Double(span)))
                    let y = floorY + travel - 40
                    let converge = max(0, min(1, (y - floorY) / span))
                    let x = baseX + (size.width / 2 - baseX) * converge * 0.35
                    let length: CGFloat = 22 + seed * 18
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: y))
                    path.addLine(to: CGPoint(x: x, y: y + length))
                    ctx.stroke(path, with: .color(Theme.neonCyan.opacity(0.08 + seed * 0.09)), lineWidth: 1.3)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// Distant cross-traffic sliding along the base of the skyline — a bit of
/// constant background life so the street never reads as a static void.
private struct TrafficStreakCanvas: View {
    var reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1.0 / 20)) { context in
            Canvas { ctx, size in
                guard !reduceMotion else { return }
                let t = context.date.timeIntervalSinceReferenceDate
                let bandY = size.height * 0.935
                for i in 0..<3 {
                    let speed = 90.0 + Double(i) * 40
                    let direction: CGFloat = i.isMultiple(of: 2) ? 1 : -1
                    let span = size.width + 220
                    let raw = CGFloat((t * speed).truncatingRemainder(dividingBy: Double(span)))
                    let x = direction > 0 ? raw - 110 : size.width - raw + 110
                    let y = bandY + CGFloat(i) * 10
                    let color = i.isMultiple(of: 2) ? Color.white : Theme.neonPink
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: y))
                    path.addLine(to: CGPoint(x: x + 46 * direction, y: y))
                    ctx.stroke(path, with: .color(color.opacity(0.35)), lineWidth: 2.5)
                }
            }
            .blur(radius: 1.5)
        }
        .allowsHitTesting(false)
    }
}

/// Short (~4-5s), reversible failure beat mirroring the sea route: muted
/// color, hushed grinding machinery, one line of text, then straight back
/// to the drain fork — never a full restart.
struct LandfillFailureScene: View {
    @EnvironmentObject var game: GameState
    @State private var showText = false

    private var reduceMotion: Bool { game.reduceMotion }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.nearBlack, Color(red: 0.09, green: 0.07, blue: 0.05)],
                           startPoint: .top, endPoint: .bottom)

            SmokeCanvas(intensity: 0.55, color: Theme.smokeOrange, reduceMotion: reduceMotion)
                .opacity(0.55)

            BottleView(vibrancy: 0.3, dirt: min(1, game.grime + 0.2), showEyes: false, width: 54, height: 132)
                .saturation(0.25)
                .opacity(0.7)

            if showText {
                Text("Buried is not gone.")
                    .font(Theme.line(24))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 26)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: Capsule())
                    .transition(.opacity)
            }

            Vignette(strength: 0.75)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Buried is not gone. Returning to the drain.")
        .onAppear(perform: runSequence)
    }

    private func runSequence() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.4))
            withAnimation(.easeIn(duration: 0.6)) { showText = true }
            try? await Task.sleep(for: .seconds(reduceMotion ? 2.6 : 3.4))
            withAnimation(.easeOut(duration: 0.4)) { showText = false }
            try? await Task.sleep(for: .seconds(0.4))
            game.returnToForkFromLandfill()
        }
    }
}
