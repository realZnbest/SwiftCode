import SwiftUI

struct TruckDeliveryScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: game.t(Loc.truckDeliveryLine),
            showBottle: false,
            textPosition: UnitPoint(x: 0.5, y: 0.15),
            content: { size in
                let roadTopY = size.height * 0.86
                return ZStack {
                    LinearGradient(colors: [Theme.citySkyDark, Theme.citySkyMid, Theme.citySkyDark], startPoint: .top, endPoint: .bottom)
                    SkylineCanvas()
                    NeonStreakField(colors: [Theme.neonCyan, Theme.neonAmber])

                    RoadsideTreesCanvas(roadTopY: roadTopY)

                    Rectangle()
                        .fill(Color(red: 0.06, green: 0.06, blue: 0.08))
                        .frame(height: size.height - roadTopY)
                        .position(x: size.width * 0.5, y: roadTopY + (size.height - roadTopY) / 2)
                    RoadLinesCanvas(roadTopY: roadTopY)
                        .frame(height: size.height)

                    StreetLampRow(roadTopY: roadTopY, direction: 1)
                        .frame(height: size.height)

                    TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                        let t = context.date.timeIntervalSinceReferenceDate
                        let bounce = sin(t * 9) * 1.6
                        RecyclingTruckShape()
                            .position(x: size.width * 0.5, y: roadTopY - 54 + bounce)
                    }
                }
            },
            onFinish: { game.advanceFromTruckDelivery() }
        )
    }
}

private struct RecyclingTruckShape: View {
    var body: some View {
        TruckBody(
            cargoWidth: 108, cargoHeight: 78,
            cargoColors: [Theme.cleanCyan, Theme.cleanCyan.opacity(0.5)],
            cabColors: [Color(white: 0.86), Color(white: 0.58)],
            badgeIcon: "arrow.3.trianglepath",
            badgeColor: Theme.freshGreen,
            windowTint: Theme.cleanCyan
        )
    }
}
