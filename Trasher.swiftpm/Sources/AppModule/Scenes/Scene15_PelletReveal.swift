import SwiftUI

struct PelletRevealScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "ส่วนชิ้นนี้มันไม่ได้เหมือนเดิม แต่ก็ไม่ได้หายไปไหน",
            showBottle: false,
            content: { size in
                ZStack {
                    LinearGradient(
                        colors: [Theme.nearBlack.mix(with: Theme.freshGreen, amount: 0.18), Theme.nearBlack],
                        startPoint: .top, endPoint: .bottom
                    )
                    LightRaysCanvas(color: Theme.freshGreen, count: 3)
                    SparkleCanvas(count: 36, color: Theme.cleanWhite)

                    let moundCenter = CGPoint(x: size.width * 0.5, y: size.height * 0.6)
                    let targets: [CGPoint] = (0..<50).map { i in
                        let a = Double(rnd(i, 500)) * 2 * .pi
                        let r = rnd(i, 501) * 32
                        return CGPoint(x: moundCenter.x + CGFloat(cos(a)) * r, y: moundCenter.y + CGFloat(sin(a)) * r * 0.5)
                    }
                    FlakeField(
                        count: 50, scatterCenter: moundCenter, scatterRadius: 90,
                        target: targets, mix: 1, color: Theme.freshGreen.opacity(0.9), opacity: 0.9
                    )
                }
            },
            onFinish: { game.advanceFromPelletReveal() }
        )
    }
}
