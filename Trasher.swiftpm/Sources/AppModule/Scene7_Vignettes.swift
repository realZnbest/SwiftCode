import SwiftUI

struct VignetteScene<Content: View>: View {
    @EnvironmentObject var game: GameState

    var line: String
    var hold: Double = 5.0
    var vignetteStrength: Double = 0.55
    var showBottle: Bool = true
    var bottleWidth: CGFloat = 60
    var bottleHeight: CGFloat = 148
    var bottlePosition: UnitPoint = UnitPoint(x: 0.5, y: 0.55)
    var bottleShowEyes: Bool = false
    var bottleGlow: Double = 0
    var bottleTilt: Angle = .zero
    var textPosition: UnitPoint = UnitPoint(x: 0.5, y: 0.86)
    var content: (CGSize) -> Content
    var onFinish: () -> Void

    @State private var showText = false

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                content(size)

                if showBottle {
                    BottleView(
                        vibrancy: game.vibrancy, dirt: game.grime, showEyes: bottleShowEyes,
                        glow: bottleGlow, width: bottleWidth, height: bottleHeight, tilt: bottleTilt
                    )
                    .position(x: bottlePosition.x * size.width, y: bottlePosition.y * size.height)
                }

                if showText {
                    Text(line)
                        .font(Theme.line(22))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 26)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: Capsule())
                        .transition(.opacity)
                        .position(x: textPosition.x * size.width, y: textPosition.y * size.height)
                }

                Vignette(strength: vignetteStrength)
            }
        }
        .onAppear(perform: run)
    }

    private func run() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.5))
            withAnimation(.easeIn(duration: 0.5)) { showText = true }
            try? await Task.sleep(for: .seconds(hold))
            withAnimation(.easeOut(duration: 0.35)) { showText = false }
            try? await Task.sleep(for: .seconds(0.3))
            onFinish()
        }
    }
}

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

struct StormDrainTunnelScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "ดำดิ่งสู่ความมืดมิด จนไม่มีใครมองเห็น",
            vignetteStrength: 0.7,
            showBottle: false,
            content: { size in
                ZStack {
                    Theme.nearBlack
                    Canvas { ctx, canvasSize in
                        for i in 0..<5 {
                            let r = canvasSize.width * (0.15 + CGFloat(i) * 0.18)
                            ctx.stroke(
                                Path(ellipseIn: CGRect(x: canvasSize.width / 2 - r / 2, y: canvasSize.height / 2 - r / 2, width: r, height: r)),
                                with: .color(Theme.cleanCyan.opacity(0.09)), lineWidth: 2
                            )
                        }
                    }
                    BubbleCanvas(count: 22, color: .white).opacity(0.5)
                    SmokeCanvas(intensity: 0.6, color: Theme.murkGreen)

                    TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                        let t = context.date.timeIntervalSinceReferenceDate
                        BottleView(
                            vibrancy: game.vibrancy, dirt: game.grime, showEyes: false,
                            width: 56, height: 138, tilt: .degrees(t * 230)
                        )
                        .position(x: size.width * 0.5, y: size.height * 0.55)
                    }
                }
            },
            onFinish: { game.advanceFromStormDrainTunnel() }
        )
    }
}

struct SecondBottleMirrorScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "ไม่ใช่ทุกชิ้นที่จะออกมาได้",
            bottlePosition: UnitPoint(x: 0.38, y: 0.48),
            bottleShowEyes: true,
            content: { size in
                ZStack {
                    LinearGradient(
                        colors: [Color(red: 0.04, green: 0.13, blue: 0.16), Color(red: 0.02, green: 0.05, blue: 0.06)],
                        startPoint: .top, endPoint: .bottom
                    )
                    BubbleCanvas(count: 14, color: Theme.murkBrown)
                    SmokeCanvas(intensity: 0.5, color: Theme.murkGreen)
                    FishSilhouettesCanvas(darkness: 0.6)

                    BottleView(vibrancy: 0.25, dirt: 0.8, showEyes: false, width: 48, height: 118)
                        .saturation(0.2)
                        .opacity(0.55)
                        .rotationEffect(.degrees(35))
                        .position(x: size.width * 0.68, y: size.height * 0.62)
                }
            },
            onFinish: { game.advanceFromSecondBottleMirror() }
        )
    }
}

struct NightIntoDayScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "เมื่อเวลาผ่านไป",
            content: { size in
                ZStack {
                    LinearGradient(
                        colors: [Color(red: 0.09, green: 0.13, blue: 0.28), Color(red: 0.72, green: 0.55, blue: 0.4)],
                        startPoint: .top, endPoint: .bottom
                    )
                    GlowOrb(color: Theme.neonAmber, size: 130)
                        .position(x: size.width * 0.78, y: size.height * 0.62)
                    CloudDriftCanvas().opacity(0.6)
                    SparkleCanvas(count: 20, color: .white).opacity(0.25)
                }
            },
            onFinish: { game.advanceFromNightIntoDay() }
        )
    }
}

struct FishingNetRescueScene: View {
    @EnvironmentObject var game: GameState

    @State private var boatX: CGFloat = -0.18
    @State private var joystickOffset: CGSize = .zero
    @State private var netProgress: CGFloat = 0
    @State private var boatDip: CGFloat = 0
    @State private var releaseAt: Double? = nil
    @State private var showControls = false
    @State private var collecting = false
    @State private var caught = false
    @State private var sceneStart = Date()
    @State private var timeoutTask: Task<Void, Never>? = nil

    private let targetX: CGFloat = 0.5
    private let lockTolerance: CGFloat = 0.05

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let surfaceY = size.height * 0.40
            let underwaterH = size.height - surfaceY
            let driftY = size.height * 0.72
            let inRange = abs(boatX - targetX) < lockTolerance

            ZStack {
                TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                    let t = context.date.timeIntervalSince(sceneStart)
                    let boatCenterX = size.width * boatX
                    let boatBob = CGFloat(sin(t * 1.4)) * 4
                    let netTopY = surfaceY - 58 + boatBob + boatDip
                    let catchY = netTopY + (driftY - netTopY) * netProgress
                    let swingRaw: CGFloat = {
                        guard let r = releaseAt else { return 0 }
                        let e = t - r
                        guard e >= 0 else { return 0 }
                        return CGFloat(sin(e * 6.5) * exp(-e * 2.0)) * 16
                    }()
                    let netCatchX = boatCenterX + (caught ? swingRaw * 0.15 : swingRaw)
                    let bottleSway = collecting ? 0 : CGFloat(sin(t * 0.9)) * 10
                    let bottlePos = caught
                        ? CGPoint(x: netCatchX, y: catchY + 16)
                        : CGPoint(x: size.width * targetX + bottleSway,
                                  y: driftY + (collecting ? 0 : CGFloat(sin(t * 1.6)) * 6))

                    ZStack {
                        Theme.deepNavy

                        LinearGradient(
                            colors: [
                                Color(red: 0.10, green: 0.42, blue: 0.48),
                                Color(red: 0.04, green: 0.20, blue: 0.28),
                                Color(red: 0.02, green: 0.08, blue: 0.14),
                                Theme.deepNavy
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                        .frame(height: underwaterH)
                        .frame(maxHeight: .infinity, alignment: .bottom)

                        ZStack {
                            LightRaysCanvas(color: Theme.cleanCyan, count: 6)
                            FishSilhouettesCanvas(darkness: 0.22)
                            OceanFloorCanvas()
                            BubbleCanvas(count: 22, color: .white)
                        }
                        .frame(width: size.width, height: underwaterH)
                        .position(x: size.width / 2, y: surfaceY + underwaterH / 2)
                        .clipped()

                        LinearGradient(
                            colors: [Color(red: 0.52, green: 0.77, blue: 0.92), Color(red: 0.82, green: 0.91, blue: 0.96)],
                            startPoint: .top, endPoint: .bottom
                        )
                        .frame(height: surfaceY)
                        .frame(maxHeight: .infinity, alignment: .top)

                        Circle()
                            .fill(RadialGradient(colors: [Color(red: 1, green: 0.96, blue: 0.82), .clear],
                                                 center: .center, startRadius: 4, endRadius: 70))
                            .frame(width: 150, height: 150)
                            .position(x: size.width * 0.82, y: surfaceY * 0.34)

                        CloudDriftCanvas()
                            .frame(width: size.width, height: surfaceY * 0.85)
                            .frame(maxHeight: .infinity, alignment: .top)
                            .opacity(0.75)

                        WaterlineCanvas(surfaceY: surfaceY, elapsed: t)

                        BottleView(
                            vibrancy: game.vibrancy, dirt: game.grime, showEyes: true,
                            width: 30, height: 74, tilt: caught ? .zero : .degrees(Double(sin(t * 0.7)) * 8)
                        )
                        .saturation(caught ? 1 : 0.6)
                        .position(bottlePos)

                        RescueNetCanvas(topX: boatCenterX, topY: netTopY, catchX: netCatchX, catchY: catchY,
                                        visible: collecting || caught)

                        CollectorBoatView()
                            .frame(width: 190, height: 150)
                            .position(x: boatCenterX, y: surfaceY - 30 + boatBob + boatDip)

                        Vignette(strength: 0.5)
                    }
                }

                if showControls && !collecting {
                    SteerArrow(active: inRange)
                        .position(x: size.width * targetX, y: surfaceY - 96)
                        .transition(.opacity)

                    Joystick(offset: $joystickOffset)
                        .position(x: size.width * 0.17, y: size.height * 0.84)
                        .transition(.opacity)

                    Button(action: { collect() }) {
                        Text("เก็บขวด")
                            .font(Theme.line(22))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 34)
                            .padding(.vertical, 14)
                            .background((inRange ? Theme.freshGreen : Color(white: 0.4)).opacity(inRange ? 0.94 : 0.55),
                                        in: Capsule())
                            .overlay(Capsule().stroke(.white.opacity(inRange ? 0.6 : 0.25), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .disabled(!inRange)
                    .position(x: size.width * 0.83, y: size.height * 0.84)
                    .transition(.opacity)
                }
            }
        }
        .onAppear(perform: start)
        .onDisappear { timeoutTask?.cancel() }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(0.02))
                guard showControls, !collecting, !caught, joystickOffset.width != 0 else { continue }
                let dir: CGFloat = joystickOffset.width > 0 ? 1 : -1
                boatX = min(0.9, max(0.1, boatX + dir * 0.006))
            }
        }
    }

    private func start() {
        boatX = -0.18
        netProgress = 0
        boatDip = 0
        releaseAt = nil
        caught = false
        collecting = false
        showControls = false
        sceneStart = Date()
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.4))
            withAnimation(.easeInOut(duration: 1.3)) { boatX = 0.2 }
            try? await Task.sleep(for: .seconds(1.4))
            withAnimation(.easeIn(duration: 0.3)) { showControls = true }
            timeoutTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(18))
                guard !collecting else { return }
                collect(force: true)
            }
        }
    }

    private func collect(force: Bool = false) {
        guard !collecting else { return }
        guard force || abs(boatX - targetX) < lockTolerance else { return }
        collecting = true
        timeoutTask?.cancel()
        withAnimation(.easeOut(duration: 0.25)) { boatX = targetX }
        withAnimation(.easeIn(duration: 0.2)) { showControls = false }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.32))
            game.sound.impactThud()
            Haptics.collision()
            withAnimation(.easeOut(duration: 0.2)) { boatDip = 8 }
            withAnimation(.easeInOut(duration: 0.26)) { netProgress = -0.1 }
            try? await Task.sleep(for: .seconds(0.28))
            releaseAt = Date().timeIntervalSince(sceneStart)
            game.sound.splash()
            withAnimation(.spring(response: 0.95, dampingFraction: 0.7)) { netProgress = 1 }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) { boatDip = 0 }
            try? await Task.sleep(for: .seconds(1.2))
            withAnimation(.easeOut(duration: 0.2)) { caught = true }
            game.sound.success()
            Haptics.success()
            withAnimation(.easeOut(duration: 0.1)) { boatDip = -5 }
            withAnimation(.interpolatingSpring(stiffness: 32, damping: 11)) { netProgress = 0 }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.55).delay(0.1)) { boatDip = 0 }
            try? await Task.sleep(for: .seconds(1.2))
            withAnimation(.easeInOut(duration: 2.0)) { boatX = 1.32 }
            try? await Task.sleep(for: .seconds(1.7))
            game.advanceFromFishingNetRescue()
        }
    }
}

private struct SteerArrow: View {
    let active: Bool
    @State private var bounce = false

    var body: some View {
        DownTriangle()
            .fill(active ? Theme.freshGreen : Color(red: 0.96, green: 0.6, blue: 0.15))
            .frame(width: 34, height: 26)
            .shadow(color: (active ? Theme.freshGreen : Color(red: 0.96, green: 0.6, blue: 0.15)).opacity(0.7), radius: 8)
            .offset(y: bounce ? 9 : -7)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { bounce = true }
            }
    }
}

private struct DownTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

private struct Joystick: View {
    @Binding var offset: CGSize

    private let radius: CGFloat = 54
    private let maxDist: CGFloat = 46
    private let knobSize: CGFloat = 48

    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1.5))

            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white.opacity(0.5))
                .offset(x: -radius + 16)
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white.opacity(0.5))
                .offset(x: radius - 16)

            Circle()
                .fill(Theme.freshGreen.opacity(0.9))
                .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 2))
                .frame(width: knobSize, height: knobSize)
                .offset(offset)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let dx = value.translation.width
                            let dist = min(abs(dx), maxDist)
                            let sign: CGFloat = dx > 0 ? 1 : -1
                            offset = CGSize(width: sign * dist, height: 0)
                        }
                        .onEnded { _ in
                            withAnimation(.interactiveSpring) { offset = .zero }
                        }
                )
        }
        .frame(width: radius * 2, height: radius * 2)
    }
}

private struct WaterlineCanvas: View {
    let surfaceY: CGFloat
    let elapsed: Double

    var body: some View {
        Canvas { ctx, size in
            var wave = Path()
            let steps = 46
            for i in 0...steps {
                let x = size.width * CGFloat(i) / CGFloat(steps)
                let y = surfaceY + sin(CGFloat(i) * 0.55 + CGFloat(elapsed) * 1.6) * 3
                if i == 0 { wave.move(to: CGPoint(x: x, y: y)) } else { wave.addLine(to: CGPoint(x: x, y: y)) }
            }
            ctx.stroke(wave, with: .color(.white.opacity(0.55)), lineWidth: 2.5)
            ctx.stroke(wave, with: .color(Theme.cleanCyan.opacity(0.4)), lineWidth: 6)
        }
        .allowsHitTesting(false)
    }
}

private struct RescueNetCanvas: View {
    let topX: CGFloat
    let topY: CGFloat
    let catchX: CGFloat
    let catchY: CGFloat
    let visible: Bool

    var body: some View {
        Canvas { ctx, size in
            guard visible else { return }
            let hw: CGFloat = 30
            var ropes = Path()
            ropes.move(to: CGPoint(x: topX - 12, y: topY)); ropes.addLine(to: CGPoint(x: catchX - hw, y: catchY))
            ropes.move(to: CGPoint(x: topX + 12, y: topY)); ropes.addLine(to: CGPoint(x: catchX + hw, y: catchY))
            ctx.stroke(ropes, with: .color(.white.opacity(0.5)), lineWidth: 1.6)

            let hoopRect = CGRect(x: catchX - hw, y: catchY - 8, width: hw * 2, height: 16)
            let pouchTip = CGPoint(x: catchX, y: catchY + 46)
            let cols = 6
            for c in 0...cols {
                let f = CGFloat(c) / CGFloat(cols)
                let rimX = hoopRect.minX + hoopRect.width * f
                var strand = Path()
                strand.move(to: CGPoint(x: rimX, y: catchY))
                strand.addQuadCurve(to: pouchTip, control: CGPoint(x: rimX + (catchX - rimX) * 0.5, y: catchY + 40))
                ctx.stroke(strand, with: .color(.white.opacity(0.32)), lineWidth: 1.0)
            }
            for r in 1...3 {
                let ry = catchY + CGFloat(r) * 12
                let rw = hw * (1 - CGFloat(r) * 0.24)
                var arc = Path()
                arc.move(to: CGPoint(x: catchX - rw, y: ry))
                arc.addQuadCurve(to: CGPoint(x: catchX + rw, y: ry), control: CGPoint(x: catchX, y: ry + 6))
                ctx.stroke(arc, with: .color(.white.opacity(0.28)), lineWidth: 1.0)
            }
            ctx.stroke(Path(ellipseIn: hoopRect), with: .color(.white.opacity(0.75)), lineWidth: 2.5)
        }
        .allowsHitTesting(false)
    }
}

private struct CollectorBoatView: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let deckY: CGFloat = 96

            var hull = Path()
            hull.move(to: CGPoint(x: 14, y: deckY))
            hull.addLine(to: CGPoint(x: w - 14, y: deckY))
            hull.addLine(to: CGPoint(x: w - 30, y: 132))
            hull.addQuadCurve(to: CGPoint(x: 30, y: 132), control: CGPoint(x: w / 2, y: 150))
            hull.closeSubpath()
            ctx.fill(hull, with: .linearGradient(
                Gradient(colors: [Color(red: 0.16, green: 0.52, blue: 0.48), Color(red: 0.05, green: 0.26, blue: 0.28)]),
                startPoint: CGPoint(x: 0, y: deckY), endPoint: CGPoint(x: 0, y: 134)))

            var stripe = Path()
            stripe.move(to: CGPoint(x: 20, y: deckY + 11))
            stripe.addLine(to: CGPoint(x: w - 26, y: deckY + 11))
            ctx.stroke(stripe, with: .color(Theme.freshGreen.opacity(0.9)), lineWidth: 6)

            var deckLine = Path()
            deckLine.move(to: CGPoint(x: 14, y: deckY))
            deckLine.addLine(to: CGPoint(x: w - 14, y: deckY))
            ctx.stroke(deckLine, with: .color(.white.opacity(0.5)), lineWidth: 2)

            var bin = Path()
            bin.move(to: CGPoint(x: 34, y: deckY))
            bin.addLine(to: CGPoint(x: 78, y: deckY))
            bin.addLine(to: CGPoint(x: 72, y: deckY - 30))
            bin.addLine(to: CGPoint(x: 40, y: deckY - 30))
            bin.closeSubpath()
            ctx.fill(bin, with: .color(Color(red: 0.14, green: 0.38, blue: 0.3)))
            ctx.stroke(bin, with: .color(Theme.freshGreen.opacity(0.7)), lineWidth: 1.5)

            let cabin = CGRect(x: 118, y: deckY - 40, width: 46, height: 40)
            ctx.fill(Path(roundedRect: cabin, cornerRadius: 5), with: .color(Color(red: 0.86, green: 0.89, blue: 0.92)))
            ctx.fill(Path(roundedRect: CGRect(x: 126, y: deckY - 31, width: 20, height: 15), cornerRadius: 3),
                     with: .color(Color(red: 0.3, green: 0.56, blue: 0.72)))

            var gantry = Path()
            gantry.move(to: CGPoint(x: 80, y: deckY))
            gantry.addLine(to: CGPoint(x: 95, y: deckY - 60))
            gantry.move(to: CGPoint(x: 110, y: deckY))
            gantry.addLine(to: CGPoint(x: 95, y: deckY - 60))
            ctx.stroke(gantry, with: .color(Color(red: 0.92, green: 0.62, blue: 0.2)), lineWidth: 4)
            ctx.fill(Path(ellipseIn: CGRect(x: 90, y: deckY - 62, width: 10, height: 10)),
                     with: .color(.black.opacity(0.65)))
        }
        .allowsHitTesting(false)
    }
}

private struct OceanFloorCanvas: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24)) { context in
            Canvas { ctx, size in
                let t = context.date.timeIntervalSinceReferenceDate
                let floorY = size.height * 0.9

                var bed = Path()
                bed.move(to: CGPoint(x: 0, y: size.height))
                bed.addLine(to: CGPoint(x: 0, y: floorY))
                let humps = 7
                for i in 0...humps {
                    let x = size.width * CGFloat(i) / CGFloat(humps)
                    let y = floorY + sin(CGFloat(i) * 1.4) * 12 - rnd(i, 900) * 16
                    bed.addLine(to: CGPoint(x: x, y: y))
                }
                bed.addLine(to: CGPoint(x: size.width, y: size.height))
                bed.closeSubpath()
                ctx.fill(bed, with: .color(Color(red: 0.02, green: 0.05, blue: 0.09)))
                ctx.stroke(bed, with: .color(Theme.cleanCyan.opacity(0.18)), lineWidth: 1.5)

                let strands = 8
                for i in 0..<strands {
                    let rootX = size.width * (0.05 + 0.9 * CGFloat(i) / CGFloat(strands - 1)) + (rnd(i, 910) - 0.5) * 26
                    let rootY = floorY + 4
                    let height = size.height * (0.22 + rnd(i, 911) * 0.24)
                    let segs = 11
                    var strand = Path()
                    strand.move(to: CGPoint(x: rootX, y: rootY))
                    for s in 1...segs {
                        let f = CGFloat(s) / CGFloat(segs)
                        let sway = sin(t * 0.8 + Double(i) * 0.9 + Double(f) * 3.2) * Double(8 + f * 22)
                        let x = rootX + CGFloat(sway)
                        let y = rootY - height * f
                        strand.addLine(to: CGPoint(x: x, y: y))
                    }
                    let tint = Color(red: 0.05, green: 0.24 + rnd(i, 913) * 0.14, blue: 0.18)
                    ctx.stroke(strand, with: .color(tint.opacity(0.72)),
                               style: StrokeStyle(lineWidth: 5 + rnd(i, 912) * 4, lineCap: .round))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct SortingLineScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "มันถูกเข้ากระบวนการคัดแยก",
            bottlePosition: UnitPoint(x: 0.5, y: 0.8),
            content: { size in
                ZStack {
                    LinearGradient(colors: [Theme.deepNavy, Theme.nearBlack], startPoint: .top, endPoint: .bottom)
                    FactorySilhouetteCanvas().opacity(0.6)
                    ConveyorBeltCanvas()
                    LightRaysCanvas(color: Theme.cleanCyan, count: 3)

                    TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                        let t = context.date.timeIntervalSinceReferenceDate
                        let x = size.width * (0.2 + 0.6 * (0.5 + 0.5 * sin(t * 1.3)))
                        Rectangle()
                            .fill(LinearGradient(colors: [.clear, Theme.cleanCyan.opacity(0.55), .clear], startPoint: .top, endPoint: .bottom))
                            .frame(width: 4, height: size.height)
                            .position(x: x, y: size.height / 2)
                            .blur(radius: 2)
                    }
                }
            },
            onFinish: { game.advanceFromSortingLine() }
        )
    }
}

struct PelletRevealScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "ส่วนชิ้นนี้มันไม่ได้เหมือนเดิม แต่ก็ไม่ได้หายไปไหน",
            showBottle: false,
            content: { size in
                ZStack {
                    LinearGradient(
                        colors: [Theme.nearBlack.mix(with: Theme.freshGreen, amount: 0.18), Theme.nearBlack],
                        startPoint: .top, endPoint: .bottom
                    )
                    LightRaysCanvas(color: Theme.freshGreen, count: 3)
                    SparkleCanvas(count: 36, color: Theme.cleanWhite)

                    let moundCenter = CGPoint(x: size.width * 0.5, y: size.height * 0.6)
                    let targets: [CGPoint] = (0..<50).map { i in
                        let a = Double(rnd(i, 500)) * 2 * .pi
                        let r = rnd(i, 501) * 32
                        return CGPoint(x: moundCenter.x + CGFloat(cos(a)) * r, y: moundCenter.y + CGFloat(sin(a)) * r * 0.5)
                    }
                    FlakeField(
                        count: 50, scatterCenter: moundCenter, scatterRadius: 90,
                        target: targets, mix: 1, color: Theme.freshGreen.opacity(0.9), opacity: 0.9
                    )
                }
            },
            onFinish: { game.advanceFromPelletReveal() }
        )
    }
}

struct TruckDeliveryScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "เส้นทางนี้จะทำให้มันเปลี่ยนไป",
            showBottle: false,
            textPosition: UnitPoint(x: 0.5, y: 0.15),
            content: { size in
                let roadTopY = size.height * 0.86
                return ZStack {
                    LinearGradient(colors: [Theme.deepNavy, Theme.nearBlack], startPoint: .top, endPoint: .bottom)
                    SkylineCanvas().opacity(0.3)
                    NeonStreakField(colors: [Theme.neonCyan, Theme.neonAmber])

                    RoadsideTreesCanvas(roadTopY: roadTopY)

                    Rectangle()
                        .fill(Color(red: 0.06, green: 0.06, blue: 0.08))
                        .frame(height: size.height - roadTopY)
                        .position(x: size.width * 0.5, y: roadTopY + (size.height - roadTopY) / 2)
                    RoadLinesCanvas(roadTopY: roadTopY)
                        .frame(height: size.height)

                    StreetLampRow(roadTopY: roadTopY, direction: 1)
                        .frame(height: size.height)

                    TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                        let t = context.date.timeIntervalSinceReferenceDate
                        let bounce = sin(t * 9) * 1.6
                        RecyclingTruckShape()
                            .position(x: size.width * 0.5, y: roadTopY - 54 + bounce)
                    }
                }
            },
            onFinish: { game.advanceFromTruckDelivery() }
        )
    }
}

private struct RecyclingTruckShape: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: [Theme.cleanCyan, Theme.cleanCyan.opacity(0.55)], startPoint: .top, endPoint: .bottom))
                .frame(width: 108, height: 76)
                .overlay(
                    Image(systemName: "arrow.3.trianglepath")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white.opacity(0.92))
                )
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.25), lineWidth: 1.5))
                .offset(x: -28, y: -6)

            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: [Color(white: 0.8), Color(white: 0.5)], startPoint: .top, endPoint: .bottom))
                .frame(width: 54, height: 52)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.cleanCyan.opacity(0.55))
                        .frame(width: 30, height: 22)
                        .offset(y: -11)
                )
                .offset(x: 52, y: 4)

            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black.opacity(0.55))
                .frame(width: 168, height: 8)
                .offset(y: 33)

            wheel.offset(x: -34, y: 40)
            wheel.offset(x: 44, y: 40)

            Circle().fill(Theme.neonAmber.opacity(0.9)).frame(width: 8, height: 8)
                .glow(Theme.neonAmber, radius: 6, opacity: 0.6)
                .offset(x: 78, y: 10)
        }
    }

    private var wheel: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Color(white: 0.3), .black], center: .center, startRadius: 0, endRadius: 15))
                .frame(width: 28, height: 28)
            Circle().fill(Color(white: 0.6)).frame(width: 9, height: 9)
        }
    }
}

struct RoadLinesCanvas: View {
    var roadTopY: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20)) { context in
            Canvas { ctx, size in
                let dash: CGFloat = 40
                let gap: CGFloat = 34
                let cycle = dash + gap
                let y = roadTopY + 16
                let offset = CGFloat((context.date.timeIntervalSinceReferenceDate * 260).truncatingRemainder(dividingBy: Double(cycle)))
                var x = -offset
                while x < size.width {
                    ctx.fill(Path(roundedRect: CGRect(x: x, y: y, width: dash, height: 5), cornerRadius: 2),
                             with: .color(.white.opacity(0.4)))
                    x += cycle
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct CommunityCleanupScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "มีมือบางคู่ เลือกที่จะหยุดไม่ให้มันต้องมาเริ่มเส้นทางนี้อีก",
            showBottle: false,
            content: { size in CarryBagView(size: size) },
            onFinish: { game.advanceFromCommunityCleanup() }
        )
    }
}

private struct CarryBagView: View {
    let size: CGSize

    @State private var walkT: CGFloat = 0
    @State private var tossT: CGFloat = 0
    @State private var binHit = false
    @State private var start = Date()

    var body: some View {
        let groundY = size.height * 0.82
        let binX = size.width * 0.74
        let binRimY = groundY - 70

        TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
            let t = context.date.timeIntervalSince(start)
            let walking = walkT < 0.999 && tossT < 0.01
            let bob = walking ? CGFloat(sin(t * 9)) * 5 : 0
            let personX = size.width * (0.24 + 0.31 * walkT)
            let holdX = personX + 34
            let holdY = groundY - 41 + bob
            let bagX = holdX + (binX - holdX) * tossT
            let bagY = holdY + (binRimY - holdY) * tossT - CGFloat(46 * sin(.pi * Double(tossT)))
            let bagScale = 1 - 0.5 * tossT
            let bagOpacity = tossT < 0.72 ? 1.0 : max(0, 1 - (Double(tossT) - 0.72) / 0.28)

            ZStack {
                LinearGradient(colors: [Color(red: 0.55, green: 0.8, blue: 0.95), Color(red: 0.78, green: 0.92, blue: 0.72)],
                               startPoint: .top, endPoint: .bottom)
                CloudDriftCanvas()
                TreeLineCanvas()
                SparkleCanvas(count: 14, color: .white).opacity(0.3)

                Rectangle()
                    .fill(LinearGradient(colors: [Color(red: 0.46, green: 0.72, blue: 0.42), Color(red: 0.3, green: 0.54, blue: 0.28)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(height: size.height - groundY + 4)
                    .position(x: size.width / 2, y: groundY + (size.height - groundY) / 2)

                TrashBinView(width: 98, height: 122)
                    .rotationEffect(.degrees(binHit ? -5 : 0), anchor: .bottom)
                    .position(x: binX, y: groundY - 50)

                BigWalker(shirt: Theme.cleanCyan)
                    .position(x: personX, y: groundY - 92 + bob)

                TrashBag()
                    .scaleEffect(bagScale)
                    .opacity(bagOpacity)
                    .position(x: bagX, y: bagY)
            }
        }
        .onAppear(perform: run)
    }

    private func run() {
        start = Date()
        walkT = 0
        tossT = 0
        binHit = false
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.5))
            withAnimation(.easeInOut(duration: 2.4)) { walkT = 1 }
            try? await Task.sleep(for: .seconds(2.55))
            withAnimation(.easeInOut(duration: 0.6)) { tossT = 1 }
            try? await Task.sleep(for: .seconds(0.48))
            game.sound.impactThud()
            Haptics.collision()
            withAnimation(.easeOut(duration: 0.1)) { binHit = true }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.42).delay(0.1)) { binHit = false }
        }
    }

    @EnvironmentObject private var game: GameState
}

private struct BigWalker: View {
    var shirt: Color

    var body: some View {
        Canvas { ctx, _ in
            let pants = Color(red: 0.2, green: 0.16, blue: 0.14)
            let skin = Color(red: 0.55, green: 0.4, blue: 0.3)
            func limb(_ pts: [CGPoint], _ color: Color, _ w: CGFloat) {
                var p = Path()
                p.addLines(pts)
                ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round))
            }
            limb([CGPoint(x: 64, y: 112), CGPoint(x: 54, y: 150), CGPoint(x: 50, y: 186)], pants, 11)
            limb([CGPoint(x: 64, y: 112), CGPoint(x: 76, y: 150), CGPoint(x: 84, y: 184)], pants, 11)
            limb([CGPoint(x: 60, y: 64), CGPoint(x: 76, y: 86), CGPoint(x: 90, y: 106)], Color(red: 0.46, green: 0.33, blue: 0.25), 8)
            limb([CGPoint(x: 64, y: 112), CGPoint(x: 64, y: 58)], shirt, 27)
            ctx.fill(Path(ellipseIn: CGRect(x: 64 - 19, y: 42 - 19, width: 38, height: 38)), with: .color(skin))
            limb([CGPoint(x: 68, y: 64), CGPoint(x: 84, y: 86), CGPoint(x: 96, y: 106)], skin, 8)
        }
        .frame(width: 130, height: 190)
    }
}

private struct TrashBag: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let bag = Color(red: 0.13, green: 0.16, blue: 0.14)
            let bagHi = Color(red: 0.24, green: 0.28, blue: 0.25)
            let neckX = w * 0.5
            var p = Path()
            p.move(to: CGPoint(x: neckX - 6, y: 10))
            p.addQuadCurve(to: CGPoint(x: 5, y: h * 0.5), control: CGPoint(x: -4, y: h * 0.14))
            p.addQuadCurve(to: CGPoint(x: neckX, y: h - 4), control: CGPoint(x: 4, y: h - 2))
            p.addQuadCurve(to: CGPoint(x: w - 5, y: h * 0.5), control: CGPoint(x: w - 4, y: h - 2))
            p.addQuadCurve(to: CGPoint(x: neckX + 6, y: 10), control: CGPoint(x: w + 4, y: h * 0.14))
            p.closeSubpath()
            ctx.fill(p, with: .linearGradient(Gradient(colors: [bagHi, bag]),
                                              startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: h)))
            ctx.fill(Path(ellipseIn: CGRect(x: neckX - 8, y: 0, width: 16, height: 14)), with: .color(bagHi))
            var tie = Path()
            tie.move(to: CGPoint(x: neckX - 7, y: 7))
            tie.addLine(to: CGPoint(x: neckX + 7, y: 7))
            ctx.stroke(tie, with: .color(.black.opacity(0.35)), lineWidth: 2)
        }
        .frame(width: 62, height: 78)
    }
}

struct DeliveryTruckScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "กำลังเดินทางไปที่ไหนสักแห่ง",
            showBottle: false,
            textPosition: UnitPoint(x: 0.5, y: 0.15),
            content: { size in
                let roadTopY = size.height * 0.86
                return ZStack {
                    LinearGradient(colors: [Theme.deepNavy, Theme.nearBlack], startPoint: .top, endPoint: .bottom)
                    SkylineCanvas().opacity(0.3)
                    NeonStreakField(colors: [Theme.neonAmber, Theme.neonPink, Theme.neonCyan])

                    RoadsideTreesCanvas(roadTopY: roadTopY)

                    Rectangle()
                        .fill(Color(red: 0.06, green: 0.06, blue: 0.08))
                        .frame(height: size.height - roadTopY)
                        .position(x: size.width * 0.5, y: roadTopY + (size.height - roadTopY) / 2)
                    RoadLinesCanvas(roadTopY: roadTopY)
                        .frame(height: size.height)

                    StreetLampRow(roadTopY: roadTopY, direction: 1)
                        .frame(height: size.height)

                    TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                        let t = context.date.timeIntervalSinceReferenceDate
                        let bounce = sin(t * 9) * 1.6
                        DeliveryTruckShape()
                            .position(x: size.width * 0.5, y: roadTopY - 54 + bounce)
                    }

                    SparkleCanvas(count: 12, color: .white).opacity(0.25)
                }
            },
            onFinish: { game.advanceFromDeliveryTruck() }
        )
    }
}

private struct DeliveryTruckShape: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: [Color(white: 0.92), Color(white: 0.7)], startPoint: .top, endPoint: .bottom))
                .frame(width: 120, height: 82)
                .overlay(
                    Image(systemName: "waterbottle.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(Theme.bottleBlue.opacity(0.7))
                )
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.3), lineWidth: 1.5))
                .offset(x: -22, y: -8)

            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: [Color(white: 0.65), Color(white: 0.4)], startPoint: .top, endPoint: .bottom))
                .frame(width: 50, height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.neonCyan.opacity(0.4))
                        .frame(width: 28, height: 20)
                        .offset(y: -13)
                )
                .offset(x: 58, y: 2)

            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black.opacity(0.55))
                .frame(width: 178, height: 8)
                .offset(y: 35)

            truckWheel.offset(x: -40, y: 42)
            truckWheel.offset(x: -10, y: 42)
            truckWheel.offset(x: 48, y: 42)

            Circle().fill(Theme.neonAmber.opacity(0.9)).frame(width: 7, height: 7)
                .glow(Theme.neonAmber, radius: 8, opacity: 0.7)
                .offset(x: 82, y: 12)
            Circle().fill(Color.red.opacity(0.7)).frame(width: 5, height: 5)
                .glow(.red, radius: 4, opacity: 0.4)
                .offset(x: -82, y: 12)
        }
    }

    private var truckWheel: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Color(white: 0.3), .black], center: .center, startRadius: 0, endRadius: 15))
                .frame(width: 26, height: 26)
            Circle().fill(Color(white: 0.55)).frame(width: 8, height: 8)
        }
    }
}

struct VendingAndDiscardScene: View {
    @EnvironmentObject var game: GameState

    private enum Stage: Int, Comparable {
        case personEnters = 0
        case buyBottle = 1
        case takeBottle = 2
        case personDrinks = 3
        case bottleEmpty = 4
        case discarded = 5
        case exiting = 6

        static func < (lhs: Stage, rhs: Stage) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    @State private var stage: Stage = .personEnters
    @State private var personX: CGFloat = 0.1
    @State private var personOpacity: Double = 1
    @State private var drinkProgress: Double = 0
    @State private var showText = false
    @State private var impactBurst = false
    @State private var arrowOffset: CGFloat = 0

    @State private var heroInGridVisible = true
    @State private var heroInHatchVisible = false
    @State private var heroInHandVisible = false

    @State private var bottlePos = CGPoint.zero

    @State private var joystickOffset: CGSize = .zero
    @State private var isMoving = false
    @State private var legTimer: Double = 0
    @State private var canBuy = false
    @State private var sequenceStarted = false

    private let groundFrac: CGFloat = 0.82
    private let groundHeight: CGFloat = 160

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let footY = size.height - groundHeight
            let px = personX * size.width
            let machineX = size.width * 0.72

            let shoulderX = px - 29.0
            let shoulderY = footY - 204.0

            ZStack {
                cityBackground

                RoadsideTreesCanvas(roadTopY: footY, count: 1, height: 460, positions: [size.width * 0.40])
                StreetLampRow(roadTopY: footY, count: 1, height: 340, positions: [size.width * 0.16])

                VendingMachineCanvas(
                    heroCol: 2, heroRow: 1,
                    vibrancy: game.vibrancy, dirt: game.grime,
                    heroVisible: heroInGridVisible,
                    hatchVisible: heroInHatchVisible
                )
                .position(x: machineX, y: footY - 150)

                streetGround

                personView(size: size)

                if heroInHandVisible && stage == .personDrinks {
                    let armAngleDeg = 40.0 + drinkProgress * 40.0
                    let armRad = armAngleDeg * .pi / 180.0
                    let handX = shoulderX - 60.0 * sin(armRad)
                    let handY = shoulderY + 60.0 * cos(armRad)

                    let bottleTiltDeg = 30.0 + drinkProgress * 30.0
                    let tiltRad = bottleTiltDeg * .pi / 180.0
                    let cdx = 40.0 * sin(tiltRad)
                    let cdy = -40.0 * cos(tiltRad)

                    BottleView(
                        vibrancy: game.vibrancy, dirt: game.grime,
                        showEyes: false, glow: 0,
                        width: 32, height: 80,
                        tilt: .degrees(bottleTiltDeg)
                    )
                    .position(x: handX + cdx, y: handY + cdy)
                    .transition(.opacity)
                }

                if stage >= .bottleEmpty {
                    BottleView(
                        vibrancy: game.vibrancy, dirt: game.grime,
                        showEyes: stage == .bottleEmpty,
                        glow: stage == .bottleEmpty ? 0.2 : 0,
                        width: 52, height: 130,
                        tilt: stage >= .discarded ? .degrees(78) : .zero
                    )
                    .position(bottlePos)
                }

                if !sequenceStarted {
                    Image(systemName: "triangle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(Theme.neonAmber)
                        .rotationEffect(.degrees(180))
                        .offset(y: arrowOffset)
                        .position(x: machineX, y: footY - 350)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                                arrowOffset = -12
                            }
                        }
                }

                if impactBurst {
                    Circle()
                        .fill(RadialGradient(colors: [.white.opacity(0.5), .clear], center: .center, startRadius: 0, endRadius: 50))
                        .frame(width: 110, height: 35)
                        .position(x: bottlePos.x, y: footY + 10)
                        .transition(.opacity)
                }

                if showText {
                    Text("มันถูกใช้ครั้งเดียว แล้วก็โดนทิ้ง")
                        .font(Theme.line(24))
                        .foregroundStyle(.white.opacity(0.95))
                        .padding(.horizontal, 26)
                        .padding(.vertical, 13)
                        .background(.ultraThinMaterial, in: Capsule())
                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                        .position(x: size.width * 0.5, y: size.height * 0.42)
                }

                Vignette(strength: 0.5)
            }
            .contentShape(Rectangle())
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(0.02))
                    guard !sequenceStarted else { continue }

                    if joystickOffset.width != 0 {
                        isMoving = true
                        legTimer += 0.02
                        let speed: CGFloat = 0.005
                        let direction = joystickOffset.width > 0 ? 1.0 : -1.0

                        personX += direction * speed
                        personX = max(0.05, min(0.65, personX))

                        if personX > 0.52 {
                            withAnimation { canBuy = true }
                        } else {
                            withAnimation { canBuy = false }
                        }
                    } else {
                        isMoving = false
                    }
                }
            }
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        if !sequenceStarted {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 140, height: 140)
                                Circle()
                                    .fill(Color.white.opacity(0.4))
                                    .frame(width: 60, height: 60)
                                    .offset(joystickOffset)
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { value in
                                                let maxDist: CGFloat = 50
                                                let dx = value.translation.width
                                                let dist = min(abs(dx), maxDist)
                                                let sign = dx > 0 ? 1.0 : -1.0
                                                joystickOffset = CGSize(width: sign * dist, height: 0)
                                            }
                                            .onEnded { _ in
                                                withAnimation(.interactiveSpring) {
                                                    joystickOffset = .zero
                                                }
                                            }
                                    )
                            }
                            .padding(.leading, 60)
                            .padding(.bottom, 80)
                            .transition(.opacity)

                            Spacer()

                            if canBuy {
                                Button(action: {
                                    buySequence(size: size)
                                }) {
                                    BuyButtonLabel()
                                }
                                .padding(.trailing, 60)
                                .padding(.bottom, 80)
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                }
            )
        }
    }

    private var cityBackground: some View {
        ZStack {
            LinearGradient(colors: [Theme.deepNavy, Theme.nearBlack], startPoint: .top, endPoint: .bottom)
            NeonStreakField(colors: [Theme.neonPink, Theme.neonCyan, Theme.neonPurple])
            SkylineCanvas()
            SparkleCanvas(count: 20, color: .white).opacity(0.35)
            RainCanvas(intensity: 0.4)
        }
    }

    private var streetGround: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.06, blue: 0.08), Color(red: 0.02, green: 0.02, blue: 0.03)],
                startPoint: .top, endPoint: .bottom
            )
            Rectangle().fill(Color.white.opacity(0.12)).frame(height: 2)
        }
        .frame(height: groundHeight)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }

    private func personView(size: CGSize) -> some View {
        let skin = Color(red: 0.55, green: 0.4, blue: 0.3)
        let shirt = Theme.neonCyan.opacity(0.7)
        let pants = Color(red: 0.2, green: 0.16, blue: 0.14)
        let legAngle = (stage == .personEnters && isMoving) || stage == .exiting
            ? sin(legTimer * 15) * 22 : 0.0

        let frontArmAngle: Double
        let backArmAngle: Double

        if stage == .buyBottle {
            frontArmAngle = -45.0
            backArmAngle = 0.0
        } else if stage == .takeBottle {
            frontArmAngle = 135.0
            backArmAngle = -10.0
        } else if stage == .personDrinks {
            frontArmAngle = 40.0 + drinkProgress * 40.0
            backArmAngle = 10.0
        } else if stage == .bottleEmpty {
            frontArmAngle = -90.0
            backArmAngle = 0.0
        } else if stage == .personEnters || stage == .exiting {
            frontArmAngle = -legAngle * 0.8
            backArmAngle = legAngle * 0.8
        } else {
            frontArmAngle = 0.0
            backArmAngle = 0.0
        }

        return ZStack(alignment: .topLeading) {
            Capsule().fill(skin).frame(width: 14, height: 60)
                .rotationEffect(.degrees(backArmAngle), anchor: .top)
                .position(x: 109, y: 86)

            Ellipse()
                .fill(Color.black.opacity(0.35))
                .frame(width: 90, height: 20)
                .position(x: 80, y: 250)

            Capsule().fill(pants).frame(width: 20, height: 110)
                .rotationEffect(.degrees(legAngle), anchor: .top)
                .position(x: 64, y: 195)
            Capsule().fill(pants).frame(width: 20, height: 110)
                .rotationEffect(.degrees(-legAngle), anchor: .top)
                .position(x: 96, y: 195)

            Circle().fill(skin).frame(width: 50, height: 50)
                .position(x: 80, y: 25)
            RoundedRectangle(cornerRadius: 10).fill(shirt)
                .frame(width: 58, height: 86)
                .position(x: 80, y: 99)

            Capsule().fill(skin).frame(width: 14, height: 60)
                .rotationEffect(.degrees(frontArmAngle), anchor: .top)
                .position(x: 51, y: 86)
        }
        .frame(width: 160, height: 260)
        .position(x: personX * size.width, y: size.height - groundHeight - 130)
        .opacity(personOpacity)
    }

    private func buySequence(size: CGSize) {
        sequenceStarted = true
        canBuy = false
        isMoving = false

        let scale = 1.0
        Task { @MainActor in
            withAnimation(.easeInOut(duration: 0.3)) { stage = .buyBottle }

            try? await Task.sleep(for: .seconds(0.4 * scale))
            game.sound.impactThud()
            Haptics.collision()

            try? await Task.sleep(for: .seconds(0.2 * scale))
            withAnimation(.easeInOut(duration: 0.3)) { heroInGridVisible = false }
            game.sound.splash()
            withAnimation(.easeInOut(duration: 0.2)) { heroInHatchVisible = true }

            try? await Task.sleep(for: .seconds(0.6 * scale))
            withAnimation(.easeInOut(duration: 0.4)) { stage = .takeBottle }

            try? await Task.sleep(for: .seconds(0.5 * scale))
            withAnimation(.easeInOut(duration: 0.2)) {
                heroInHatchVisible = false
                heroInHandVisible = true
            }

            try? await Task.sleep(for: .seconds(0.3 * scale))
            withAnimation(.easeInOut(duration: 0.4)) { stage = .personDrinks }

            try? await Task.sleep(for: .seconds(0.5 * scale))
            withAnimation(.easeInOut(duration: 2.0 * scale)) { drinkProgress = 1 }

            try? await Task.sleep(for: .seconds(1.0 * scale))

            let footY = size.height - groundHeight
            let px = personX * size.width
            withAnimation(.easeInOut(duration: 0.4)) {
                stage = .bottleEmpty
                heroInHandVisible = false
                bottlePos = CGPoint(x: px - 85, y: footY - 248)
            }

            try? await Task.sleep(for: .seconds(0.4 * scale))
            withAnimation(.easeIn(duration: 0.5)) {
                stage = .discarded
                bottlePos = CGPoint(x: bottlePos.x - 20, y: footY + 10)
            }

            try? await Task.sleep(for: .seconds(0.55))
            game.sound.impactThud()
            Haptics.collision()
            withAnimation(.easeOut(duration: 0.2)) { impactBurst = true }
            try? await Task.sleep(for: .seconds(0.2))
            withAnimation(.easeOut(duration: 0.3)) { impactBurst = false }

            try? await Task.sleep(for: .seconds(0.4))
            withAnimation(.easeInOut(duration: 0.3)) { stage = .exiting }
            withAnimation(.easeIn(duration: 1.2)) {
                personX = -0.2
                personOpacity = 0
            }

            try? await Task.sleep(for: .seconds(0.6))
            withAnimation(.easeIn(duration: 0.5)) { showText = true }

            try? await Task.sleep(for: .seconds(2.8))
            game.advanceFromVendingAndDiscard()
        }
    }
}

private struct BuyButtonLabel: View {
    var body: some View {
        Text("กดน้ำ")
            .font(Theme.title(22))
            .foregroundStyle(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 15)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
    }
}

private struct ShelfBottleGlyph: View {
    var body: some View {
        BottleShape()
            .fill(Theme.bottleBlueDeep.opacity(0.55))
            .overlay(BottleShape().stroke(Color.white.opacity(0.07), lineWidth: 1))
    }
}

private struct VendingMachineCanvas: View {
    var heroCol: Int
    var heroRow: Int
    var vibrancy: Double
    var dirt: Double
    var heroVisible: Bool
    var hatchVisible: Bool

    private let cols = 5
    private let rows = 4
    private let machineWidth: CGFloat = 200
    private let machineHeight: CGFloat = 300

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    colors: [Color(red: 0.7, green: 0.15, blue: 0.2), Color(red: 0.4, green: 0.05, blue: 0.1)],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: machineWidth, height: machineHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.12), lineWidth: 2)
                )

            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.04))
                .frame(width: machineWidth - 24, height: machineHeight * 0.60)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Theme.neonCyan.opacity(0.15), lineWidth: 1.2)
                )
                .offset(y: -30)

            bottleGrid
                .offset(y: -30)

            RoundedRectangle(cornerRadius: 2)
                .fill(LinearGradient(colors: [Theme.neonCyan.opacity(0.5), Theme.neonPurple.opacity(0.4)], startPoint: .leading, endPoint: .trailing))
                .frame(width: machineWidth - 32, height: 5)
                .blur(radius: 2)
                .offset(y: -(machineHeight / 2 - 18))

            RoundedRectangle(cornerRadius: 6)
                .fill(Color.black.opacity(0.6))
                .frame(width: 80, height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .overlay(
                    Group {
                        if hatchVisible {
                            BottleView(vibrancy: vibrancy, dirt: dirt, showEyes: false, width: 12, height: 30, tilt: .degrees(90))
                                .opacity(0.8)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                )
                .offset(y: machineHeight / 2 - 32)

            RoundedRectangle(cornerRadius: 1)
                .fill(Color(white: 0.3))
                .frame(width: 14, height: 4)
                .offset(x: machineWidth / 2 - 24, y: -15)

            VStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill([Theme.neonCyan, Theme.neonPink, Theme.neonAmber, Theme.neonPurple][i].opacity(0.5))
                        .frame(width: 7, height: 7)
                }
            }
            .offset(x: machineWidth / 2 - 23, y: 10)
        }
    }

    private var bottleGrid: some View {
        let cellW: CGFloat = (machineWidth - 40) / CGFloat(cols)
        let cellH: CGFloat = (machineHeight * 0.56) / CGFloat(rows)

        return VStack(spacing: 3) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 3) {
                    ForEach(0..<cols, id: \.self) { col in
                        let isHero = col == heroCol && row == heroRow
                        ZStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 1)
                                .offset(y: cellH / 2 - 2)

                            if isHero {
                                if heroVisible {
                                    BottleView(
                                        vibrancy: vibrancy, dirt: dirt,
                                        showEyes: true, glow: 0.45,
                                        width: 18, height: 42
                                    )
                                }
                            } else {
                                ShelfBottleGlyph()
                                    .frame(width: 14, height: 36)
                            }
                        }
                        .frame(width: cellW, height: cellH)
                    }
                }
            }
        }
    }
}
