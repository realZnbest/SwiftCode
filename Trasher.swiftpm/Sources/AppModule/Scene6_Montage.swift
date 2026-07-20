import SwiftUI

private struct MontageVignette {
    let colors: [Color]
    let label: String
    let kind: Kind

    enum Kind { case city, river, coast, everywhere }
}

private let montageVignettes: [MontageVignette] = [
    MontageVignette(colors: [Theme.smokeOrange, Theme.neonPink], label: "ในเมือง", kind: .city),
    MontageVignette(colors: [Theme.murkGreen, Theme.cleanCyan], label: "ในน้ำ", kind: .river),
    MontageVignette(colors: [Theme.neonPurple, Theme.deepNavy], label: "มหาสมุทร", kind: .coast),
    MontageVignette(colors: [Theme.cleanCyan, Theme.freshGreen], label: "ทุกๆที่", kind: .everywhere)
]

struct MontageScene: View {
    @EnvironmentObject var game: GameState

    @State private var index = 0
    @State private var advanceTask: Task<Void, Never>?

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
                NeonStreakField(colors: [Theme.neonAmber, Theme.neonPink])
            case .river:
                FishSilhouettesCanvas(darkness: 0.3)
                BubbleCanvas(count: 20, color: Theme.cleanCyan)
            case .coast:
                SparkleCanvas(count: 50, color: .white)
                    .opacity(0.5)
                NeonStreakField(colors: [Theme.neonPurple, Theme.neonCyan])
                    .opacity(0.6)
            case .everywhere:
                SparkleCanvas(count: 70, color: Theme.cleanWhite)
                PathChoiceIndicator(kind: .recyclingPoint, bright: true, containerSize: size, showLabel: false)
                    .position(x: size.width / 2, y: size.height * 0.44)
            }

            Text(vignette.label)
                .font(Theme.line(26))
                .foregroundStyle(.white.opacity(0.9))
                .position(x: size.width / 2, y: size.height * 0.8)
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
                try? await Task.sleep(for: .seconds(perVignette))
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.5)) { index = step }
            }
            try? await Task.sleep(for: .seconds(perVignette))
            guard !Task.isCancelled else { return }
            game.advanceFromMontage()
        }
    }
}
