import SwiftUI

struct SecondBottleMirrorScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: game.t(Loc.secondBottleMirrorLine),
            bottlePosition: UnitPoint(x: 0.38, y: 0.48),
            bottleShowEyes: true,
            content: { size in
                SceneClock(fps: 18) { t in
                    ZStack {
                        UnderwaterBackdrop(
                            surface: Color(red: 0.04, green: 0.13, blue: 0.16),
                            deep: Color(red: 0.02, green: 0.05, blue: 0.06),
                            murk: 0.6,
                            t: clockStep(t, 12)
                        )
                        CausticBands(color: Theme.cleanCyan, intensity: 0.4, t: clockStep(t, 15))
                        BubbleCanvas(count: 14, color: Theme.murkBrown, t: clockStep(t, 18))
                        SmokeCanvas(intensity: 0.5, color: Theme.murkGreen, t: clockStep(t, 12))
                        FishSilhouettesCanvas(darkness: 0.6)

                        BottleView(vibrancy: 0.25, dirt: 0.8, showEyes: false, width: 48, height: 118)
                            .saturation(0.2)
                            .opacity(0.55)
                            .rotationEffect(.degrees(35))
                            .position(x: size.width * 0.68, y: size.height * 0.62)
                    }
                }
            },
            onFinish: { game.advanceFromSecondBottleMirror() }
        )
    }
}
