import SwiftUI
import Combine

@MainActor
final class GameState: ObservableObject {

    enum Phase: Int, Equatable, Hashable {
        case languageSelect
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

    @Published private(set) var phase: Phase = .languageSelect
    @Published private(set) var grime: Double = 0
    @Published private(set) var vibrancy: Double = 1
    @Published private(set) var seaAttempts: Int = 0
    @Published private(set) var landfillAttempts: Int = 0
    @Published private(set) var binMisses: Int = 0
    @Published var journeyReplayToken: Int = 0
    @Published var language: AppLanguage = .thai

    let sound = SoundEngine()

    private let debugStartPhase: Phase? = .canal
    private var hasStarted = false

    var mustRouteToRecycling: Bool { seaAttempts >= 1 }

    var mustRouteToDrain: Bool { landfillAttempts >= 1 }

    func begin() {
        grime = 0
        vibrancy = 1
        seaAttempts = 0
        landfillAttempts = 0
        binMisses = 0
        if hasStarted {
            goTo(debugStartPhase ?? .title)
        } else {
            hasStarted = true
            goTo(debugStartPhase ?? .languageSelect)
        }
    }

    func selectLanguage(_ language: AppLanguage) {
        self.language = language
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
        goTo(.landfillFailure)
    }

    func returnToForkFromLandfill() {
        goTo(.streetToDrain)
    }

    func chooseSea() {
        seaAttempts += 1
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
    }

    func finishRecycling() {
        vibrancy = 1
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
