import SwiftUI

/// 10-15s. A neon city at night, a hand lets go of a bottle, the camera
/// pushes in close enough that its highlight reads like a quiet gaze.
struct OpeningScene: View {
    @EnvironmentObject var game: GameState

    @State private var stage = 0
    @State private var bottleY: CGFloat = -220
    @State private var bottleRotation: Angle = .degrees(-8)
    @State private var handOffset: CGFloat = 0
    @State private var handOpacity: Double = 1
    @State private var showText = false
    @State private var pushIn = false
    @State private var impactBurst = false

    private var reduceMotion: Bool { game.reduceMotion }

    var body: some View {
        ZStack {
            cityBackground
                .scaleEffect(pushIn ? 1.35 : 1.0)
                .opacity(pushIn ? 0.55 : 1)

            LinearGradient(colors: [.clear, Theme.nearBlack.opacity(0.9)], startPoint: .center, endPoint: .bottom)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .frame(height: 240)
                .frame(maxHeight: .infinity, alignment: .bottom)

            Image(systemName: "hand.point.down.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 84)
                .foregroundStyle(.white.opacity(0.5))
                .offset(y: -190 + handOffset)
                .opacity(handOpacity)

            BottleView(
                vibrancy: 1,
                dirt: 0,
                showEyes: stage >= 2,
                glow: 0,
                width: pushIn ? 128 : 58,
                height: pushIn ? 320 : 146
            )
            .offset(y: bottleY)
            .rotationEffect(bottleRotation)

            if impactBurst {
                Circle()
                    .fill(RadialGradient(colors: [.white.opacity(0.55), .clear], center: .center, startRadius: 0, endRadius: 60))
                    .frame(width: 130, height: 40)
                    .offset(y: 132)
                    .transition(.opacity)
            }

            if showText {
                Text("I still have a purpose.")
                    .font(Theme.line(26))
                    .foregroundStyle(.white.opacity(0.95))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial, in: Capsule())
                    .glow(Theme.neonCyan, radius: 10, opacity: 0.25)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .offset(y: 210)
            }

            Vignette(strength: pushIn ? 0.7 : 0.4)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Opening scene. A hand drops a plastic bottle onto a rainy city street. It still has a purpose.")
        .onAppear(perform: runSequence)
    }

    private var cityBackground: some View {
        ZStack {
            LinearGradient(colors: [Theme.deepNavy, Theme.nearBlack], startPoint: .top, endPoint: .bottom)
            NeonStreakField(colors: [Theme.neonPink, Theme.neonCyan, Theme.neonPurple], reduceMotion: reduceMotion)
            SkylineCanvas()
            SparkleCanvas(count: 30, color: .white, reduceMotion: reduceMotion)
                .opacity(0.4)
        }
    }

    private func runSequence() {
        let scale = reduceMotion ? 0.7 : 1.0
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.1 * scale))
            withAnimation(.easeIn(duration: 0.6)) { handOffset = reduceMotion ? 0 : 38 }

            try? await Task.sleep(for: .seconds(0.7 * scale))
            stage = 1
            withAnimation(reduceMotion ? .easeInOut(duration: 0.5) : .interpolatingSpring(stiffness: 55, damping: 6)) {
                bottleY = 140
                bottleRotation = .degrees(70)
            }
            withAnimation(.easeOut(duration: 0.4).delay(reduceMotion ? 0.25 : 0.5)) {
                handOpacity = 0
            }

            try? await Task.sleep(for: .seconds(reduceMotion ? 0.55 : 0.75))
            game.sound.impactThud()
            Haptics.collision()
            withAnimation(.easeOut(duration: 0.3)) { impactBurst = true }
            withAnimation(.easeInOut(duration: 0.25)) { bottleRotation = .degrees(84) }

            try? await Task.sleep(for: .seconds(0.25))
            withAnimation(.easeOut(duration: 0.3)) { impactBurst = false }

            stage = 2
            withAnimation(reduceMotion ? .easeInOut(duration: 0.6) : .easeInOut(duration: 1.1)) {
                pushIn = true
            }

            try? await Task.sleep(for: .seconds(0.9 * scale))
            withAnimation(.easeIn(duration: 0.6)) { showText = true }

            try? await Task.sleep(for: .seconds(3.4 * scale))
            game.advanceFromOpening()
        }
    }
}

struct SkylineCanvas: View {
    var body: some View {
        Canvas { ctx, size in
            let buildingCount = 9
            for i in 0..<buildingCount {
                let w = size.width / CGFloat(buildingCount)
                let h = size.height * (0.25 + rnd(i, 80) * 0.35)
                let x = CGFloat(i) * w
                let rect = CGRect(x: x, y: size.height - h, width: w * 0.86, height: h)
                ctx.fill(Path(rect), with: .color(Color(red: 0.05, green: 0.07, blue: 0.13)))
                ctx.stroke(Path(rect), with: .color(Theme.neonCyan.opacity(0.1)), lineWidth: 1)

                let rows = Int(h / 22)
                let cols = 3
                for r in 0..<rows {
                    for c in 0..<cols {
                        guard rnd(i * 31 + r * 7 + c + 1, 81) > 0.62 else { continue }
                        let wx = x + 6 + CGFloat(c) * (w * 0.86 - 12) / CGFloat(cols)
                        let wy = size.height - h + 8 + CGFloat(r) * 20
                        let color = [Theme.neonAmber, Theme.neonCyan, Theme.neonPink][(i + r + c) % 3]
                        ctx.fill(Path(CGRect(x: wx, y: wy, width: 5, height: 8)), with: .color(color.opacity(0.8)))
                    }
                }
            }
        }
    }
}
