import SwiftUI

struct CommunityCleanupScene: View {
    @EnvironmentObject var game: GameState
    @State private var showText = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                CarryBagView(size: geo.size, onComplete: advance)

                if showText {
                    Text(game.t(Loc.communityCleanupLine))
                        .font(Theme.line(22))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 26)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: Capsule())
                        .transition(.opacity)
                        .position(x: geo.size.width * 0.5, y: geo.size.height * 0.86)
                }

                Vignette(strength: 0.55)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.5).delay(0.5)) { showText = true }
        }
    }

    private func advance() {
        withAnimation(.easeOut(duration: 0.35)) { showText = false }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.3))
            game.advanceFromCommunityCleanup()
        }
    }
}

private struct CarryBagView: View {
    let size: CGSize
    var onComplete: () -> Void

    @State private var start = Date()
    @State private var impactTriggered = false
    @State private var tossTriggered = false
    @State private var tossTriggerElapsed: Double = 0
    @State private var dragOffset: CGSize = .zero
    @State private var promptCueScale: CGFloat = 1
    @State private var swipeGuideProgress: CGFloat = 0
    @State private var completed = false
    @State private var lidOpened = false
    @State private var lidOpenProgress: CGFloat = 0
    @State private var lidPromptCueScale: CGFloat = 1
    @State private var lidSwipeProgress: CGFloat = 0
    @State private var joystickOffset: CGSize = .zero
    @State private var personProgress: CGFloat = 0
    @State private var isMoving = false
    @State private var arrowBounce: CGFloat = 0

    private let walkSpeed: CGFloat = 0.013
    private let tossDuration: Double = 0.6
    private let impactOffsetInToss: Double = 0.48

    private func smoothstep(_ x: Double) -> Double { x * x * (3 - 2 * x) }

    var body: some View {
        let groundY = size.height * 0.82
        let binX = size.width * 0.74
        let binRimY = groundY - 70

        TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
            let t = context.date.timeIntervalSince(start)
            let arrived = personProgress >= 0.999
            let effectiveTossT = tossTriggered
                ? smoothstep(max(0, min(1, (t - tossTriggerElapsed) / tossDuration)))
                : 0
            let bob = isMoving ? CGFloat(sin(t * 9)) * 5 : 0
            let legPhase = t * 9
            let strideAmt: Double = isMoving ? 1 : 0
            let personX = size.width * (0.24 + 0.30 * personProgress)
            let holdX = personX + 34
            let holdY = groundY - 52 + bob
            let awaitingLidOpen = arrived && !lidOpened && !tossTriggered
            let awaitingThrow = arrived && lidOpened && !tossTriggered
            let lidBob = lidOpened ? CGFloat(sin(t * 2.2) * 4) : 0

            let bagX = tossTriggered
                ? holdX + (binX - holdX) * CGFloat(effectiveTossT)
                : holdX + (awaitingThrow ? dragOffset.width : 0)
            let bagY = tossTriggered
                ? holdY + (binRimY - holdY) * CGFloat(effectiveTossT) - CGFloat(46 * sin(.pi * effectiveTossT))
                : holdY + (awaitingThrow ? dragOffset.height : 0)
            let bagScale = tossTriggered ? CGFloat(1 - 0.5 * effectiveTossT) : 1
            let bagOpacity = !tossTriggered || effectiveTossT < 0.72
                ? 1.0
                : max(0, 1 - (effectiveTossT - 0.72) / 0.28)

            let impactT = tossTriggered ? (t - tossTriggerElapsed - impactOffsetInToss) : -1
            let binTilt: Double = (impactT >= 0 && impactT < 0.5)
                ? cos(impactT * 30) * exp(-impactT * 9) * -6
                : 0

            ZStack {
                LinearGradient(colors: [Color(red: 0.55, green: 0.8, blue: 0.95), Color(red: 0.78, green: 0.92, blue: 0.72)],
                               startPoint: .top, endPoint: .bottom)
                CloudDriftCanvas()
                TreeLineCanvas()
                SparkleCanvas(count: 14, color: .white).opacity(0.3)
                BirdFlockCanvas(count: 4)

                ParkGroundCanvas(groundY: groundY)

                BushClusterView(width: 64, flowerColors: [Theme.neonPink, .white, Theme.neonAmber], seed: 1)
                    .position(x: size.width * 0.06, y: groundY + 58)
                BushClusterView(width: 52, flowerColors: [Theme.cleanCyan, .white], seed: 2)
                    .position(x: size.width * 0.35, y: groundY + 60)
                BushClusterView(width: 58, flowerColors: [Theme.neonAmber, Theme.freshGreen], seed: 3)
                    .position(x: size.width * 0.92, y: groundY + 62)

                WalkwayStripView(width: size.width, height: 30)
                    .position(x: size.width * 0.5, y: groundY + 18)

                GroundShadowView(width: 44)
                    .position(x: size.width * 0.13, y: groundY - 2)
                ParkLampPostView(height: 130)
                    .position(x: size.width * 0.13, y: groundY - 65)

                GroundShadowView(width: 84)
                    .position(x: size.width * 0.90, y: groundY - 14)
                BenchView(width: 92, height: 34)
                    .position(x: size.width * 0.90, y: groundY - 30)

                GroundShadowView(width: 90)
                    .position(x: binX, y: groundY + 4)
                TrashBinView(width: 98, height: 122, lidOpen: lidOpenProgress, lidBob: lidBob)
                    .rotationEffect(.degrees(binTilt), anchor: .bottom)
                    .position(x: binX, y: groundY - 50)

                GroundShadowView(width: 60 + CGFloat(strideAmt) * 6)
                    .position(x: personX, y: groundY + 6)
                BigWalker(shirt: Theme.cleanCyan, legPhase: legPhase, stride: strideAmt)
                    .position(x: personX, y: groundY - 92 + bob)

                TrashBag()
                    .scaleEffect(bagScale)
                    .opacity(bagOpacity)
                    .position(x: bagX, y: bagY)

                if !arrived {
                    Image(systemName: "triangle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 22, height: 22)
                        .foregroundColor(Theme.neonAmber)
                        .rotationEffect(.degrees(180))
                        .offset(y: arrowBounce)
                        .position(x: binX, y: groundY - 190)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                                arrowBounce = -12
                            }
                        }

                    WalkJoystickView(offset: $joystickOffset)
                        .position(x: size.width * 0.16, y: size.height * 0.85)
                }

                if awaitingLidOpen {
                    LidOpenGuideOverlay(
                        lidPos: CGPoint(x: binX, y: binRimY),
                        promptCueScale: lidPromptCueScale,
                        swipeProgress: lidSwipeProgress,
                        onDragEnded: { value in
                            if value.translation.height < -30 {
                                openLid()
                            }
                        }
                    )
                }

                if awaitingThrow {
                    ThrowGuideOverlay(
                        bagPos: CGPoint(x: bagX, y: bagY),
                        binPos: CGPoint(x: binX, y: binRimY),
                        promptCueScale: promptCueScale,
                        swipeGuideProgress: swipeGuideProgress,
                        onDragChanged: { dragOffset = $0 },
                        onDragEnded: { value in
                            let toBin = CGSize(width: binX - holdX, height: binRimY - holdY)
                            let toBinMag = (toBin.width * toBin.width + toBin.height * toBin.height).squareRoot()
                            let dragMag = (value.translation.width * value.translation.width
                                + value.translation.height * value.translation.height).squareRoot()
                            let dot = value.translation.width * toBin.width + value.translation.height * toBin.height
                            let aimedAtBin = toBinMag > 0 && dragMag > 24 && dot > 0

                            if aimedAtBin {
                                tossTriggered = true
                                tossTriggerElapsed = t
                                dragOffset = .zero
                            } else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    dragOffset = .zero
                                }
                            }
                        }
                    )
                }
            }
            .onChange(of: awaitingLidOpen) { _, isAwaiting in
                guard isAwaiting else { return }
                lidPromptCueScale = 1
                withAnimation(.easeOut(duration: 0.6).repeatForever(autoreverses: false)) {
                    lidPromptCueScale = 1.6
                }
                lidSwipeProgress = 0
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                    lidSwipeProgress = 1
                }
            }
            .onChange(of: awaitingThrow) { _, isAwaiting in
                guard isAwaiting else { return }
                promptCueScale = 1
                withAnimation(.easeOut(duration: 0.6).repeatForever(autoreverses: false)) {
                    promptCueScale = 1.8
                }
                swipeGuideProgress = 0
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                    swipeGuideProgress = 0.3
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(8))
                    guard !tossTriggered else { return }
                    tossTriggered = true
                    tossTriggerElapsed = Date().timeIntervalSince(start)
                }
            }
            .onChange(of: impactT >= 0) { _, crossed in
                guard crossed, !impactTriggered else { return }
                impactTriggered = true
                game.sound.impactThud()
                guard !completed else { return }
                completed = true
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.9))
                    onComplete()
                }
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(0.02))
                guard personProgress < 1 else { isMoving = false; continue }
                if joystickOffset.width != 0 {
                    isMoving = true
                    let direction: CGFloat = joystickOffset.width > 0 ? 1 : -1
                    personProgress = max(0, min(1, personProgress + direction * walkSpeed))
                } else {
                    isMoving = false
                }
            }
        }
        .onAppear(perform: run)
    }

    private func run() {
        start = Date()
        impactTriggered = false
        tossTriggered = false
        dragOffset = .zero
        swipeGuideProgress = 0
        completed = false
        lidOpened = false
        lidOpenProgress = 0
        lidPromptCueScale = 1
        lidSwipeProgress = 0
        joystickOffset = .zero
        personProgress = 0
        isMoving = false
        arrowBounce = 0
    }

    private func openLid() {
        guard !lidOpened else { return }
        lidOpened = true
        game.sound.chomp()
        withAnimation(.easeOut(duration: 0.35)) { lidOpenProgress = 1 }
    }

    @EnvironmentObject private var game: GameState
}

private struct WalkJoystickView: View {
    @Binding var offset: CGSize

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.35))
                .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 2.5))
                .frame(width: 128, height: 128)
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 60, height: 60)
                .offset(offset)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let maxDist: CGFloat = 46
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
    }
}

private struct LidOpenGuideOverlay: View {
    var lidPos: CGPoint
    var promptCueScale: CGFloat
    var swipeProgress: CGFloat
    var onDragEnded: (DragGesture.Value) -> Void

    private var handPos: CGPoint {
        CGPoint(x: lidPos.x, y: lidPos.y - 30 * swipeProgress)
    }

    var body: some View {
        ZStack {
            pulseRing
            ghostHand
        }
        .allowsHitTesting(false)
        .overlay(dragHitArea)
    }

    private var pulseRing: some View {
        Circle()
            .stroke(Theme.freshGreen, lineWidth: 2.5)
            .frame(width: 56, height: 56)
            .scaleEffect(promptCueScale)
            .opacity(Double(2 - promptCueScale))
            .position(lidPos)
    }

    private var ghostHand: some View {
        Image(systemName: "hand.draw.fill")
            .font(.system(size: 24, weight: .regular))
            .foregroundStyle(.white.opacity(0.95))
            .glow(Theme.freshGreen, radius: 6, opacity: 0.6)
            .position(handPos)
    }

    private var dragHitArea: some View {
        Circle()
            .fill(Color.white.opacity(0.001))
            .frame(width: 100, height: 100)
            .position(lidPos)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded(onDragEnded)
            )
    }
}

private struct ThrowGuideOverlay: View {
    var bagPos: CGPoint
    var binPos: CGPoint
    var promptCueScale: CGFloat
    var swipeGuideProgress: CGFloat
    var onDragChanged: (CGSize) -> Void
    var onDragEnded: (DragGesture.Value) -> Void

    private var handPos: CGPoint {
        CGPoint(
            x: bagPos.x + (binPos.x - bagPos.x) * swipeGuideProgress,
            y: bagPos.y + (binPos.y - bagPos.y) * swipeGuideProgress
        )
    }

    var body: some View {
        ZStack {
            guidePath
            pulseRing
            ghostHand
        }
        .allowsHitTesting(false)
        .overlay(dragHitArea)
    }

    private var guidePath: some View {
        Path { path in
            path.move(to: bagPos)
            path.addQuadCurve(
                to: binPos,
                control: CGPoint(x: (bagPos.x + binPos.x) / 2, y: min(bagPos.y, binPos.y) - 34)
            )
        }
        .stroke(Theme.freshGreen.opacity(0.4), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [1, 9]))
    }

    private var pulseRing: some View {
        Circle()
            .stroke(Theme.freshGreen, lineWidth: 2.5)
            .frame(width: 70, height: 70)
            .scaleEffect(promptCueScale)
            .opacity(Double(2 - promptCueScale))
            .position(bagPos)
    }

    private var ghostHand: some View {
        Image(systemName: "hand.draw.fill")
            .font(.system(size: 26, weight: .regular))
            .foregroundStyle(.white.opacity(0.95))
            .glow(Theme.freshGreen, radius: 6, opacity: 0.6)
            .position(handPos)
    }

    private var dragHitArea: some View {
        Circle()
            .fill(Color.white.opacity(0.001))
            .frame(width: 110, height: 110)
            .position(bagPos)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { onDragChanged($0.translation) }
                    .onEnded(onDragEnded)
            )
    }
}

private struct BigWalker: View {
    var shirt: Color
    var legPhase: Double = 0
    var stride: Double = 0

    private func gait(_ phase: Double) -> Double {
        let s = sin(phase)
        return (s < 0 ? -1.0 : 1.0) * pow(abs(s), 0.72)
    }

    private func legSway(_ phase: Double) -> (knee: CGSize, foot: CGSize) {
        let swing = CGFloat(gait(phase) * stride)
        let lift = CGFloat(max(0, cos(phase)) * stride)
        return (
            CGSize(width: swing * 7, height: -lift * 5),
            CGSize(width: swing * 15, height: -lift * 9)
        )
    }

    private func armSway(_ phase: Double) -> (elbow: CGSize, hand: CGSize) {
        let swing = CGFloat(gait(phase) * stride)
        return (
            CGSize(width: swing * 5, height: swing * 2),
            CGSize(width: swing * 10, height: swing * 3)
        )
    }

    var body: some View {
        Canvas { ctx, _ in
            let pants = Color(red: 0.2, green: 0.16, blue: 0.14)
            let skin = Color(red: 0.55, green: 0.4, blue: 0.3)
            func limb(_ pts: [CGPoint], _ color: Color, _ w: CGFloat) {
                var p = Path()
                p.addLines(pts)
                ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round))
            }

            let hip = CGPoint(x: 64, y: 112)
            let backSway = legSway(legPhase + .pi)
            let frontSway = legSway(legPhase)
            let backKnee = CGPoint(x: 61 + backSway.knee.width, y: 150 + backSway.knee.height)
            let backFoot = CGPoint(x: 59 + backSway.foot.width, y: 186 + backSway.foot.height)
            let frontKnee = CGPoint(x: 67 + frontSway.knee.width, y: 150 + frontSway.knee.height)
            let frontFoot = CGPoint(x: 69 + frontSway.foot.width, y: 184 + frontSway.foot.height)

            let backArmSway = armSway(legPhase)
            let frontArmSway = armSway(legPhase + .pi)
            let backShoulder = CGPoint(x: 60, y: 64)
            let backElbow = CGPoint(x: 76 + backArmSway.elbow.width, y: 86 + backArmSway.elbow.height)
            let backHand = CGPoint(x: 90 + backArmSway.hand.width, y: 106 + backArmSway.hand.height)
            let frontShoulder = CGPoint(x: 68, y: 64)
            let frontElbow = CGPoint(x: 84 + frontArmSway.elbow.width, y: 86 + frontArmSway.elbow.height)
            let frontHand = CGPoint(x: 96 + frontArmSway.hand.width, y: 106 + frontArmSway.hand.height)

            limb([hip, backKnee, backFoot], pants, 11)
            limb([hip, frontKnee, frontFoot], pants, 11)
            limb([backShoulder, backElbow, backHand], Color(red: 0.46, green: 0.33, blue: 0.25), 8)
            limb([CGPoint(x: 64, y: 112), CGPoint(x: 64, y: 58)], shirt, 27)
            ctx.fill(Path(ellipseIn: CGRect(x: 64 - 19, y: 42 - 19, width: 38, height: 38)), with: .color(skin))
            limb([frontShoulder, frontElbow, frontHand], skin, 8)
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
