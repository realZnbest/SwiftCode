import SwiftUI
import UIKit

/// 40-50s (including a possible short detour). The bottle drifts through a
/// darkening canal, then the player swipes it toward the sea (a short,
/// reversible failure beat) or toward a glowing recycling point.
struct CanalScene: View {
    @EnvironmentObject var game: GameState

    private enum Stage { case floating, fork, resolving }

    @State private var stage: Stage = .floating
    @State private var sceneStart = Date()
    @State private var dragX: CGFloat = 0
    @State private var choiceMade = false
    @State private var resolvedToward: Bool? = nil // true = recycling (right), false = sea (left)
    @State private var idleTask: Task<Void, Never>? = nil

    private var reduceMotion: Bool { game.reduceMotion }
    private let introDuration: Double = 12

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            TimelineView(.animation(minimumInterval: reduceMotion ? 0.3 : 1.0 / 30)) { context in
                let elapsed = context.date.timeIntervalSince(sceneStart)
                let darkness = stage == .floating
                    ? min(1, elapsed / introDuration) * 0.7
                    : 0.75

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

                    if stage != .floating {
                        forkView(size: size)
                    }

                    Vignette(strength: 0.5)
                }
                .onChange(of: elapsed) { _, newValue in
                    if stage == .floating && newValue > introDuration {
                        enterFork()
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(stage == .floating
            ? "Canal scene. The water is growing darker."
            : "A fork in the canal. Swipe left toward the sea, or swipe right toward the bright recycling point.")
        .onAppear(perform: setup)
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
            pathIndicator(
                systemImage: "water.waves",
                tint: seaBlocked ? .gray : Theme.murkGreen,
                bright: !seaBlocked && leaning < -0.15
            )
            .opacity(seaBlocked ? 0.25 : 1)
            .position(x: size.width * 0.18, y: size.height * 0.42)

            // Recycling path (right)
            pathIndicator(
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

    private func pathIndicator(systemImage: String, tint: Color, bright: Bool) -> some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [tint.opacity(bright ? 0.55 : 0.2), .clear], center: .center, startRadius: 0, endRadius: 80))
                .frame(width: 150, height: 150)
            Image(systemName: systemImage)
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(tint.opacity(bright ? 1 : 0.55))
        }
        .glow(tint, radius: bright ? 14 : 4, opacity: bright ? 0.6 : 0.15)
        .scaleEffect(bright ? 1.08 : 1)
        .animation(.easeInOut(duration: 0.4), value: bright)
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

    private func enterFork() {
        guard stage == .floating else { return }
        stage = .fork
        armIdleAutoAdvance(delay: 9)
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

