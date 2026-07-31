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
                    LinearGradient(colors: [Theme.deepNavy, Theme.nearBlack], startPoint: .top, endPoint: .bottom)
                    SkylineCanvas().opacity(0.3)
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
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: [Theme.cleanCyan, Theme.cleanCyan.opacity(0.55)], startPoint: .top, endPoint: .bottom))
                .frame(width: 108, height: 76)
                .overlay(
                    Image(systemName: "arrow.3.trianglepath")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white.opacity(0.92))
                )
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.25), lineWidth: 1.5))
                .offset(x: -28, y: -6)

            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: [Color(white: 0.8), Color(white: 0.5)], startPoint: .top, endPoint: .bottom))
                .frame(width: 54, height: 52)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.cleanCyan.opacity(0.55))
                        .frame(width: 30, height: 22)
                        .offset(y: -11)
                )
                .offset(x: 52, y: 4)

            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black.opacity(0.55))
                .frame(width: 168, height: 8)
                .offset(y: 33)

            wheel.offset(x: -34, y: 40)
            wheel.offset(x: 44, y: 40)

            Circle().fill(Theme.neonAmber.opacity(0.9)).frame(width: 8, height: 8)
                .glow(Theme.neonAmber, radius: 6, opacity: 0.6)
                .offset(x: 78, y: 10)
        }
    }

    private var wheel: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Color(white: 0.3), .black], center: .center, startRadius: 0, endRadius: 15))
                .frame(width: 28, height: 28)
            Circle().fill(Color(white: 0.6)).frame(width: 9, height: 9)
        }
    }
}
