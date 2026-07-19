import SwiftUI

private struct MontageVignette {
    let colors: [Color]
    let label: String
    let kind: Kind

    enum Kind { case city, river, coast, everywhere }
}

private let montageVignettes: [MontageVignette] = [
    MontageVignette(colors: [Theme.smokeOrange, Theme.neonPink], label: "A city.", kind: .city),
    MontageVignette(colors: [Theme.murkGreen, Theme.cleanCyan], label: "A river.", kind: .river),
    MontageVignette(colors: [Theme.neonPurple, Theme.deepNavy], label: "A coast.", kind: .coast),
    MontageVignette(colors: [Theme.cleanCyan, Theme.freshGreen], label: "Everywhere.", kind: .everywhere)
]

/// A quick, wordless-almost montage widening the story's scope right
/// before the park: the same small choice, playing out in other places.
/// Purely auto-paced — there is nothing to do here but watch it land.
struct MontageScene: View {
    @EnvironmentObject var game: GameState

    @State private var index = 0
    @State private var advanceTask: Task<Void, Never>?

    private var reduceMotion: Bool { game.reduceMotion }
    private let perVignette: Double = 1.7

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                ForEach(Array(montageVignettes.enumerated()), id: \.offset) { i, vignette in
                    if i == index {
                        vignetteView(vignette, size: size)
                            .transition(.opacity)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("A quick montage: the same choice, playing out in other cities, rivers, and coastlines.")
        .onAppear(perform: runSequence)
        .onDisappear { advanceTask?.cancel() }
    }

    @ViewBuilder
    private func vignetteView(_ vignette: MontageVignette, size: CGSize) -> some View {
        ZStack {
            LinearGradient(colors: [vignette.colors[0].opacity(0.35), Theme.nearBlack],
                           startPoint: .top, endPoint: .bottom)

            switch vignette.kind {
            case .city:
                SkylineCanvas().opacity(0.7)
                NeonStreakField(colors: [Theme.neonAmber, Theme.neonPink], reduceMotion: reduceMotion)
            case .river:
                FishSilhouettesCanvas(darkness: 0.3, reduceMotion: reduceMotion)
                BubbleCanvas(count: 20, color: Theme.cleanCyan, reduceMotion: reduceMotion)
            case .coast:
                SparkleCanvas(count: 50, color: .white, reduceMotion: reduceMotion)
                    .opacity(0.5)
                NeonStreakField(colors: [Theme.neonPurple, Theme.neonCyan], reduceMotion: reduceMotion)
                    .opacity(0.6)
            case .everywhere:
                SparkleCanvas(count: 70, color: Theme.cleanWhite, reduceMotion: reduceMotion)
                PathChoiceIndicator(kind: .recyclingPoint, bright: true, containerSize: size, showLabel: false)
                    .position(x: size.width / 2, y: size.height * 0.44)
            }

            Text(vignette.label)
                .font(Theme.line(26))
                .foregroundStyle(.white.opacity(0.9))
                .position(x: size.width / 2, y: size.height * 0.8)
                // Old label fully clears before the new one fades in, so
                // the crossfade never overlaps two words on top of each other.
                .transition(.asymmetric(
                    insertion: .opacity.animation(.easeIn(duration: 0.35).delay(0.25)),
                    removal: .opacity.animation(.easeOut(duration: 0.2))
                ))

            Vignette(strength: 0.45)
        }
    }

    private func runSequence() {
        index = 0
        advanceTask?.cancel()
        advanceTask = Task { @MainActor in
            for step in 1..<montageVignettes.count {
                try? await Task.sleep(for: .seconds(reduceMotion ? perVignette * 1.3 : perVignette))
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.5)) { index = step }
            }
            try? await Task.sleep(for: .seconds(reduceMotion ? perVignette * 1.3 : perVignette))
            guard !Task.isCancelled else { return }
            game.advanceFromMontage()
        }
    }
}
