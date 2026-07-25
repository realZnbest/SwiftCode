import SwiftUI

struct FactoryOriginScene: View {
    @EnvironmentObject var game: GameState

    private let birthXFrac: CGFloat = 0.25

    @State private var heroBottleX: CGFloat = 0.25
    @State private var heroBottleY: CGFloat = 0.77
    @State private var heroBottleVisible = false
    @State private var heroBottleScale: CGFloat = 0.3
    @State private var nozzleY: CGFloat = -0.03
    @State private var flashOpacity: Double = 0
    @State private var bgBottleOffset: CGFloat = 0
    @State private var headSquash: CGFloat = 1
    @State private var ringScale: CGFloat = 0.4
    @State private var ringOpacity: Double = 0

    var body: some View {
        VignetteScene(
            line: "มันถูกผลิตมา เพื่อใช้เพียงครั้งเดียว",
            hold: 5.3,
            showBottle: false,
            textPosition: UnitPoint(x: 0.5, y: 0.65),
            content: { size in
                ZStack {
                    LinearGradient(colors: [Theme.deepNavy, Theme.nearBlack], startPoint: .top, endPoint: .bottom)
                    FactorySilhouetteCanvas().opacity(0.6)
                    ConveyorBeltCanvas()

                    HStack(spacing: 200) {
                        ForEach(0..<12, id: \.self) { _ in
                            BottleView(vibrancy: 1, dirt: 0, showEyes: false, glow: 0, width: 40, height: 98, tilt: .zero)
                                .opacity(0.3)
                        }
                    }
                    .offset(x: bgBottleOffset)
                    .position(x: size.width * 0.5, y: size.height * 0.82 + 25)
                    .onAppear {
                        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                            bgBottleOffset = 240
                        }
                    }

                    BottleView(
                        vibrancy: 1, dirt: 0, showEyes: false,
                        glow: 0.35, width: 60, height: 148, tilt: .zero
                    )
                    .scaleEffect(heroBottleScale)
                    .opacity(heroBottleVisible ? 1 : 0)
                    .position(x: size.width * heroBottleX, y: size.height * heroBottleY)

                    CappingMachineView(size: size, xFrac: birthXFrac, headY: size.height * nozzleY, capping: flashOpacity > 0, squash: headSquash)

                    Circle()
                        .stroke(Theme.cleanCyan, lineWidth: 3.5)
                        .frame(width: 70, height: 70)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)
                        .position(x: size.width * birthXFrac, y: size.height * 0.72)

                    if flashOpacity > 0 {
                        Circle()
                            .fill(Theme.neonCyan)
                            .frame(width: 104, height: 104)
                            .blur(radius: 22)
                            .opacity(flashOpacity)
                            .position(x: size.width * birthXFrac, y: size.height * 0.75)
                    }

                    LightRaysCanvas(color: Theme.cleanCyan, count: 3)
                    SparkleCanvas(count: 18, color: .white).opacity(0.4)
                }
                .onAppear(perform: runAnimation)
            },
            onFinish: { game.advanceFromFactoryOrigin() }
        )
    }

    private let hoverY: CGFloat = 0.58
    private let punchY: CGFloat = 0.69

    private func stampBeat() {
        game.sound.impactThud()
        Haptics.collision()
        withAnimation(.spring(response: 0.13, dampingFraction: 0.42)) { headSquash = 0.66 }
        ringScale = 0.35
        ringOpacity = 0.8
        withAnimation(.easeOut(duration: 0.5)) {
            ringScale = 2.1
            ringOpacity = 0
        }
        game.sound.success()
        Haptics.success()
        withAnimation(.easeOut(duration: 0.08)) { flashOpacity = 0.9 }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.6)) {
            heroBottleVisible = true
            heroBottleScale = 1.0
        }
        withAnimation(.easeIn(duration: 0.4).delay(0.1)) { flashOpacity = 0 }
    }

    private func runAnimation() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.0))

            withAnimation(.easeIn(duration: 0.36)) { nozzleY = hoverY }
            try? await Task.sleep(for: .seconds(0.42))

            withAnimation(.easeIn(duration: 0.16)) { nozzleY = punchY }
            try? await Task.sleep(for: .seconds(0.16))

            stampBeat()

            try? await Task.sleep(for: .seconds(0.09))
            withAnimation(.spring(response: 0.22, dampingFraction: 0.55)) { headSquash = 1 }

            try? await Task.sleep(for: .seconds(0.35))
            withAnimation(.easeIn(duration: 0.81)) { nozzleY = -0.03 }
            withAnimation(.interpolatingSpring(stiffness: 70, damping: 14)) {
                heroBottleY = 0.82
            }

            try? await Task.sleep(for: .seconds(0.4))
            withAnimation(.easeInOut(duration: 2.4)) {
                heroBottleX = 1.2
            }
        }
    }
}

private struct CappingMachineView: View {
    var size: CGSize
    var xFrac: CGFloat = 0.5
    var headY: CGFloat
    var capping: Bool
    var squash: CGFloat = 1

    private let housingCenterY: CGFloat = -8
    private let housingHeight: CGFloat = 34
    private let cylinderHeight: CGFloat = 96
    private let headHeight: CGFloat = 26

    var body: some View {
        let housingBottom = housingCenterY + housingHeight / 2
        let cylinderCenterY = housingBottom + cylinderHeight / 2
        let cylinderBottom = housingBottom + cylinderHeight
        let rodTop = cylinderBottom - 16
        let rodBottom = headY - headHeight / 2 + 4
        let rodLen = max(6, rodBottom - rodTop)
        let rodCenterY = rodTop + rodLen / 2
        let midX = size.width * xFrac

        ZStack {
            Rectangle()
                .fill(LinearGradient(colors: [Color(white: 0.5), Color(white: 0.3), Color(white: 0.46)],
                                      startPoint: .leading, endPoint: .trailing))
                .frame(width: 24, height: rodLen)
                .overlay(
                    VStack(spacing: rodLen / 3.4) {
                        ForEach(0..<3, id: \.self) { _ in
                            Rectangle().fill(Color.black.opacity(0.35)).frame(height: 2.5)
                        }
                    }
                )
                .position(x: midX, y: rodCenterY)

            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(colors: [Color(white: 0.28), Color(white: 0.1), Color(white: 0.24)],
                                      startPoint: .leading, endPoint: .trailing))
                .frame(width: 40, height: cylinderHeight)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.14), lineWidth: 1))
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(white: 0.16))
                        .frame(width: 44, height: 7)
                        .offset(y: cylinderHeight / 2 - 4)
                )
                .position(x: midX, y: cylinderCenterY)

            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(colors: [Color(white: 0.44), Color(white: 0.18)], startPoint: .top, endPoint: .bottom))
                .frame(width: 78, height: housingHeight)
                .overlay(
                    HStack(spacing: 46) {
                        boltDot
                        boltDot
                    }
                )
                .overlay(
                    HazardStripeBand()
                        .frame(width: 78, height: 8)
                        .offset(y: housingHeight / 2 - 5)
                )
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.18), lineWidth: 1))
                .position(x: midX, y: housingCenterY)

            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(colors: [Color(white: 0.56), Color(white: 0.24)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 58, height: headHeight)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.35), lineWidth: 1))

                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.cleanCyan)
                    .frame(width: 52, height: 6)
                    .offset(y: headHeight / 2 - 3)
                    .glow(Theme.cleanCyan, radius: capping ? 16 : 5, opacity: capping ? 1 : 0.55)
            }
            .scaleEffect(CGSize(width: 2 - squash, height: squash), anchor: .bottom)
            .position(x: midX, y: headY)
        }
    }

    private var boltDot: some View {
        Circle()
            .fill(Color.black.opacity(0.5))
            .frame(width: 6, height: 6)
            .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
    }
}

private struct HazardStripeBand: View {
    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black.opacity(0.85)))
            let stripeW: CGFloat = 4
            var x: CGFloat = -size.height
            while x < size.width {
                var p = Path()
                p.move(to: CGPoint(x: x, y: size.height))
                p.addLine(to: CGPoint(x: x + size.height, y: 0))
                p.addLine(to: CGPoint(x: x + size.height + stripeW, y: 0))
                p.addLine(to: CGPoint(x: x + stripeW, y: size.height))
                p.closeSubpath()
                ctx.fill(p, with: .color(Theme.neonAmber.opacity(0.85)))
                x += stripeW * 2
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 1.5))
    }
}
