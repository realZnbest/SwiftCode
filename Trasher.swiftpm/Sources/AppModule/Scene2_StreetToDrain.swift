import SwiftUI

private enum ObstacleKind: CaseIterable {
    case trashBag, branch, oilSlick, rollingCan, puddleWave
}

private struct FallingObstacle: Identifiable {
    let id = UUID()
    let spawnDelay: Double
    let lane: Int
    let kind: ObstacleKind
    let travelDuration: Double
    let driftPhase: Double
}

private struct FeedbackBurst: Identifiable {
    let id = UUID()
    let xFrac: CGFloat
    let isHit: Bool
}

/// Rain pushes the bottle down the street toward a storm drain. The player
/// drags left/right anywhere on screen to dodge obstacles that drift down
/// from the top — a storm that builds from a light sprinkle of trash bags
/// to a dense, fast flurry with rolling cans and gutter waves, punctuated
/// by lightning — then chooses at the drain itself: down the grate toward
/// the canal, or swept toward a passing garbage truck and the landfill.
struct StreetToDrainScene: View {
    @EnvironmentObject var game: GameState

    private enum Stage { case dodging, fork, resolving }

    private let laneCount = 5
    private let bottleRowFrac: CGFloat = 0.72
    private let dodgeDuration: Double = 27

    @State private var stage: Stage = .dodging
    @State private var obstacles: [FallingObstacle] = []
    @State private var resolved: Set<UUID> = []
    @State private var nearMissed: Set<UUID> = []
    @State private var sceneStart = Date()
    @State private var bottleX: CGFloat = 0.5
    @State private var dragStartX: CGFloat = 0.5
    @State private var feedbackBursts: [FeedbackBurst] = []
    @State private var showHint = true
    @State private var forkDragX: CGFloat = 0
    @State private var choiceMade = false
    @State private var idleTask: Task<Void, Never>? = nil
    @State private var flashTimestamps: [Double] = []
    @State private var triggeredFlashes: Set<Int> = []
    @State private var flashOpacity: Double = 0

    private var reduceMotion: Bool { game.reduceMotion }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                background

                RainCanvas(intensity: 1, reduceMotion: reduceMotion)
                GutterFlowCanvas(reduceMotion: reduceMotion, bottleRowFrac: bottleRowFrac)
                TrafficStreakCanvas(reduceMotion: reduceMotion)

                if stage == .dodging {
                    drainPreview(size: size)
                    RippleCanvas(reduceMotion: reduceMotion, x: bottleX, rowFrac: bottleRowFrac)

                    TimelineView(.animation(minimumInterval: reduceMotion ? 0.2 : 1.0 / 45)) { context in
                        let elapsed = context.date.timeIntervalSince(sceneStart)
                        ZStack {
                            Canvas { ctx, canvasSize in
                                for obstacle in obstacles {
                                    draw(obstacle, elapsed: elapsed, size: canvasSize, ctx: &ctx)
                                }
                            }
                            Color.clear
                                .onChange(of: elapsed) { _, newValue in
                                    evaluateCollisions(elapsed: newValue)
                                    checkLightning(elapsed: newValue)
                                    if newValue > dodgeDuration {
                                        enterFork()
                                    }
                                }
                        }
                    }

                    ForEach(feedbackBursts) { burst in
                        feedbackView(burst)
                            .position(x: burst.xFrac * size.width, y: bottleRowFrac * size.height)
                            .transition(.opacity)
                    }

                    BottleView(
                        vibrancy: game.vibrancy, dirt: game.grime, showEyes: false, glow: 0,
                        width: 80, height: 192
                    )
                    .position(x: bottleX * size.width, y: bottleRowFrac * size.height)

                    progressTrack(size: size)

                    if showHint {
                        Text("Swipe to dodge")
                            .font(Theme.line(20))
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(.horizontal, 22)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial, in: Capsule())
                            .position(x: size.width / 2, y: size.height * 0.18)
                            .transition(.opacity)
                    }
                }

                if stage == .fork || stage == .resolving {
                    forkView(size: size)
                }

                Vignette(strength: 0.5)

                Color.white
                    .opacity(flashOpacity)
                    .blendMode(.plusLighter)
                    .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .gesture(stage == .dodging ? dodgeGesture(size: size) : nil)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(stage == .dodging
            ? "Street scene. Drag left or right to steer the bottle away from trash and debris toward the storm drain."
            : "The storm drain. Swipe left toward a passing garbage truck, or swipe right down the drain toward the canal.")
        .onAppear(perform: setup)
    }

    @ViewBuilder
    private func feedbackView(_ burst: FeedbackBurst) -> some View {
        if burst.isHit {
            Circle()
                .fill(RadialGradient(colors: [Theme.smokeOrange.opacity(0.6), .clear],
                                     center: .center, startRadius: 0, endRadius: 44))
                .frame(width: 90, height: 90)
        } else {
            Circle()
                .strokeBorder(Theme.neonCyan.opacity(0.75), lineWidth: 3)
                .frame(width: 82, height: 82)
                .scaleEffect(1.15)
        }
    }

    private func dodgeGesture(size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let deltaFrac = value.translation.width / max(size.width, 1)
                bottleX = min(0.92, max(0.08, dragStartX + deltaFrac))
            }
            .onEnded { _ in dragStartX = bottleX }
    }

    private var background: some View {
        ZStack {
            LinearGradient(colors: [Theme.deepNavy, Theme.nearBlack], startPoint: .top, endPoint: .bottom)
            SkylineCanvas()
                .opacity(0.55)
            NeonStreakField(colors: [Theme.neonCyan, Theme.neonPurple, Theme.neonPink], reduceMotion: reduceMotion)
                .opacity(0.85)

            // Wet pavement: a soft reflective band across the lower third.
            LinearGradient(colors: [.clear, Color.white.opacity(0.05), Color.white.opacity(0.02)],
                           startPoint: .top, endPoint: .bottom)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .frame(height: 260)
                .blendMode(.plusLighter)
        }
    }

    private func progressTrack(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 0.5 : 0.1)) { context in
            let elapsed = min(dodgeDuration, context.date.timeIntervalSince(sceneStart))
            let frac = elapsed / dodgeDuration
            let trackWidth = size.width * 0.5
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.12)).frame(height: 4)
                Capsule().fill(Theme.neonCyan.opacity(0.85)).frame(width: trackWidth * frac, height: 4)
                    .glow(Theme.neonCyan, radius: 6, opacity: 0.5)
            }
            .frame(width: trackWidth)
            .position(x: size.width / 2, y: 22)
        }
        .allowsHitTesting(false)
    }

    private func drainPreview(size: CGSize) -> some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Theme.neonCyan.opacity(0.35), .clear],
                                     center: .center, startRadius: 0, endRadius: 90))
                .frame(width: 180, height: 180)
            Circle().strokeBorder(Theme.neonCyan.opacity(0.6), lineWidth: 3).frame(width: 70, height: 70)
            Circle().strokeBorder(Theme.neonCyan.opacity(0.3), lineWidth: 2).frame(width: 46, height: 46)
        }
        .position(x: size.width / 2, y: bottleRowFrac * size.height)
    }

    private func forkView(size: CGSize) -> some View {
        let landfillBlocked = game.mustRouteToDrain
        let bottleCenterX = size.width / 2 + forkDragX
        let leaning = forkDragX / (size.width * 0.3)

        return ZStack {
            // Landfill / garbage truck path (left) — the wrong turn.
            PathChoiceIndicator(
                systemImage: "trash.fill",
                tint: landfillBlocked ? .gray : Theme.smokeOrange,
                bright: !landfillBlocked && leaning < -0.15,
                dim: landfillBlocked
            )
            .position(x: size.width * 0.18, y: size.height * 0.42)

            // Storm drain path (right) — continues the story correctly.
            PathChoiceIndicator(
                systemImage: "arrow.down.circle.fill",
                tint: Theme.neonCyan,
                bright: leaning > 0.15 || landfillBlocked
            )
            .position(x: size.width * 0.82, y: size.height * 0.42)

            BottleView(vibrancy: game.vibrancy, dirt: game.grime, showEyes: false, width: 62, height: 152)
                .position(x: bottleCenterX, y: size.height * 0.62)
                .rotationEffect(.degrees(Double(leaning) * 14))
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard !choiceMade else { return }
                    forkDragX = max(-size.width * 0.3, min(size.width * 0.3, value.translation.width))
                }
                .onEnded { value in
                    guard !choiceMade else { return }
                    let threshold = size.width * 0.16
                    if value.translation.width < -threshold && !landfillBlocked {
                        resolveFork(towardDrain: false)
                    } else if value.translation.width > threshold {
                        resolveFork(towardDrain: true)
                    } else {
                        withAnimation(.spring()) { forkDragX = 0 }
                    }
                }
        )
    }

    private func setup() {
        sceneStart = Date()
        choiceMade = false
        forkDragX = 0
        resolved = []
        nearMissed = []
        feedbackBursts = []
        flashOpacity = 0
        triggeredFlashes = []
        if game.mustRouteToDrain {
            stage = .fork
            armIdleAutoAdvance()
        } else {
            stage = .dodging
            obstacles = buildObstacles()
            flashTimestamps = (0..<3).map { _ in Double.random(in: 5...(dodgeDuration - 3)) }.sorted()
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(3.2))
                withAnimation { showHint = false }
            }
        }
    }

    /// Obstacles start as a light sprinkle and build to a dense, fast
    /// flurry with lanes overlapping by the time the bottle nears the
    /// drain — a real storm, not a steady trickle.
    private func buildObstacles() -> [FallingObstacle] {
        var result: [FallingObstacle] = []
        var t = 0.9
        while t < dodgeDuration - 0.9 {
            let intensity = min(1, t / (dodgeDuration * 0.85))
            let kind = ObstacleKind.allCases.randomElement()!
            let lane = kind == .puddleWave ? Int.random(in: 0..<(laneCount - 1)) : Int.random(in: 0..<laneCount)
            let travel = 3.3 * (1 - 0.28 * intensity)
            result.append(FallingObstacle(
                spawnDelay: t, lane: lane, kind: kind,
                travelDuration: travel, driftPhase: Double.random(in: 0...(2 * .pi))
            ))
            let gap = (2.05 - 1.4 * intensity) + Double.random(in: -0.2...0.3)
            t += max(gap, 0.6)
        }
        return result
    }

    private func enterFork() {
        guard stage == .dodging else { return }
        stage = .fork
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

    private func laneX(_ lane: Int) -> CGFloat { (CGFloat(lane) + 0.5) / CGFloat(laneCount) }

    /// The horizontal position (as a 0...1 fraction) of an obstacle at time
    /// `t` since it spawned — shared by drawing and collision so a can's
    /// sideways drift or a puddle's double-wide straddle line up exactly
    /// with what's on screen.
    private func obstacleXFrac(_ obstacle: FallingObstacle, t: Double) -> CGFloat {
        switch obstacle.kind {
        case .rollingCan:
            return laneX(obstacle.lane) + CGFloat(sin(t * 3.2 + obstacle.driftPhase)) * 0.055
        case .puddleWave:
            let otherLane = min(obstacle.lane + 1, laneCount - 1)
            return (laneX(obstacle.lane) + laneX(otherLane)) / 2
        default:
            return laneX(obstacle.lane)
        }
    }

    private func draw(_ obstacle: FallingObstacle, elapsed: Double, size: CGSize, ctx: inout GraphicsContext) {
        let t = elapsed - obstacle.spawnDelay
        guard t > 0 else { return }
        let progress = t / obstacle.travelDuration
        guard progress <= 1.15 else { return }
        let x = obstacleXFrac(obstacle, t: t) * size.width
        let y = -60 + (bottleRowFrac * size.height + 60) * min(progress, 1.15)
        let scale = 0.6 + min(progress, 1) * 0.85

        switch obstacle.kind {
        case .trashBag:
            let r = 26 * scale
            ctx.fill(Path(ellipseIn: CGRect(x: x - r / 2, y: y - r / 2, width: r, height: r * 0.85)),
                     with: .color(Color(red: 0.16, green: 0.2, blue: 0.16).opacity(0.9)))
            var knot = Path()
            knot.move(to: CGPoint(x: x, y: y - r * 0.42))
            knot.addLine(to: CGPoint(x: x, y: y - r * 0.6))
            ctx.stroke(knot, with: .color(.black.opacity(0.6)), lineWidth: 2)
        case .branch:
            var path = Path()
            let len = 34 * scale
            path.move(to: CGPoint(x: x - len / 2, y: y + len * 0.2))
            path.addLine(to: CGPoint(x: x + len / 2, y: y - len * 0.2))
            path.move(to: CGPoint(x: x - len * 0.1, y: y - len * 0.05))
            path.addLine(to: CGPoint(x: x - len * 0.3, y: y - len * 0.35))
            ctx.stroke(path, with: .color(Theme.murkBrown), lineWidth: 4 * scale)
        case .oilSlick:
            let r = 44 * scale
            let rect = CGRect(x: x - r / 2, y: y - r * 0.3, width: r, height: r * 0.5)
            ctx.fill(Path(ellipseIn: rect),
                     with: .radialGradient(
                        Gradient(colors: [.black.opacity(0.75), Theme.neonPurple.opacity(0.35), Theme.murkGreen.opacity(0.4)]),
                        center: CGPoint(x: x, y: y), startRadius: 0, endRadius: r / 2))
        case .rollingCan:
            let r = 15 * scale
            let rect = CGRect(x: x - r, y: y - r * 0.7, width: r * 2, height: r * 1.4)
            ctx.fill(Path(roundedRect: rect, cornerRadius: r * 0.65),
                     with: .linearGradient(Gradient(colors: [Color(white: 0.8), Color(white: 0.42)]),
                                            startPoint: CGPoint(x: rect.minX, y: rect.minY),
                                            endPoint: CGPoint(x: rect.maxX, y: rect.maxY)))
            var shine = Path()
            shine.move(to: CGPoint(x: x - r * 0.25, y: y - r * 0.55))
            shine.addLine(to: CGPoint(x: x - r * 0.25, y: y + r * 0.55))
            ctx.stroke(shine, with: .color(.white.opacity(0.55)), lineWidth: 1.4)
        case .puddleWave:
            let w = 130 * scale
            let rect = CGRect(x: x - w / 2, y: y - 14 * scale, width: w, height: 28 * scale)
            ctx.fill(Path(ellipseIn: rect),
                     with: .radialGradient(
                        Gradient(colors: [.white.opacity(0.55), Theme.neonCyan.opacity(0.35), .clear]),
                        center: CGPoint(x: x, y: y), startRadius: 0, endRadius: w / 2))
        }
    }

    private func evaluateCollisions(elapsed: Double) {
        for obstacle in obstacles {
            guard !resolved.contains(obstacle.id) else { continue }
            let t = elapsed - obstacle.spawnDelay
            guard t > 0 else { continue }
            let progress = t / obstacle.travelDuration
            guard progress >= 0.82 && progress <= 1.12 else {
                if progress > 1.12 { resolved.insert(obstacle.id) }
                continue
            }
            let obstacleX = obstacleXFrac(obstacle, t: t)
            let hitRadius: CGFloat = obstacle.kind == .puddleWave ? 0.21 : 0.105
            let distance = abs(obstacleX - bottleX)
            if progress >= 0.9 && progress <= 1.08 && distance < hitRadius {
                resolved.insert(obstacle.id)
                registerHit(at: obstacleX)
            } else if distance < hitRadius + 0.1 && !nearMissed.contains(obstacle.id) {
                nearMissed.insert(obstacle.id)
                registerNearMiss(at: obstacleX)
            }
        }
    }

    private func registerHit(at xFrac: CGFloat) {
        game.registerObstacleHit()
        let burst = FeedbackBurst(xFrac: xFrac, isHit: true)
        withAnimation { feedbackBursts.append(burst) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            feedbackBursts.removeAll { $0.id == burst.id }
        }
    }

    private func registerNearMiss(at xFrac: CGFloat) {
        let burst = FeedbackBurst(xFrac: xFrac, isHit: false)
        withAnimation(.easeOut(duration: 0.25)) { feedbackBursts.append(burst) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            feedbackBursts.removeAll { $0.id == burst.id }
        }
    }

    private func checkLightning(elapsed: Double) {
        for (i, timestamp) in flashTimestamps.enumerated() where !triggeredFlashes.contains(i) {
            if elapsed > timestamp {
                triggeredFlashes.insert(i)
                triggerLightning()
            }
        }
    }

    private func triggerLightning() {
        game.sound.thunder()
        withAnimation(.easeOut(duration: 0.08)) { flashOpacity = 0.5 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeIn(duration: 0.55)) { flashOpacity = 0 }
        }
    }

    private func resolveFork(towardDrain: Bool) {
        guard !choiceMade else { return }
        choiceMade = true
        idleTask?.cancel()
        stage = .resolving

        let travel: CGFloat = towardDrain ? 900 : -900
        withAnimation(reduceMotion ? .easeInOut(duration: 0.5) : .easeIn(duration: 0.8)) {
            forkDragX = travel
        }

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

/// Faint concentric ripples under the bottle as it wades through the
/// rising street water — continuous feedback that this is a current, not
/// just a backdrop.
private struct RippleCanvas: View {
    var reduceMotion: Bool
    var x: CGFloat
    var rowFrac: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1.0 / 24)) { context in
            Canvas { ctx, size in
                guard !reduceMotion else { return }
                let t = context.date.timeIntervalSinceReferenceDate
                let center = CGPoint(x: x * size.width, y: rowFrac * size.height + 58)
                for i in 0..<3 {
                    let phase = (t * 0.9 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                    let radius = CGFloat(phase) * 46
                    let opacity = (1 - phase) * 0.3
                    ctx.stroke(
                        Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius * 0.35, width: radius * 2, height: radius * 0.7)),
                        with: .color(Theme.neonCyan.opacity(opacity)), lineWidth: 1.4
                    )
                }
            }
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
