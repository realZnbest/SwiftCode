import SwiftUI

/// Switches on the current story phase. Each scene is fully remounted on
/// phase change (`.id`) so its local @State always starts clean, and the
/// crossfade transition doubles as the reduced-motion-friendly scene change.
struct RootView: View {
    @EnvironmentObject var game: GameState
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    var body: some View {
        ZStack {
            Theme.nearBlack.ignoresSafeArea()

            Group {
                switch game.phase {
                case .opening:
                    OpeningScene()
                case .streetToDrain:
                    StreetToDrainScene()
                case .canal:
                    CanalScene()
                case .seaFailure:
                    SeaFailureScene()
                case .recycling:
                    RecyclingScene()
                case .ending:
                    EndingScene()
                }
            }
            .id(game.phase)
            .transition(.opacity)
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .onAppear {
            game.reduceMotion = systemReduceMotion
            game.begin()
        }
        .onChange(of: systemReduceMotion) { _, newValue in
            game.reduceMotion = newValue
        }
    }
}
