import SwiftUI

struct DeliveryTruckScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "กำลังเดินทางไปที่ไหนสักแห่ง",
            showBottle: false,
            textPosition: UnitPoint(x: 0.5, y: 0.15),
            content: { size in
                let roadTopY = size.height * 0.86
                return ZStack {
                    LinearGradient(colors: [Theme.deepNavy, Theme.nearBlack], startPoint: .top, endPoint: .bottom)
                    SkylineCanvas().opacity(0.3)
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
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: [Color(white: 0.92), Color(white: 0.7)], startPoint: .top, endPoint: .bottom))
                .frame(width: 120, height: 82)
                .overlay(
                    Image(systemName: "waterbottle.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(Theme.bottleBlue.opacity(0.7))
                )
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.3), lineWidth: 1.5))
                .offset(x: -22, y: -8)

            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: [Color(white: 0.65), Color(white: 0.4)], startPoint: .top, endPoint: .bottom))
                .frame(width: 50, height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.neonCyan.opacity(0.4))
                        .frame(width: 28, height: 20)
                        .offset(y: -13)
                )
                .offset(x: 58, y: 2)

            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black.opacity(0.55))
                .frame(width: 178, height: 8)
                .offset(y: 35)

            truckWheel.offset(x: -40, y: 42)
            truckWheel.offset(x: -10, y: 42)
            truckWheel.offset(x: 48, y: 42)

            Circle().fill(Theme.neonAmber.opacity(0.9)).frame(width: 7, height: 7)
                .glow(Theme.neonAmber, radius: 8, opacity: 0.7)
                .offset(x: 82, y: 12)
            Circle().fill(Color.red.opacity(0.7)).frame(width: 5, height: 5)
                .glow(.red, radius: 4, opacity: 0.4)
                .offset(x: -82, y: 12)
        }
    }

    private var truckWheel: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Color(white: 0.3), .black], center: .center, startRadius: 0, endRadius: 15))
                .frame(width: 26, height: 26)
            Circle().fill(Color(white: 0.55)).frame(width: 8, height: 8)
        }
    }
}
