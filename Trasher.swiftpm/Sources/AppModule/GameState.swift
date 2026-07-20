import SwiftUI
import Combine

@MainActor
final class GameState: ObservableObject {

    enum Phase: Int, Equatable, Hashable {
        case title
        case factoryOrigin
        case deliveryTruck
        case vendingAndDiscard
        case streetToDrain
        case stormDrainTunnel
        case landfillFailure
        case secondBottleMirror
        case canal
        case seaFailure
        case nightIntoDay
        case fishingNetRescue
        case sortingLine
        case recycling
        case pelletReveal
        case truckDelivery
        case montage
        case communityCleanup
        case ending
    }

    @Published private(set) var phase: Phase = .title
    @Published private(set) var grime: Double = 0
    @Published private(set) var vibrancy: Double = 1
    @Published private(set) var seaAttempts: Int = 0
    @Published private(set) var landfillAttempts: Int = 0
    @Published private(set) var binMisses: Int = 0
    @Published var journeyReplayToken: Int = 0

    let sound = SoundEngine()

    var mustRouteToRecycling: Bool { seaAttempts >= 1 }

    var mustRouteToDrain: Bool { landfillAttempts >= 1 }

    func begin() {
        grime = 0
        vibrancy = 1
        seaAttempts = 0
        landfillAttempts = 0
        binMisses = 0
        goTo(.title)
    }

    func goTo(_ next: Phase) {
        sound.transition(to: next)
        withAnimation(.easeInOut(duration: 0.9)) {
            phase = next
        }
    }

    func registerObstacleHit() {
        grime = min(1, grime + 0.18)
        vibrancy = max(0.45, vibrancy - 0.12)
        sound.impactThud()
        Haptics.collision()
    }

    func advanceFromTitle() {
        goTo(.factoryOrigin)
    }

    func advanceFromFactoryOrigin() {
        goTo(.deliveryTruck)
    }

    func advanceFromDeliveryTruck() {
        goTo(.vendingAndDiscard)
    }

    func advanceFromVendingAndDiscard() {
        goTo(.streetToDrain)
    }

    func chooseDrain() {
        sound.splash()
        goTo(.stormDrainTunnel)
    }

    func advanceFromStormDrainTunnel() {
        goTo(.secondBottleMirror)
    }

    func advanceFromSecondBottleMirror() {
        goTo(.canal)
    }

    func chooseLandfill() {
        landfillAttempts += 1
        Haptics.warning()
        goTo(.landfillFailure)
    }

    func returnToForkFromLandfill() {
        goTo(.streetToDrain)
    }

    func chooseSea() {
        seaAttempts += 1
        Haptics.warning()
        goTo(.seaFailure)
    }

    func returnToForkFromSea() {
        goTo(.canal)
    }

    func chooseRecycling() {
        goTo(.nightIntoDay)
    }

    func advanceFromNightIntoDay() {
        goTo(.fishingNetRescue)
    }

    func advanceFromFishingNetRescue() {
        goTo(.sortingLine)
    }

    func advanceFromSortingLine() {
        goTo(.recycling)
    }

    func registerBinMiss() {
        binMisses += 1
        sound.impactThud()
        Haptics.collision()
    }

    func finishRecycling() {
        vibrancy = 1
        Haptics.success()
        goTo(.pelletReveal)
    }

    func advanceFromPelletReveal() {
        goTo(.truckDelivery)
    }

    func advanceFromTruckDelivery() {
        goTo(.montage)
    }

    func advanceFromMontage() {
        goTo(.communityCleanup)
    }

    func advanceFromCommunityCleanup() {
        goTo(.ending)
    }

    func replayJourney() {
        journeyReplayToken += 1
    }

    func playAgain() {
        begin()
    }
}
