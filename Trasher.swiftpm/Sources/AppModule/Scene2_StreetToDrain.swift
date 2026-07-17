import SwiftUI

private enum ObstacleKind: CaseIterable {
    case trashBag, branch, oilSlick
}

private struct FallingObstacle: Identifiable {
    let id = UUID()
    let spawnDelay: Double
    let lane: Int
    let kind: ObstacleKind
}

private struct HitBurst: Identifiable {
    let id = UUID()
    let xFrac: CGFloat
}

/// 30-40s. Rain pushes the bottle down the street toward a storm drain.
/// The player drags left/right anywhere on screen to dodge obstacles that
/// drift down from the top of the frame.
struct StreetToDrainScene: View {
    @EnvironmentObject var game: GameState

    private let laneCount = 5
    private let bottleRowFrac: CGFloat = 0.72
    private let travelDuration: Double = 3.3
    private let sceneDuration: Double = 33

    @State private var obstacles: [FallingObstacle] = []
    @State private var resolved: Set<UUID> = []
    @State private var sceneStart = Date()
    @State private var bottleX: CGFloat = 0.5
    @State private var dragStartX: CGFloat = 0.5
    @State private var hitBursts: [HitBurst] = []
    @State private var showHint = true
    @State private var draining = false

    private var reduceMotion: Bool { game.reduceMotion }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                background

                RainCanvas(intensity: 1, reduceMotion: reduceMotion)

                drainIndicator(size: size)

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
                                if !draining && newValue > sceneDuration {
                                    beginDrainOut()
                                }
                            }
                    }
                }

                ForEach(hitBursts) { burst in
                    Circle()
                        .fill(RadialGradient(colors: [Theme.smokeOrange.opacity(0.6), .clear],
                                             center: .center, startRadius: 0, endRadius: 44))
                        .frame(width: 90, height: 90)
                        .position(x: burst.xFrac * size.width, y: bottleRowFrac * size.height)
                        .transition(.opacity)
                }

                BottleView(
                    vibrancy: game.vibrancy,
                    dirt: game.grime,
                    showEyes: false,
                    glow: 0,
                    width: 66,
                    height: 160
                )
                .position(x: bottleX * size.width, y: bottleRowFrac * size.height)
                .scaleEffect(draining ? 0.15 : 1)
                .opacity(draining ? 0 : 1)
                .rotationEffect(.degrees(draining ? 260 : 0))
                .animation(reduceMotion ? .easeInOut(duration: 0.5) : .easeIn(duration: 1.1), value: draining)

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

                Vignette(strength: 0.5)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let deltaFrac = value.translation.width / max(size.width, 1)
                        bottleX = min(0.92, max(0.08, dragStartX + deltaFrac))
                    }
                    .onEnded { _ in dragStartX = bottleX }
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Street scene. Drag left or right to steer the bottle away from trash and debris toward the storm drain.")
        .onAppear(perform: setup)
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
            let elapsed = min(sceneDuration, context.date.timeIntervalSince(sceneStart))
            let frac = elapsed / sceneDuration
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

    private func drainIndicator(size: CGSize) -> some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Theme.neonCyan.opacity(draining ? 0.9 : 0.35), .clear],
                                     center: .center, startRadius: 0, endRadius: 90))
                .frame(width: 180, height: 180)
            Circle()
                .strokeBorder(Theme.neonCyan.opacity(0.6), lineWidth: 3)
                .frame(width: 70, height: 70)
            Circle()
                .strokeBorder(Theme.neonCyan.opacity(0.3), lineWidth: 2)
                .frame(width: 46, height: 46)
        }
        .position(x: size.width / 2, y: bottleRowFrac * size.height)
        .scaleEffect(draining ? 1.3 : 1)
        .animation(.easeInOut(duration: 0.8), value: draining)
    }

    private func setup() {
        sceneStart = Date()
        obstacles = (0..<11).map { i in
            FallingObstacle(
                spawnDelay: Double(i) * 2.75 + Double.random(in: 0...0.9),
                lane: Int.random(in: 0..<laneCount),
                kind: ObstacleKind.allCases.randomElement()!
            )
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3.2))
            withAnimation { showHint = false }
        }
    }

    private func laneX(_ lane: Int) -> CGFloat { (CGFloat(lane) + 0.5) / CGFloat(laneCount) }

    private func draw(_ obstacle: FallingObstacle, elapsed: Double, size: CGSize, ctx: inout GraphicsContext) {
        let t = elapsed - obstacle.spawnDelay
        guard t > 0 else { return }
        let progress = t / travelDuration
        guard progress <= 1.15 else { return }
        let x = laneX(obstacle.lane) * size.width
        let y = -60 + (bottleRowFrac * size.height + 60) * min(progress, 1.15)
        let scale = 0.5 + min(progress, 1) * 0.7

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
        }
    }

    private func evaluateCollisions(elapsed: Double) {
        for obstacle in obstacles {
            guard !resolved.contains(obstacle.id) else { continue }
            let t = elapsed - obstacle.spawnDelay
            guard t > 0 else { continue }
            let progress = t / travelDuration
            if progress >= 0.9 && progress <= 1.08 {
                if abs(laneX(obstacle.lane) - bottleX) < 0.095 {
                    resolved.insert(obstacle.id)
                    registerHit(at: laneX(obstacle.lane))
                }
            } else if progress > 1.1 {
                resolved.insert(obstacle.id)
            }
        }
    }

    private func registerHit(at xFrac: CGFloat) {
        game.registerObstacleHit()
        let burst = HitBurst(xFrac: xFrac)
        withAnimation { hitBursts.append(burst) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            hitBursts.removeAll { $0.id == burst.id }
        }
    }

    private func beginDrainOut() {
        draining = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.6 : 1.2))
            game.advanceFromStreet()
        }
    }
}
