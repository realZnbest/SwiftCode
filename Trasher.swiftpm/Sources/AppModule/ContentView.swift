import SwiftUI

struct RootView: View {
    @EnvironmentObject var game: GameState
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
                case .deliveryTruck:
                    DeliveryTruckScene()
                case .vendingAndDiscard:
                    VendingAndDiscardScene()
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

            Color.black
                .opacity(cutPulse)
                .allowsHitTesting(false)
                .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .onAppear {
            game.begin()
        }
        .onChange(of: game.phase) { _, _ in
            withAnimation(.easeIn(duration: 0.16)) { cutPulse = 0.32 }
            withAnimation(.easeOut(duration: 0.5).delay(0.16)) { cutPulse = 0 }
        }
    }

    private var sceneTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 1.045)),
            removal: .opacity.combined(with: .scale(scale: 0.965))
        )
    }
}
