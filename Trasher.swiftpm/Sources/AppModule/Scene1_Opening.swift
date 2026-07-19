import SwiftUI

/// 10-15s. A neon city at night, a hand lets go of a bottle, the camera
/// pushes in close enough that its highlight reads like a quiet gaze.
struct OpeningScene: View {
    @EnvironmentObject var game: GameState

    @State private var stage = 0
    // 0...1 progress through the fall, not an absolute position — resolved
    // against the GeometryReader's *live* size every render and interpolated
    // between a start point and the ground band's own position (see
    // `groundHeight`), so the landing spot always lines up with where
    // streetGround is actually drawn instead of a guessed fraction of
    // screen height. An earlier version stored the target as absolute
    // points computed once from a size captured in onAppear; that captured
    // size was unreliable (SwiftUI can report a transient/incorrect size on
    // a view's first layout pass), so the bottle ended up resting nowhere
    // near the actual ground band.
    @State private var fallProgress: CGFloat = 0
    @State private var bottleRotation: Angle = .degrees(-8)
    @State private var handOffset: CGFloat = 0
    @State private var handOpacity: Double = 1
    @State private var showText = false
    @State private var pushIn = false
    @State private var impactBurst = false

    private var reduceMotion: Bool { game.reduceMotion }

    /// Height of the street/pavement band the bottle actually lands on
    /// (see `streetGround`) — kept as one constant so the resting position
    /// lines up with where the ground is actually drawn, instead of two
    /// independently-guessed numbers.
    private let groundHeight: CGFloat = 170

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
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
                    .position(x: size.width / 2, y: size.height * 0.3 + handOffset)
                    .opacity(handOpacity)

                BottleView(
                    vibrancy: 1,
                    dirt: 0,
                    showEyes: stage >= 2,
                    glow: 0,
                    width: pushIn ? 128 : 58,
                    height: pushIn ? 320 : 146
                )
                .rotationEffect(bottleRotation)
                .position(x: size.width / 2, y: bottleY(in: size))

                if impactBurst {
                    Circle()
                        .fill(RadialGradient(colors: [.white.opacity(0.55), .clear], center: .center, startRadius: 0, endRadius: 60))
                        .frame(width: 130, height: 40)
                        .position(x: size.width / 2, y: size.height - groundHeight + 20)
                        .transition(.opacity)
                }

                if showText {
                    Text("มันยังคงมีเป้าหมายอยู่")
                        .font(Theme.line(26))
                        .foregroundStyle(.white.opacity(0.95))
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(.ultraThinMaterial, in: Capsule())
                        .glow(Theme.neonCyan, radius: 10, opacity: 0.25)
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        .position(x: size.width / 2, y: size.height * 0.55)
                }

                Vignette(strength: pushIn ? 0.7 : 0.4)
            }
            .onAppear(perform: runSequence)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Opening scene. A hand drops a plastic bottle onto a rainy city street. It still has a purpose.")
    }

    /// The bottle's Y position, interpolated between its starting drop
    /// point and a resting spot flush with the top of `streetGround`, so it
    /// visibly lands on the ground band instead of stopping in mid-air.
    private func bottleY(in size: CGSize) -> CGFloat {
        let startY = size.height * 0.3
        let restY = size.height - groundHeight + 40
        return startY + (restY - startY) * fallProgress
    }

    private var cityBackground: some View {
        ZStack {
            LinearGradient(colors: [Theme.deepNavy, Theme.nearBlack], startPoint: .top, endPoint: .bottom)
            NeonStreakField(colors: [Theme.neonPink, Theme.neonCyan, Theme.neonPurple], reduceMotion: reduceMotion)
            SkylineCanvas()
            SparkleCanvas(count: 30, color: .white, reduceMotion: reduceMotion)
                .opacity(0.4)
            RainCanvas(intensity: 0.5, reduceMotion: reduceMotion)
            streetGround
        }
    }

    /// The pavement the bottle actually lands on. Without this the drop
    /// had nothing to read as "landing" against — just a hand releasing it
    /// into a dark gradient. Puddle glints tie into the "rainy city
    /// street" the accessibility label already describes.
    private var streetGround: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.06, blue: 0.08), Color(red: 0.02, green: 0.02, blue: 0.03)],
                startPoint: .top, endPoint: .bottom
            )
            Rectangle().fill(Color.white.opacity(0.12)).frame(height: 2)
            HStack(spacing: 70) {
                ForEach(0..<5, id: \.self) { i in
                    Capsule()
                        .fill([Theme.neonCyan, Theme.neonPink, Theme.neonPurple][i % 3].opacity(0.16))
                        .frame(width: 46, height: 130)
                        .blur(radius: 10)
                }
            }
            .offset(y: 6)
        }
        .frame(height: 170)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }

    private func runSequence() {
        let scale = reduceMotion ? 0.7 : 1.0
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.1 * scale))
            withAnimation(.easeIn(duration: 0.6)) { handOffset = reduceMotion ? 0 : 38 }

            try? await Task.sleep(for: .seconds(0.7 * scale))
            stage = 1
            // An accelerating fall (not the old loose, underdamped spring)
            // so the drop is visually *done* by the time impact fires
            // below, instead of still drifting toward the target.
            withAnimation(.easeIn(duration: reduceMotion ? 0.45 : 0.65)) {
                fallProgress = 1
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
            try? await Task.sleep(for: .seconds(0.5 * scale))

            stage = 2
            withAnimation(reduceMotion ? .easeInOut(duration: 0.6) : .easeInOut(duration: 1.1)) {
                pushIn = true
            }

            try? await Task.sleep(for: .seconds(0.9 * scale))
            withAnimation(.easeIn(duration: 0.6)) { showText = true }

            try? await Task.sleep(for: .seconds(3.4 * scale))
            game.advanceFromVendingAndDiscard()
        }
    }
}

struct SkylineCanvas: View {
    var body: some View {
        Canvas { ctx, size in
            let buildingCount = 9
            let hazeColor = Color(red: 0.2, green: 0.28, blue: 0.4)

            for i in 0..<buildingCount {
                let w = size.width / CGFloat(buildingCount)
                let h = size.height * (0.25 + rnd(i, 80) * 0.35)
                let x = CGFloat(i) * w
                let rect = CGRect(x: x, y: size.height - h, width: w * 0.86, height: h)

                // Atmospheric perspective: buildings toward the edges read
                // as farther away, so they lighten and desaturate slightly
                // into the haze instead of all sitting at the same depth.
                let depth = abs(Double(i) - Double(buildingCount - 1) / 2) / (Double(buildingCount - 1) / 2)
                let fill = Color(red: 0.05, green: 0.07, blue: 0.13).mix(with: hazeColor, amount: depth * 0.55)

                ctx.fill(Path(rect), with: .color(fill))
                ctx.stroke(Path(rect), with: .color(Theme.neonCyan.opacity(0.1)), lineWidth: 1)

                let rows = Int(h / 22)
                let cols = 3
                for r in 0..<rows {
                    for c in 0..<cols {
                        guard rnd(i * 31 + r * 7 + c + 1, 81) > 0.62 else { continue }
                        let wx = x + 6 + CGFloat(c) * (w * 0.86 - 12) / CGFloat(cols)
                        let wy = size.height - h + 8 + CGFloat(r) * 20
                        let color = [Theme.neonAmber, Theme.neonCyan, Theme.neonPink][(i + r + c) % 3]
                        ctx.opacity = 1 - depth * 0.35
                        ctx.fill(Path(CGRect(x: wx, y: wy, width: 5, height: 8)), with: .color(color.opacity(0.8)))
                    }
                }
            }

            // Ground-level haze where rain and light mix at the base of
            // the buildings.
            ctx.opacity = 1
            let hazeBand = CGRect(x: 0, y: size.height * 0.82, width: size.width, height: size.height * 0.18)
            ctx.fill(Path(hazeBand), with: .linearGradient(
                Gradient(colors: [.clear, hazeColor.opacity(0.22)]),
                startPoint: CGPoint(x: 0, y: hazeBand.minY), endPoint: CGPoint(x: 0, y: hazeBand.maxY)
            ))
        }
    }
}
