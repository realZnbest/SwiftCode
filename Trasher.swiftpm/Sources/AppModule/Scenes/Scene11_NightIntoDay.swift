import SwiftUI

struct NightIntoDayScene: View {
    @EnvironmentObject var game: GameState
    @State private var start = Date()

    private let nightTop = Color(red: 0.05, green: 0.07, blue: 0.18)
    private let nightBottom = Color(red: 0.14, green: 0.14, blue: 0.22)
    private let dayTop = Color(red: 0.35, green: 0.55, blue: 0.85)
    private let dayBottom = Color(red: 0.85, green: 0.65, blue: 0.42)

    var body: some View {
        VignetteScene(
            line: "เมื่อเวลาผ่านไป",
            content: { size in
                TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                    let elapsed = context.date.timeIntervalSince(start)
                    let progress = min(1, max(0, elapsed / 5.0))
                    let eased = progress * progress * (3 - 2 * progress)

                    let orbX = size.width * (0.15 + 0.55 * eased)
                    let orbY = size.height * 0.78 - size.height * 0.4 * sin(eased * .pi / 2)

                    ZStack {
                        LinearGradient(
                            colors: [
                                nightTop.mix(with: dayTop, amount: eased),
                                nightBottom.mix(with: dayBottom, amount: eased)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )

                        GlowOrb(
                            color: Theme.cleanWhite.mix(with: Theme.neonAmber, amount: eased),
                            size: 90 + 40 * eased
                        )
                        .position(x: orbX, y: orbY)

                        CloudDriftCanvas().opacity(0.5 + 0.2 * eased)
                        SparkleCanvas(count: 20, color: .white).opacity(0.55 * (1 - eased))
                    }
                }
            },
            onFinish: { game.advanceFromNightIntoDay() }
        )
    }
}
