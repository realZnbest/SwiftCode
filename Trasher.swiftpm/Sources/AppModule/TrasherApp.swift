import SwiftUI

@main
struct TrasherApp: App {

    @StateObject private var game = GameState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(game)
                .preferredColorScheme(.dark)
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
        }
    }
}
