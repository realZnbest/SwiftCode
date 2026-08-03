import SwiftUI

struct DeliveryTruckScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: game.t(Loc.deliveryTruckLine),
            showBottle: false,
            textPosition: UnitPoint(x: 0.5, y: 0.15),
            content: { size in
                let roadTopY = size.height * 0.86
                return ZStack {
                    LinearGradient(colors: [Theme.citySkyDark, Theme.citySkyMid, Theme.citySkyDark], startPoint: .top, endPoint: .bottom)
                    SkylineCanvas()
                    NeonStreakField(colors: [Theme.neonAmber, Theme.neonPink, Theme.neonCyan])

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
                        DeliveryTruckShape()
                            .position(x: size.width * 0.5, y: roadTopY - 54 + bounce)
                    }

                    SparkleCanvas(count: 12, color: .white).opacity(0.25)
                }
            },
            onFinish: { game.advanceFromDeliveryTruck() }
        )
    }
}

private struct DeliveryTruckShape: View {
    var body: some View {
        TruckBody(
            cargoWidth: 118, cargoHeight: 80,
            cargoColors: [Color(white: 0.94), Color(white: 0.72)],
            cabColors: [Color(white: 0.88), Color(white: 0.62)],
            badgeIcon: "waterbottle.fill",
            badgeColor: Theme.bottleBlue,
            windowTint: Theme.neonCyan
        )
    }
}
