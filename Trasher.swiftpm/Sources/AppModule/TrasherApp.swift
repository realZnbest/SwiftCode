import SwiftUI

@main
struct TrasherApp: App {

    @StateObject private var game = GameState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(game)
                .preferredColorScheme(.dark)
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                game.sound.resume()
                game.sound.transition(to: game.phase)
            case .inactive, .background:
                game.sound.suspend()
            @unknown default:
                game.sound.suspend()
            }
        }
    }
}
