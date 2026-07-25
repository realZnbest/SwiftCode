import SwiftUI

struct TitleScene: View {
    @EnvironmentObject var game: GameState

    @State private var appear = false

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                LinearGradient(colors: [Theme.deepNavy, Theme.nearBlack], startPoint: .top, endPoint: .bottom)
                SkylineCanvas().opacity(0.35)
                NeonStreakField(colors: [Theme.neonCyan, Theme.neonPurple])
                    .opacity(0.45)

                spotlightGlow(size: size)

                SparkleCanvas(count: 30, color: .white)
                    .opacity(0.6)
                    .mask(spotlightMask(size: size))

                BottleView(vibrancy: 1, dirt: 0, showEyes: true, width: 46, height: 112)
                    .position(x: size.width / 2, y: size.height * 0.66)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 16)

                VStack(spacing: 8) {
                    Text("TRASHER")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .glow(Theme.cleanCyan, radius: 16, opacity: 0.5)
                    Text("a plastic bottle's journey")
                        .font(Theme.line(17))
                        .foregroundStyle(.white.opacity(0.65))
                }
                .position(x: size.width / 2, y: size.height * 0.26)
                .opacity(appear ? 1 : 0)

                tapToBeginLabel(size: size)

                Vignette(strength: 0.62)
            }
            .contentShape(Rectangle())
            .onTapGesture { begin() }
        }
        .onAppear(perform: runSequence)
    }

    private func tapToBeginLabel(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let glow = 0.4 + 0.55 * (0.5 + 0.5 * sin(t * 1.7))
            Text("แตะเพื่อเริ่ม")
                .font(Theme.line(16))
                .foregroundStyle(.white.opacity(glow))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .position(x: size.width / 2, y: size.height * 0.88)
        .opacity(appear ? 1 : 0)
    }

    private func spotlightGlow(size: CGSize) -> some View {
        RadialGradient(
            colors: [Color.white.opacity(0.16), .clear],
            center: UnitPoint(x: 0.5, y: 0.62), startRadius: 10, endRadius: size.width * 0.42
        )
    }

    private func spotlightMask(size: CGSize) -> some View {
        RadialGradient(
            colors: [.white, .clear],
            center: UnitPoint(x: 0.5, y: 0.62), startRadius: 10, endRadius: size.width * 0.42
        )
    }

    private func runSequence() {
        withAnimation(.easeIn(duration: 1.0).delay(0.3)) { appear = true }
    }

    private func begin() {
        game.advanceFromTitle()
    }
}
