import SwiftUI

struct SortingLineScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: game.t(Loc.sortingLineLine),
            bottlePosition: UnitPoint(x: 0.5, y: 0.8),
            content: { size in
                ZStack {
                    LinearGradient(
                        colors: [Color(red: 0.03, green: 0.10, blue: 0.09), Color(red: 0.02, green: 0.05, blue: 0.05)],
                        startPoint: .top, endPoint: .bottom
                    )
                    RecyclingEmblemGlow(brighten: 0)
                    RecyclingGreenhouseRoof()
                    SortingBeltStructure(beltYFrac: 0.9)
                    SortingFloorGlow()
                    LightRaysCanvas(color: Theme.freshGreen, count: 3)

                    TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                        let t = context.date.timeIntervalSinceReferenceDate
                        let x = size.width * (0.2 + 0.6 * (0.5 + 0.5 * sin(t * 1.3)))
                        Rectangle()
                            .fill(LinearGradient(colors: [.clear, Theme.cleanCyan.opacity(0.55), .clear], startPoint: .top, endPoint: .bottom))
                            .frame(width: 4, height: size.height)
                            .position(x: x, y: size.height / 2)
                            .blur(radius: 2)
                    }
                }
            },
            onFinish: { game.advanceFromSortingLine() }
        )
    }
}
