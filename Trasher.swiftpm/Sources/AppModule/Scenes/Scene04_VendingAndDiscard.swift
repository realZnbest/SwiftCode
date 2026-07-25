import SwiftUI

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

    @State private var zoomScale: CGFloat = 1.0
    @State private var zoomAnchor: UnitPoint = .center

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
                }
                .scaleEffect(zoomScale, anchor: zoomAnchor)

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

            zoomAnchor = UnitPoint(x: bottlePos.x / size.width, y: bottlePos.y / size.height)
            withAnimation(.easeInOut(duration: 1.4)) {
                zoomScale = 1.7
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
