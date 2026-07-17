import SwiftUI
import Combine

/// Drives the whole story. Scenes read `phase` to know what to show and
/// call the `choose*` / `finish*` / `advance()` methods to move forward.
///
/// Design rule: every scene auto-advances on its own timer, so the game
/// always reaches the ending even if the judge never touches the screen.
/// Player input changes *how* the journey looks (grime, detours) but never
/// blocks progress and never needs a full restart.
@MainActor
final class GameState: ObservableObject {

    enum Phase: Int, Equatable, Hashable {
        case opening
        case streetToDrain
        case canal
        case seaFailure
        case recycling
        case ending
    }

    @Published private(set) var phase: Phase = .opening
    @Published private(set) var grime: Double = 0          // 0 clean ... 1 filthy
    @Published private(set) var vibrancy: Double = 1        // 1 vivid ... 0.4 dull
    @Published private(set) var seaAttempts: Int = 0
    @Published private(set) var binMisses: Int = 0
    @Published var journeyReplayToken: Int = 0
    @Published var reduceMotion: Bool = false

    let sound = SoundEngine()

    /// After the player has already seen the fork once (chose the sea),
    /// the story gently insists on recycling next time so the game can't
    /// loop forever.
    var mustRouteToRecycling: Bool { seaAttempts >= 1 }

    func begin() {
        grime = 0
        vibrancy = 1
        seaAttempts = 0
        binMisses = 0
        goTo(.opening)
    }

    func goTo(_ next: Phase) {
        sound.transition(to: next)
        withAnimation(reduceMotion ? .easeInOut(duration: 0.5) : .easeInOut(duration: 0.9)) {
            phase = next
        }
    }

    func registerObstacleHit() {
        grime = min(1, grime + 0.18)
        vibrancy = max(0.45, vibrancy - 0.12)
        sound.impactThud()
        Haptics.collision()
    }

    func advanceFromOpening() {
        goTo(.streetToDrain)
    }

    func advanceFromStreet() {
        goTo(.canal)
    }

    func chooseSea() {
        seaAttempts += 1
        sound.muffle()
        Haptics.warning()
        goTo(.seaFailure)
    }

    func returnToForkFromSea() {
        goTo(.canal)
    }

    func chooseRecycling() {
        goTo(.recycling)
    }

    func registerBinMiss() {
        binMisses += 1
        sound.impactThud()
        Haptics.collision()
    }

    func finishRecycling() {
        vibrancy = 1
        sound.success()
        Haptics.success()
        goTo(.ending)
    }

    func replayJourney() {
        journeyReplayToken += 1
    }

    func playAgain() {
        begin()
    }
}
