import SwiftUI

struct OpeningScene: View {
    @EnvironmentObject var game: GameState

    @State private var stage = 0
    @State private var fallProgress: CGFloat = 0
    @State private var bottleRotation: Angle = .degrees(-8)
    @State private var sceneStart = Date()
    @State private var showText = false
    @State private var pushIn = false
    @State private var impactBurst = false

    private let groundHeight: CGFloat = 170
    private let walkInDuration: Double = 1.0
    private let dropAt: Double = 1.8
    private let walkOutStart: Double = 2.0
    private let walkOutEnd: Double = 3.3

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

                if stage < 2 {
                    TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                        let elapsed = context.date.timeIntervalSince(sceneStart)
                        if elapsed < walkOutEnd {
                            let s = littererState(at: elapsed)
                            LittererFigure(
                                anchorX: s.x * size.width,
                                anchorY: size.height * 0.3 + 46,
                                legPhase: s.legPhase,
                                armRaise: s.armRaise,
                                stride: s.stride
                            )
                            .opacity(s.opacity)
                        }
                    }
                    .allowsHitTesting(false)
                }

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
    }

    private func bottleY(in size: CGSize) -> CGFloat {
        let startY = size.height * 0.3
        let restY = size.height - groundHeight + 40
        return startY + (restY - startY) * fallProgress
    }

    private var cityBackground: some View {
        ZStack {
            LinearGradient(colors: [Theme.deepNavy, Theme.nearBlack], startPoint: .top, endPoint: .bottom)
            NeonStreakField(colors: [Theme.neonPink, Theme.neonCyan, Theme.neonPurple])
            SkylineCanvas()
            SparkleCanvas(count: 30, color: .white)
                .opacity(0.4)
            RainCanvas(intensity: 0.5)
            streetGround
        }
    }

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
        let scale = 1.0
        sceneStart = Date()
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.8 * scale))
            stage = 1
            withAnimation(.easeIn(duration: 0.65)) {
                fallProgress = 1
                bottleRotation = .degrees(70)
            }

            try? await Task.sleep(for: .seconds(0.75))
            game.sound.impactThud()
            Haptics.collision()
            withAnimation(.easeOut(duration: 0.3)) { impactBurst = true }
            withAnimation(.easeInOut(duration: 0.25)) { bottleRotation = .degrees(84) }

            try? await Task.sleep(for: .seconds(0.25))
            withAnimation(.easeOut(duration: 0.3)) { impactBurst = false }
            try? await Task.sleep(for: .seconds(0.5 * scale))

            stage = 2
            withAnimation(.easeInOut(duration: 1.1)) {
                pushIn = true
            }

            try? await Task.sleep(for: .seconds(0.9 * scale))
            withAnimation(.easeIn(duration: 0.6)) { showText = true }

            try? await Task.sleep(for: .seconds(3.4 * scale))
            game.advanceFromVendingAndDiscard()
        }
    }

    private func littererState(at elapsed: Double) -> LittererState {
        let startX: CGFloat = -0.12
        let standX: CGFloat = 0.5
        let exitX: CGFloat = 1.15

        var x = startX
        var legPhase = 0.0
        var armRaise = 0.0
        var stride: Double = 0
        var opacity = 1.0

        switch elapsed {
        case ..<walkInDuration:
            let t = max(0, elapsed / walkInDuration)
            let eased = 1 - pow(1 - t, 3)
            x = startX + (standX - startX) * CGFloat(eased)
            legPhase = elapsed * 9.5
            armRaise = min(1, t * 1.6)
            stride = min(1, t * 5)
            opacity = min(1, elapsed / 0.25)

        case walkInDuration..<dropAt:
            x = standX
            legPhase = walkInDuration * 9.5
            let t = max(0, min(1, (elapsed - walkInDuration) / (dropAt - walkInDuration)))
            armRaise = 1 - t
            stride = max(0, 1 - t * 6)

        case dropAt..<walkOutStart:
            x = standX
            legPhase = walkInDuration * 9.5
            armRaise = 0
            stride = 0

        case walkOutStart..<walkOutEnd:
            let t = max(0, min(1, (elapsed - walkOutStart) / (walkOutEnd - walkOutStart)))
            let eased = t * t
            x = standX + (exitX - standX) * CGFloat(eased)
            legPhase = (walkInDuration + (elapsed - walkOutStart)) * 9.5
            armRaise = 0
            stride = min(1, t * 6)
            opacity = 1 - max(0, (elapsed - (walkOutEnd - 0.3)) / 0.3)

        default:
            opacity = 0
        }

        return LittererState(x: x, legPhase: legPhase, armRaise: armRaise, stride: stride, opacity: opacity)
    }
}

private struct LittererState {
    var x: CGFloat
    var legPhase: Double
    var armRaise: Double
    var stride: Double
    var opacity: Double
}

private struct LittererFigure: View {
    var anchorX: CGFloat
    var anchorY: CGFloat
    var legPhase: Double
    var armRaise: Double
    var stride: Double

    private let skin = Color(red: 0.34, green: 0.37, blue: 0.44)
    private let legHeight: CGFloat = 40

    /// Sharper than a plain sine so the limb snaps through the swing and eases into contact,
    /// which reads as an actual step instead of a metronome.
    private func gait(_ phase: Double) -> Double {
        let s = sin(phase)
        return (s < 0 ? -1.0 : 1.0) * pow(abs(s), 0.72)
    }

    private var backLegAngle: Double { gait(legPhase + .pi) * 28 * stride }
    private var frontLegAngle: Double { gait(legPhase) * 28 * stride }
    private var backArmAngle: Double { -gait(legPhase) * 22 * stride }
    private var frontArmAngle: Double {
        -70 * armRaise + gait(legPhase) * 22 * stride * (1 - armRaise)
    }

    // Knee/elbow-bend illusion: shorten the limb slightly while it's swinging forward.
    private func foreshorten(_ phase: Double) -> CGFloat {
        CGFloat(1 - 0.14 * max(0, sin(phase)) * stride)
    }

    private var bob: CGFloat { CGFloat(-abs(gait(legPhase * 2)) * 2.2 * stride) }
    private var lean: Double { -4 * stride }
    private var shadowScaleX: CGFloat { CGFloat(1 - 0.08 * stride) }

    var body: some View {
        ZStack(alignment: .bottom) {
            Ellipse()
                .fill(Color.black.opacity(0.3))
                .frame(width: 30, height: 8)
                .scaleEffect(x: shadowScaleX)

            // back leg — hangs straight from the hip, no extra lift
            Capsule().fill(skin).frame(width: 8, height: legHeight)
                .scaleEffect(x: 1, y: foreshorten(legPhase + .pi), anchor: .top)
                .rotationEffect(.degrees(backLegAngle), anchor: .top)
                .offset(x: -3)

            // back arm
            Capsule().fill(skin).frame(width: 6, height: 24)
                .rotationEffect(.degrees(backArmAngle), anchor: .top)
                .offset(x: -4, y: -legHeight + 8)

            VStack(spacing: 3) {
                Circle().fill(skin).frame(width: 16, height: 16)
                RoundedRectangle(cornerRadius: 5).fill(skin.opacity(0.92)).frame(width: 15, height: 33)
            }
            .overlay(
                VStack(spacing: 3) {
                    Circle().stroke(Theme.neonCyan.opacity(0.25), lineWidth: 1).frame(width: 16, height: 16)
                    RoundedRectangle(cornerRadius: 5).stroke(Theme.neonCyan.opacity(0.25), lineWidth: 1).frame(width: 15, height: 33)
                }
            )
            .rotationEffect(.degrees(lean), anchor: .bottom)
            .offset(y: -legHeight + bob)

            // front leg
            Capsule().fill(skin).frame(width: 8, height: legHeight)
                .scaleEffect(x: 1, y: foreshorten(legPhase), anchor: .top)
                .rotationEffect(.degrees(frontLegAngle), anchor: .top)
                .offset(x: 3)

            // front arm — raised holding the bottle, swings down as armRaise falls to 0
            Capsule().fill(skin).frame(width: 6, height: 24)
                .rotationEffect(.degrees(frontArmAngle), anchor: .top)
                .offset(x: 4, y: -legHeight + 8)
        }
        .position(x: anchorX, y: anchorY)
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

            ctx.opacity = 1
            let hazeBand = CGRect(x: 0, y: size.height * 0.82, width: size.width, height: size.height * 0.18)
            ctx.fill(Path(hazeBand), with: .linearGradient(
                Gradient(colors: [.clear, hazeColor.opacity(0.22)]),
                startPoint: CGPoint(x: 0, y: hazeBand.minY), endPoint: CGPoint(x: 0, y: hazeBand.maxY)
            ))
        }
    }
}
