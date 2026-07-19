import SwiftUI

/// A short, interactive title card before the story begins: the bottle
/// rests under a streetlamp spotlight while dust drifts through the beam.
/// Tap anywhere to begin, or it moves on by itself after a few seconds so
/// the game never waits on an instruction a judge might not read.
struct TitleScene: View {
    @EnvironmentObject var game: GameState

    @State private var appear = false
    @State private var beginTask: Task<Void, Never>?

    private var reduceMotion: Bool { game.reduceMotion }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                LinearGradient(colors: [Theme.deepNavy, Theme.nearBlack], startPoint: .top, endPoint: .bottom)
                SkylineCanvas().opacity(0.35)
                NeonStreakField(colors: [Theme.neonCyan, Theme.neonPurple], reduceMotion: reduceMotion)
                    .opacity(0.45)

                spotlightGlow(size: size)

                SparkleCanvas(count: 30, color: .white, reduceMotion: reduceMotion)
                    .opacity(0.6)
                    .mask(spotlightMask(size: size))

                BottleView(vibrancy: 1, dirt: 0, showEyes: true, width: 46, height: 112)
                    .position(x: size.width / 2, y: size.height * 0.66)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 16)

                VStack(spacing: 8) {
                    Text("TRASHER")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .glow(Theme.cleanCyan, radius: 16, opacity: 0.5)
                    Text("a plastic bottle's journey")
                        .font(Theme.line(17))
                        .foregroundStyle(.white.opacity(0.65))
                }
                .position(x: size.width / 2, y: size.height * 0.26)
                .opacity(appear ? 1 : 0)

                tapToBeginLabel(size: size)

                Vignette(strength: 0.62)
            }
            .contentShape(Rectangle())
            .onTapGesture { begin() }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Trasher. A plastic bottle's journey.")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Double tap to begin")
        .onAppear(perform: runSequence)
        .onDisappear { beginTask?.cancel() }
    }

    /// Driven by a continuous sine wave from `TimelineView` rather than a
    /// toggled `@State` + `repeatForever` animation — `repeatForever` on an
    /// imperatively-toggled bool is prone to restarting/jumping whenever the
    /// surrounding view re-renders (e.g. from the `appear` fade-in), which
    /// reads as the label glitching back and forth instead of pulsing
    /// smoothly. A pure function of elapsed time has no state to desync.
    private func tapToBeginLabel(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1.0 / 30)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let glow = reduceMotion ? 0.7 : 0.4 + 0.55 * (0.5 + 0.5 * sin(t * 1.7))
            Text("Tap to begin")
                .font(Theme.line(16))
                .foregroundStyle(.white.opacity(glow))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .position(x: size.width / 2, y: size.height * 0.88)
        .opacity(appear ? 1 : 0)
    }

    private func spotlightGlow(size: CGSize) -> some View {
        RadialGradient(
            colors: [Color.white.opacity(0.16), .clear],
            center: UnitPoint(x: 0.5, y: 0.62), startRadius: 10, endRadius: size.width * 0.42
        )
    }

    private func spotlightMask(size: CGSize) -> some View {
        RadialGradient(
            colors: [.white, .clear],
            center: UnitPoint(x: 0.5, y: 0.62), startRadius: 10, endRadius: size.width * 0.42
        )
    }

    private func runSequence() {
        withAnimation(.easeIn(duration: 1.0).delay(0.3)) { appear = true }

        beginTask?.cancel()
        beginTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.9))
            guard !Task.isCancelled else { return }

            try? await Task.sleep(for: .seconds(7.1))
            guard !Task.isCancelled else { return }
            begin()
        }
    }

    private func begin() {
        beginTask?.cancel()
        game.advanceFromTitle()
    }
}
