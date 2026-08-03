import SwiftUI

struct SeaFailureScene: View {
    @EnvironmentObject var game: GameState
    @State private var showText = false
    @State private var sceneStart = Date()

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                let elapsed = context.date.timeIntervalSince(sceneStart)
                let clock = context.date.timeIntervalSinceReferenceDate
                let yBob = 14 * sin(elapsed * 1.5) + 6 * sin(elapsed * 0.8 + 0.4)
                let tiltDeg = 10 * sin(elapsed * 0.65 + 0.2) + 4 * sin(elapsed * 1.8 + 1.3)
                let bottleX = size.width * 0.42
                let bottleY = size.height * 0.56
                let sink = min(1, max(0, elapsed / 2.4))
                let descent = sink * sink

                ZStack {
                    UnderwaterBackdrop(
                        surface: Color(red: 0.05, green: 0.14, blue: 0.17),
                        deep: Theme.nearBlack,
                        murk: 0.72,
                        t: clockStep(clock, 12)
                    )

                    CausticBands(color: Theme.cleanCyan,
                                 intensity: 0.45 * (1 - descent * 0.75),
                                 t: clockStep(clock, 15))

                    LightRaysCanvas(color: Theme.cleanCyan, count: 3, t: clockStep(clock, 15))
                        .opacity(0.2 * (1 - descent * 0.8))

                    BubbleCanvas(count: 14, color: .white, t: clockStep(clock, 18))
                        .opacity(0.3)

                    SmokeCanvas(intensity: 0.5, color: Theme.murkGreen, t: clockStep(clock, 12))
                        .opacity(0.5)

                    MicroplasticDrift(elapsed: 4.2, center: CGPoint(x: bottleX, y: bottleY))
                        .opacity(0.5)

                    FishSilhouettesCanvas(darkness: 0.55 + descent * 0.35)

                    BottleView(vibrancy: 0.3 * (1 - descent * 0.7), dirt: game.grime, showEyes: false,
                               width: 30, height: 74)
                        .saturation(0.3 * (1 - descent * 0.85))
                        .rotationEffect(.degrees(tiltDeg))
                        .scaleEffect(1 - descent * 0.24)
                        .opacity(1 - descent * 0.4)
                        .position(x: bottleX - CGFloat(descent) * size.width * 0.03,
                                  y: bottleY + CGFloat(yBob) + CGFloat(descent) * size.height * 0.17)

                    if showText {
                        Text(game.t(Loc.seaFailureLine))
                            .font(Theme.line(24))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 26)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial, in: Capsule())
                            .transition(.opacity)
                            .position(x: size.width * 0.5, y: size.height * 0.22)
                    }

                    Vignette(strength: 0.75 + descent * 0.16)
                }
            }
        }
        .onAppear(perform: runSequence)
    }

    private func runSequence() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.4))
            withAnimation(.easeIn(duration: 0.6)) { showText = true }
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation(.easeOut(duration: 0.4)) { showText = false }
            try? await Task.sleep(for: .seconds(0.4))
            game.returnToForkFromSea()
        }
    }
}
