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
                        Text(game.t(Loc.seaFailureLine))
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
            try? await Task.sleep(for: .seconds(0.4))
            withAnimation(.easeOut(duration: 0.4)) { showText = false }
            try? await Task.sleep(for: .seconds(0.4))
            game.returnToForkFromSea()
        }
    }
}
