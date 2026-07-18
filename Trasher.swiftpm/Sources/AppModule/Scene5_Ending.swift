import SwiftUI

/// 15-20s. A bright park scene with the finished bench, a short animated
/// recap of the whole journey, the closing line, and the two exit actions.
struct EndingScene: View {
    @EnvironmentObject var game: GameState
    @State private var showContent = false
    @State private var showBenchCaption = false

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                parkBackground

                BenchView(width: size.width * 0.35, height: size.height * 0.14)
                    .position(x: size.width * 0.5, y: size.height * 0.71)
                    .glow(Theme.freshGreen, radius: 14, opacity: endingGlow)

                if showBenchCaption {
                    // Echoes the opening line ("I still have a purpose.") so the
                    // ending answers it, and reads as plastic reshaped — not wood.
                    Text("Same plastic. A new purpose.")
                        .font(Theme.line(15))
                        .foregroundStyle(Color.black.opacity(0.75))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .transition(.opacity)
                        .position(x: size.width * 0.5, y: size.height * 0.47)
                }

                if journeyWasMessy {
                    endingScars(size: size)
                }

                communitySilhouettes(size: size)

                VStack(spacing: 16) {
                    Spacer().frame(height: size.height * 0.05)

                    JourneyRecapView(
                        replayToken: game.journeyReplayToken,
                        reduceMotion: game.reduceMotion,
                        waypoints: journeyWaypoints
                    )
                        .frame(height: size.height * 0.22)
                        .padding(.horizontal, 50)

                    Spacer()

                    Text("Waste does not disappear.\nYou can choose where it goes.")
                        .multilineTextAlignment(.center)
                        .font(Theme.line(24))
                        .foregroundStyle(Color.black.opacity(0.8))
                        .padding(.horizontal, 30)

                    HStack(spacing: 20) {
                        Button {
                            game.playAgain()
                        } label: {
                            Label("Play Again", systemImage: "arrow.counterclockwise")
                                .font(Theme.line(17))
                                .padding(.horizontal, 22)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial, in: Capsule())
                                .overlay(Capsule().stroke(Theme.cleanCyan.opacity(0.7), lineWidth: 1.5))
                        }
                        .foregroundStyle(Color.black.opacity(0.85))
                        .accessibilityLabel("Play again from the beginning")

                        Button {
                            game.replayJourney()
                        } label: {
                            Label("View My Journey", systemImage: "map")
                                .font(Theme.line(17))
                                .padding(.horizontal, 22)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial, in: Capsule())
                                .overlay(Capsule().stroke(Theme.freshGreen.opacity(0.7), lineWidth: 1.5))
                        }
                        .foregroundStyle(Color.black.opacity(0.85))
                        .accessibilityLabel("Replay the animated summary of the bottle's journey")
                    }

                    Spacer().frame(height: size.height * 0.06)
                }
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 1.0).delay(0.5)) { showContent = true }
            withAnimation(.easeIn(duration: 0.8).delay(1.3)) { showBenchCaption = true }
        }
    }

    private var parkBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.55, green: 0.82, blue: 0.97).mix(with: Theme.murkGreen, amount: lingeringHaze),
                    Color(red: 0.78, green: 0.92, blue: 0.72).mix(with: Theme.murkBrown, amount: lingeringHaze)
                ],
                startPoint: .top, endPoint: .bottom
            )
            GlowOrb(color: Theme.neonAmber, size: 170)
                .position(x: 90, y: 70)
            CloudDriftCanvas(reduceMotion: game.reduceMotion)
                .opacity(0.7)
            TreeLineCanvas()
            SparkleCanvas(count: 16, color: .white, reduceMotion: game.reduceMotion)
                .opacity(0.35 - lingeringHaze * 0.2)
            if lingeringHaze > 0 {
                SmokeCanvas(intensity: lingeringHaze * 0.5, color: Theme.murkGreen, reduceMotion: game.reduceMotion)
                    .opacity(lingeringHaze * 0.45)
            }
        }
    }

    private var journeyWaypoints: [JourneyWaypoint] {
        var result = [
            JourneyWaypoint(icon: "building.2.fill", color: Theme.neonCyan),
            JourneyWaypoint(icon: "cloud.rain.fill", color: Theme.neonPink)
        ]
        if game.landfillAttempts > 0 {
            result.append(JourneyWaypoint(icon: "trash.fill", color: Theme.smokeOrange))
        }
        result.append(JourneyWaypoint(icon: "water.waves", color: Theme.murkGreen))
        if game.seaAttempts > 0 {
            result.append(JourneyWaypoint(icon: "water.waves", color: Theme.mutedSeaTeal))
        }
        result += [
            JourneyWaypoint(icon: "arrow.3.trianglepath", color: Theme.cleanCyan),
            JourneyWaypoint(icon: "leaf.fill", color: Theme.freshGreen)
        ]
        return result
    }

    private var lingeringHaze: Double {
        min(0.28, game.grime * 0.12 + Double(game.binMisses + game.landfillAttempts + game.seaAttempts) * 0.045)
    }

    private var endingGlow: Double { 0.34 - lingeringHaze * 0.55 }
    private var journeyWasMessy: Bool { lingeringHaze > 0.03 }

    private func endingScars(size: CGSize) -> some View {
        HStack(spacing: 9) {
            ForEach(0..<3, id: \.self) { _ in
                Capsule().fill(Theme.murkBrown.opacity(0.22)).frame(width: 4, height: 16)
            }
        }
        .rotationEffect(.degrees(-10))
        .position(x: size.width * 0.57, y: size.height * 0.68)
        .allowsHitTesting(false)
    }

    private func communitySilhouettes(size: CGSize) -> some View {
        // PersonFigure is 68pt tall; scaled to 0.6 that's 40.8pt, so its
        // feet sit 20.4pt below the cluster's own center. Positioning that
        // center 20.4pt above TreeLineCanvas's ground line (baseY = 0.78)
        // plants the feet on the grass instead of floating above it.
        let groundY = size.height * 0.78 - 20.4
        return ZStack {
            personCluster(shirts: [Theme.neonAmber, Theme.cleanCyan])
                .position(x: size.width * 0.24, y: groundY)
            personCluster(shirts: [Theme.neonPink])
                .position(x: size.width * 0.78, y: groundY)
        }
        .allowsHitTesting(false)
    }

    /// Flanks the bench rather than sitting in the text/button column below
    /// it, and stays above the tree line so figures don't blend into the
    /// dark foliage silhouettes. Uses the same head/torso/legs PersonFigure
    /// as the community cleanup scene, not an unlabeled dark capsule.
    private func personCluster(shirts: [Color]) -> some View {
        HStack(spacing: 12) {
            ForEach(Array(shirts.enumerated()), id: \.offset) { _, shirt in
                PersonFigure(shirt: shirt)
            }
        }
        .scaleEffect(0.6)
    }
}

// MARK: - Journey recap

struct JourneyWaypoint {
    let icon: String
    let color: Color
}

private struct JourneyPathShape: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for i in 1..<points.count {
            let prev = points[i - 1]
            let cur = points[i]
            path.addQuadCurve(to: cur, control: CGPoint(x: (prev.x + cur.x) / 2, y: prev.y))
        }
        return path
    }
}

/// A short, replayable animation tracing the bottle's whole route as a
/// clean line with five waypoint icons — the "journey" the ending recaps.
struct JourneyRecapView: View {
    var replayToken: Int
    var reduceMotion: Bool
    var waypoints: [JourneyWaypoint]

    @State private var progress: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let points = waypointPositions(in: size)

            ZStack {
                JourneyPathShape(points: points)
                    .stroke(Color.black.opacity(0.12), lineWidth: 3)

                JourneyPathShape(points: points)
                    .trim(from: 0, to: reduceMotion ? 1 : progress)
                    .stroke(
                        LinearGradient(colors: [Theme.neonCyan, Theme.cleanCyan, Theme.freshGreen],
                                       startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )

                ForEach(0..<waypoints.count, id: \.self) { i in
                    let threshold = CGFloat(i) / CGFloat(max(waypoints.count - 1, 1))
                    let revealed = reduceMotion || progress >= threshold - 0.03
                    ZStack {
                        Circle().fill(waypoints[i].color.opacity(0.22)).frame(width: 38, height: 38)
                        Image(systemName: waypoints[i].icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(waypoints[i].color)
                    }
                    .position(points[i])
                    .opacity(revealed ? 1 : 0.25)
                    .scaleEffect(revealed ? 1 : 0.7)
                }

                if !reduceMotion {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 9, height: 9)
                        .glow(.white, radius: 6, opacity: 0.8)
                        .position(pointAlong(points: points, progress: progress))
                        .opacity(progress > 0.01 && progress < 0.99 ? 1 : 0)
                }
            }
        }
        .onAppear(perform: animate)
        .onChange(of: replayToken) { _, _ in animate() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("A path from city street, to storm drain, to canal, to recycling facility, to a bench made of recycled plastic.")
    }

    private func waypointPositions(in size: CGSize) -> [CGPoint] {
        let n = max(waypoints.count, 2)
        return (0..<n).map { i in
            let x = size.width * (CGFloat(i) / CGFloat(n - 1))
            let y = size.height * (i.isMultiple(of: 2) ? 0.3 : 0.7)
            return CGPoint(x: x, y: y)
        }
    }

    private func pointAlong(points: [CGPoint], progress: CGFloat) -> CGPoint {
        let n = points.count
        let scaled = progress * CGFloat(n - 1)
        let index = min(n - 2, max(0, Int(scaled)))
        let frac = scaled - CGFloat(index)
        let a = points[index]
        let b = points[index + 1]
        return CGPoint(x: a.x + (b.x - a.x) * frac, y: a.y + (b.y - a.y) * frac)
    }

    private func animate() {
        progress = 0
        guard !reduceMotion else {
            progress = 1
            return
        }
        withAnimation(.easeInOut(duration: 4.0)) { progress = 1 }
    }
}
