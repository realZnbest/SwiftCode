import SwiftUI

struct RootView: View {
    @EnvironmentObject var game: GameState
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion

    var body: some View {
        ZStack {
            Theme.nearBlack.ignoresSafeArea()

            Group {
                switch game.phase {
                case .title:
                    TitleScene()
                case .opening:
                    OpeningScene()
                case .streetToDrain:
                    StreetToDrainScene()
                case .landfillFailure:
                    LandfillFailureScene()
                case .canal:
                    CanalScene()
                case .seaFailure:
                    SeaFailureScene()
                case .recycling:
                    RecyclingScene()
                case .montage:
                    MontageScene()
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
