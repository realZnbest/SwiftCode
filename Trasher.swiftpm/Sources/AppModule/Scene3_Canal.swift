import SwiftUI
import UIKit

/// 40-50s (including a possible short detour). The bottle drifts through a
/// darkening canal, then the player swipes it toward the sea (a short,
/// reversible failure beat) or toward a glowing recycling point.
struct CanalScene: View {
    @EnvironmentObject var game: GameState

    private enum Stage { case floating, macro, fork, resolving }

    @State private var stage: Stage = .floating
    @State private var sceneStart = Date()
    @State private var dragX: CGFloat = 0
    @State private var choiceMade = false
    @State private var resolvedToward: Bool? = nil // true = recycling (right), false = sea (left)
    @State private var idleTask: Task<Void, Never>? = nil

    private var reduceMotion: Bool { game.reduceMotion }
    private let introDuration: Double = 9
    private let macroDuration: Double = 5.5

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            TimelineView(.animation(minimumInterval: reduceMotion ? 0.3 : 1.0 / 30)) { context in
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

                    FishSilhouettesCanvas(darkness: darkness, reduceMotion: reduceMotion)

                    SmokeCanvas(intensity: darkness, color: Theme.murkGreen, reduceMotion: reduceMotion)

                    if stage == .floating {
                        BottleView(vibrancy: game.vibrancy, dirt: game.grime, showEyes: false, width: 60, height: 148)
                            .position(
                                x: size.width * (0.15 + 0.35 * min(1, elapsed / introDuration)),
                                y: size.height * 0.5 + CGFloat(sin(elapsed * 1.6)) * 18
                            )
                    }

                    if stage == .macro {
                        macroView(size: size, macroElapsed: elapsed - introDuration)
                    }

                    if stage == .fork || stage == .resolving {
                        forkView(size: size)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(stage == .fork || stage == .resolving
            ? "A fork in the canal. Swipe left toward the sea, or swipe right toward the bright recycling point."
            : "Canal scene. The water is growing darker.")
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

            BottleView(
                vibrancy: game.vibrancy, dirt: game.grime, showEyes: envelope > 0.6,
                width: 60, height: 148
            )
            .position(center)
            .scaleEffect(1 + envelope * 2.1)

            if envelope > 0.35 {
                Text("Some of it never comes back.")
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
        let bottleCenterX = size.width / 2 + dragX
        let leaning = dragX / (size.width * 0.3)

        return ZStack {
            // Sea path (left)
            PathChoiceIndicator(
                systemImage: "water.waves",
                tint: seaBlocked ? .gray : Theme.mutedSeaTeal,
                bright: !seaBlocked && leaning < -0.15,
                dim: seaBlocked
            )
            .position(x: size.width * 0.18, y: size.height * 0.42)

            // Recycling path (right)
            PathChoiceIndicator(
                systemImage: "arrow.3.trianglepath",
                tint: Theme.cleanCyan,
                bright: leaning > 0.15 || seaBlocked
            )
            .position(x: size.width * 0.82, y: size.height * 0.42)

            BottleView(vibrancy: game.vibrancy, dirt: game.grime, showEyes: false, width: 62, height: 152)
                .position(x: bottleCenterX, y: size.height * 0.62)
                .rotationEffect(.degrees(Double(leaning) * 14))
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard !choiceMade else { return }
                    dragX = max(-size.width * 0.3, min(size.width * 0.3, value.translation.width))
                }
                .onEnded { value in
                    guard !choiceMade else { return }
                    let threshold = size.width * 0.16
                    if value.translation.width < -threshold && !seaBlocked {
                        resolve(towardRecycling: false)
                    } else if value.translation.width > threshold {
                        resolve(towardRecycling: true)
                    } else {
                        withAnimation(.spring()) { dragX = 0 }
                    }
                }
        )
    }

    private func setup() {
        sceneStart = Date()
        choiceMade = false
        dragX = 0
        resolvedToward = nil
        if game.mustRouteToRecycling {
            stage = .fork
            armIdleAutoAdvance(delay: 6)
        } else {
            stage = .floating
        }
    }

    private func enterMacro() {
        guard stage == .floating else { return }
        stage = .macro
        game.sound.motif()
    }

    private func enterFork() {
        guard stage == .floating || stage == .macro else { return }
        stage = .fork
        armIdleAutoAdvance(delay: 7)
    }

    private func armIdleAutoAdvance(delay: Double) {
        idleTask?.cancel()
        idleTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled, !choiceMade else { return }
            resolve(towardRecycling: true)
        }
    }

    private func resolve(towardRecycling: Bool) {
        guard !choiceMade else { return }
        choiceMade = true
        idleTask?.cancel()
        resolvedToward = towardRecycling
        stage = .resolving

        let travel: CGFloat = towardRecycling ? 900 : -900
        withAnimation(reduceMotion ? .easeInOut(duration: 0.5) : .easeIn(duration: 0.8)) {
            dragX = travel
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.5 : 0.85))
            if towardRecycling {
                game.chooseRecycling()
            } else {
                game.chooseSea()
            }
        }
    }
}

/// Short (~4-5s), reversible failure beat: muted color, hushed sound,
/// one line of text, then straight back to the fork — never a full restart.
struct SeaFailureScene: View {
    @EnvironmentObject var game: GameState
    @State private var showText = false

    private var reduceMotion: Bool { game.reduceMotion }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.nearBlack, Color(red: 0.05, green: 0.08, blue: 0.09)],
                           startPoint: .top, endPoint: .bottom)

            SmokeCanvas(intensity: 0.5, color: Theme.murkGreen, reduceMotion: reduceMotion)
                .opacity(0.5)

            BottleView(vibrancy: 0.35, dirt: game.grime, showEyes: false, width: 54, height: 132)
                .saturation(0.3)
                .opacity(0.7)

            if showText {
                Text("Waste does not disappear.")
                    .font(Theme.line(24))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 26)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: Capsule())
                    .transition(.opacity)
            }

            Vignette(strength: 0.75)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Waste does not disappear. Returning to the fork.")
        .onAppear(perform: runSequence)
    }

    private func runSequence() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.4))
            withAnimation(.easeIn(duration: 0.6)) { showText = true }
            try? await Task.sleep(for: .seconds(reduceMotion ? 2.6 : 3.4))
            withAnimation(.easeOut(duration: 0.4)) { showText = false }
            try? await Task.sleep(for: .seconds(0.4))
            game.returnToForkFromSea()
        }
    }
}

