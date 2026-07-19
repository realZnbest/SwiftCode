import SwiftUI

struct RootView: View {
    @EnvironmentObject var game: GameState
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var cutPulse: Double = 0

    var body: some View {
        ZStack {
            Theme.nearBlack.ignoresSafeArea()

            Group {
                switch game.phase {
                case .title:
                    TitleScene()
                case .factoryOrigin:
                    FactoryOriginScene()
                case .opening:
                    OpeningScene()
                case .streetToDrain:
                    StreetToDrainScene()
                case .stormDrainTunnel:
                    StormDrainTunnelScene()
                case .landfillFailure:
                    LandfillFailureScene()
                case .secondBottleMirror:
                    SecondBottleMirrorScene()
                case .canal:
                    CanalScene()
                case .seaFailure:
                    SeaFailureScene()
                case .nightIntoDay:
                    NightIntoDayScene()
                case .fishingNetRescue:
                    FishingNetRescueScene()
                case .sortingLine:
                    SortingLineScene()
                case .recycling:
                    RecyclingScene()
                case .pelletReveal:
                    PelletRevealScene()
                case .truckDelivery:
                    TruckDeliveryScene()
                case .montage:
                    MontageScene()
                case .communityCleanup:
                    CommunityCleanupScene()
                case .ending:
                    EndingScene()
                }
            }
            .id(game.phase)
            .transition(sceneTransition)

            // A brief, soft darkening "breath" between scenes — timed to
            // land under the crossfade — reads as a deliberate cut between
            // shots rather than one view simply dissolving into the next.
            // Skipped under reduced motion since it's a pulse, not content.
            Color.black
                .opacity(cutPulse)
                .allowsHitTesting(false)
                .ignoresSafeArea()
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
        .onChange(of: game.phase) { _, _ in
            guard !game.reduceMotion else { return }
            withAnimation(.easeIn(duration: 0.16)) { cutPulse = 0.32 }
            withAnimation(.easeOut(duration: 0.5).delay(0.16)) { cutPulse = 0 }
        }
    }

    /// Incoming scenes settle in from a slight zoom rather than simply
    /// fading up, and outgoing scenes ease back rather than just
    /// vanishing — a soft push-through instead of a flat crossfade.
    private var sceneTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 1.045)),
            removal: .opacity.combined(with: .scale(scale: 0.965))
        )
    }
}
