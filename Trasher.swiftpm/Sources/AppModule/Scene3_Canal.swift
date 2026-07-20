import SwiftUI
import UIKit

struct CanalScene: View {
    @EnvironmentObject var game: GameState

    private enum Stage { case floating, macro, fork, resolving }

    @State private var stage: Stage = .floating
    @State private var sceneStart = Date()
    @State private var choiceMade = false
    @State private var resolvedToward: Bool? = nil

    @State private var forkBottlePos = CGPoint(x: 0.5, y: 0.22)
    @State private var forkDragBase = CGPoint(x: 0.5, y: 0.22)
    @State private var forkWrongFeedback = false
    private let seaForkRect = CGRect(x: 0.08, y: 0.55, width: 0.30, height: 0.3)
    private let recyclingForkRect = CGRect(x: 0.62, y: 0.55, width: 0.30, height: 0.3)

    private let introDuration: Double = 9
    private let macroDuration: Double = 5.5

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                let elapsed = context.date.timeIntervalSince(sceneStart)
                let darkness: Double = {
                    switch stage {
                    case .floating: return min(1, elapsed / introDuration) * 0.7
                    case .macro: return 0.85
                    case .fork, .resolving: return 0.75
                    }
                }()

                ZStack {
                    waterBackground(darkness: darkness)

                    LightRaysCanvas(color: Theme.cleanCyan, count: 4)
                        .opacity(1 - darkness * 0.75)

                    BubbleCanvas(count: 14, color: Theme.murkBrown)
                        .opacity(0.4 + darkness * 0.4)

                    FishSilhouettesCanvas(darkness: darkness)

                    SmokeCanvas(intensity: darkness, color: Theme.murkGreen)

                    if stage == .floating {
                        let xDrift = 0.15 + 0.35 * min(1, elapsed / introDuration)
                            + 0.012 * sin(elapsed * 0.55) + 0.006 * sin(elapsed * 1.3 + 1.1)
                        let yBob = 18 * sin(elapsed * 1.6) + 7 * sin(elapsed * 0.85 + 0.6)
                        let tiltDeg = 9 * sin(elapsed * 0.7 + 0.3) + 4 * sin(elapsed * 1.9 + 2.0)

                        BottleView(
                            vibrancy: game.vibrancy, dirt: game.grime, showEyes: false,
                            width: 60, height: 148, tilt: .degrees(tiltDeg)
                        )
                        .position(x: size.width * xDrift, y: size.height * 0.5 + CGFloat(yBob))
                        .transition(.opacity)
                    }

                    if stage == .macro {
                        macroView(size: size, macroElapsed: elapsed - introDuration)
                            .transition(.opacity)
                    }

                    if stage == .fork || stage == .resolving {
                        forkView(size: size)
                            .transition(.opacity.combined(with: .scale(scale: 0.94)))
                    }

                    Vignette(strength: stage == .macro ? 0.35 : 0.5)
                }
                .onChange(of: elapsed) { _, newValue in
                    if stage == .floating && newValue > introDuration {
                        enterMacro()
                    } else if stage == .macro && newValue > introDuration + macroDuration {
                        enterFork()
                    }
                }
            }
        }
        .onAppear(perform: setup)
    }

    private func macroView(size: CGSize, macroElapsed: Double) -> some View {
        let zoomIn = min(1, macroElapsed / 1.2)
        let zoomOut = min(1, max(0, (macroDuration - macroElapsed) / 1.2))
        let envelope = min(zoomIn, zoomOut)
        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)

        return ZStack {
            FlakeField(
                count: 16, scatterCenter: center, scatterRadius: 90,
                target: Array(repeating: center, count: 16),
                mix: 1 - envelope, color: Theme.cleanWhite.opacity(0.85), opacity: envelope * 0.8
            )

            MicroplasticDrift(elapsed: macroElapsed, center: center)
                .opacity(envelope > 0.35 ? envelope : 0)

            BottleView(
                vibrancy: game.vibrancy, dirt: game.grime, showEyes: envelope > 0.6,
                width: 60, height: 148
            )
            .position(center)
            .scaleEffect(1 + envelope * 2.1)

            if envelope > 0.35 {
                Text("บางส่วนของมันหลุดออกไปและไม่เคยกลับมา")
                    .font(Theme.line(21))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: Capsule())
                    .opacity(min(1, (envelope - 0.35) / 0.3))
                    .position(x: size.width * 0.5, y: size.height * 0.84)
            }
        }
    }

    private func waterBackground(darkness: Double) -> some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.18, blue: 0.24).mix(with: Theme.murkGreen, amount: darkness),
                Color(red: 0.02, green: 0.05, blue: 0.08).mix(with: Theme.murkBrown, amount: darkness)
            ],
            startPoint: .top, endPoint: .bottom
        )
    }

    private func forkView(size: CGSize) -> some View {
        let seaBlocked = game.mustRouteToRecycling
        let hoveringSea = !choiceMade && !seaBlocked && seaForkRect.contains(forkBottlePos)
        let hoveringRecycling = !choiceMade && recyclingForkRect.contains(forkBottlePos)

        return ZStack {
            PathChoiceIndicator(
                kind: .sea,
                bright: hoveringSea,
                dim: seaBlocked,
                containerSize: size
            )
            .position(x: seaForkRect.midX * size.width, y: seaForkRect.midY * size.height)

            PathChoiceIndicator(
                kind: .recyclingPoint,
                bright: hoveringRecycling,
                containerSize: size
            )
            .position(x: recyclingForkRect.midX * size.width, y: recyclingForkRect.midY * size.height)

            if forkWrongFeedback {
                Label("ขวดน้ำมันลอยไปแล้ว มาลองรีไซเคิลกันเถอะ", systemImage: "exclamationmark.triangle.fill")
                    .font(Theme.line(16))
                    .foregroundStyle(Theme.neonAmber)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Theme.nearBlack.opacity(0.78), in: Capsule())
                    .position(x: size.width * 0.5, y: size.height * 0.36)
                    .transition(.opacity)
            }

            BottleView(vibrancy: game.vibrancy, dirt: game.grime, showEyes: false, width: 62, height: 152)
                .position(x: forkBottlePos.x * size.width, y: forkBottlePos.y * size.height)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard !choiceMade else { return }
                    forkBottlePos = CGPoint(
                        x: min(0.95, max(0.05, forkDragBase.x + value.translation.width / size.width)),
                        y: min(0.95, max(0.05, forkDragBase.y + value.translation.height / size.height))
                    )
                }
                .onEnded { _ in
                    guard !choiceMade else { return }
                    evaluateForkDrop(seaBlocked: seaBlocked)
                }
        )
    }

    private func evaluateForkDrop(seaBlocked: Bool) {
        forkDragBase = forkBottlePos
        if recyclingForkRect.contains(forkBottlePos) {
            resolve(towardRecycling: true)
        } else if seaForkRect.contains(forkBottlePos) {
            if seaBlocked {
                withAnimation(.easeOut(duration: 0.35)) {
                    forkBottlePos = CGPoint(x: 0.5, y: 0.22)
                    forkWrongFeedback = true
                }
                forkDragBase = forkBottlePos
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1.6))
                    guard stage == .fork else { return }
                    withAnimation(.easeOut(duration: 0.25)) { forkWrongFeedback = false }
                }
            } else {
                resolve(towardRecycling: false)
            }
        }
    }

    private func setup() {
        sceneStart = Date()
        choiceMade = false
        forkBottlePos = CGPoint(x: 0.5, y: 0.22)
        forkDragBase = forkBottlePos
        forkWrongFeedback = false
        resolvedToward = nil
        if game.mustRouteToRecycling {
            stage = .fork
        } else {
            stage = .floating
        }
    }

    private func enterMacro() {
        guard stage == .floating else { return }
        withAnimation(.easeInOut(duration: 0.6)) {
            stage = .macro
        }
    }

    private func enterFork() {
        guard stage == .floating || stage == .macro else { return }
        withAnimation(.easeInOut(duration: 0.6)) {
            stage = .fork
        }
    }

    private func resolve(towardRecycling: Bool) {
        guard !choiceMade else { return }
        choiceMade = true
        resolvedToward = towardRecycling
        stage = .resolving

        let target = towardRecycling ? recyclingForkRect : seaForkRect
        withAnimation(.easeInOut(duration: 0.6)) {
            forkBottlePos = CGPoint(x: target.midX, y: target.midY)
        }
        game.sound.impactThud()
        Haptics.collision()

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.85))
            if towardRecycling {
                game.chooseRecycling()
            } else {
                game.chooseSea()
            }
        }
    }
}

struct SeaFailureScene: View {
    @EnvironmentObject var game: GameState
    @State private var showText = false
    @State private var sceneStart = Date()

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                let elapsed = context.date.timeIntervalSince(sceneStart)
                let yBob = 14 * sin(elapsed * 1.5) + 6 * sin(elapsed * 0.8 + 0.4)
                let tiltDeg = 10 * sin(elapsed * 0.65 + 0.2) + 4 * sin(elapsed * 1.8 + 1.3)
                let bottleX = size.width * 0.42
                let bottleY = size.height * 0.56

                ZStack {
                    LinearGradient(colors: [Theme.nearBlack, Color(red: 0.05, green: 0.08, blue: 0.09)],
                                   startPoint: .top, endPoint: .bottom)

                    LightRaysCanvas(color: Theme.cleanCyan, count: 3)
                        .opacity(0.2)

                    BubbleCanvas(count: 14, color: .white)
                        .opacity(0.3)

                    SmokeCanvas(intensity: 0.5, color: Theme.murkGreen)
                        .opacity(0.5)

                    MicroplasticDrift(elapsed: 4.2, center: CGPoint(x: bottleX, y: bottleY))
                        .opacity(0.5)

                    FishSilhouettesCanvas(darkness: 0.55)

                    BottleView(vibrancy: 0.3, dirt: game.grime, showEyes: false, width: 30, height: 74)
                        .saturation(0.3)
                        .rotationEffect(.degrees(tiltDeg))
                        .position(x: bottleX, y: bottleY + CGFloat(yBob))

                    if showText {
                        Text("มันไม่ได้หายไปไหน")
                            .font(Theme.line(24))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 26)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial, in: Capsule())
                            .transition(.opacity)
                            .position(x: size.width * 0.5, y: size.height * 0.22)
                    }

                    Vignette(strength: 0.75)
                }
            }
        }
        .onAppear(perform: runSequence)
    }

    private func runSequence() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.4))
            withAnimation(.easeIn(duration: 0.6)) { showText = true }
            try? await Task.sleep(for: .seconds(3.4))
            withAnimation(.easeOut(duration: 0.4)) { showText = false }
            try? await Task.sleep(for: .seconds(0.4))
            game.returnToForkFromSea()
        }
    }
}
