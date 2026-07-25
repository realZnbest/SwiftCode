import SwiftUI

struct NightIntoDayScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "เมื่อเวลาผ่านไป",
            content: { size in
                ZStack {
                    LinearGradient(
                        colors: [Color(red: 0.09, green: 0.13, blue: 0.28), Color(red: 0.72, green: 0.55, blue: 0.4)],
                        startPoint: .top, endPoint: .bottom
                    )
                    GlowOrb(color: Theme.neonAmber, size: 130)
                        .position(x: size.width * 0.78, y: size.height * 0.62)
                    CloudDriftCanvas().opacity(0.6)
                    SparkleCanvas(count: 20, color: .white).opacity(0.25)
                }
            },
            onFinish: { game.advanceFromNightIntoDay() }
        )
    }
}
