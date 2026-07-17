import SwiftUI

/// 15-20s. A bright park scene with the finished bench, a short animated
/// recap of the whole journey, the closing line, and the two exit actions.
struct EndingScene: View {
    @EnvironmentObject var game: GameState
    @State private var showContent = false

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                parkBackground

                BenchView(width: size.width * 0.2, height: size.height * 0.28)
                    .position(x: size.width * 0.5, y: size.height * 0.66)
                    .glow(Theme.freshGreen, radius: 14, opacity: 0.3)

                communitySilhouettes(size: size)

                VStack(spacing: 16) {
                    Spacer().frame(height: size.height * 0.05)

                    JourneyRecapView(replayToken: game.journeyReplayToken, reduceMotion: game.reduceMotion)
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
        }
    }

    private var parkBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.55, green: 0.82, blue: 0.97), Color(red: 0.78, green: 0.92, blue: 0.72)],
                startPoint: .top, endPoint: .bottom
            )
            GlowOrb(color: Theme.neonAmber, size: 170)
                .position(x: 90, y: 70)
            SparkleCanvas(count: 16, color: .white, reduceMotion: game.reduceMotion)
                .opacity(0.35)
        }
    }

    private func communitySilhouettes(size: CGSize) -> some View {
        HStack(spacing: 44) {
            ForEach(0..<3, id: \.self) { _ in
                Capsule()
                    .fill(Color.black.opacity(0.28))
                    .frame(width: 24, height: 44)
            }
        }
        .position(x: size.width * 0.5, y: size.height * 0.78)
    }
}

// MARK: - Journey recap

private struct JourneyWaypoint {
    let icon: String
    let color: Color
}

private let journeyWaypoints: [JourneyWaypoint] = [
    JourneyWaypoint(icon: "building.2.fill", color: Theme.neonCyan),
    JourneyWaypoint(icon: "cloud.rain.fill", color: Theme.neonPink),
    JourneyWaypoint(icon: "water.waves", color: Theme.murkGreen),
    JourneyWaypoint(icon: "arrow.3.trianglepath", color: Theme.cleanCyan),
    JourneyWaypoint(icon: "leaf.fill", color: Theme.freshGreen)
]

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

                ForEach(0..<journeyWaypoints.count, id: \.self) { i in
                    let threshold = CGFloat(i) / CGFloat(journeyWaypoints.count - 1)
                    let revealed = reduceMotion || progress >= threshold - 0.03
                    ZStack {
                        Circle().fill(journeyWaypoints[i].color.opacity(0.22)).frame(width: 38, height: 38)
                        Image(systemName: journeyWaypoints[i].icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(journeyWaypoints[i].color)
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
        .accessibilityLabel("A path from city street, to storm drain, to canal, to recycling facility, to park bench.")
    }

    private func waypointPositions(in size: CGSize) -> [CGPoint] {
        let n = journeyWaypoints.count
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
