import SwiftUI

struct StormDrainTunnelScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "ดำดิ่งสู่ความมืดมิด จนไม่มีใครมองเห็น",
            vignetteStrength: 0.7,
            showBottle: false,
            content: { size in
                ZStack {
                    Theme.nearBlack
                    Canvas { ctx, canvasSize in
                        for i in 0..<5 {
                            let r = canvasSize.width * (0.15 + CGFloat(i) * 0.18)
                            ctx.stroke(
                                Path(ellipseIn: CGRect(x: canvasSize.width / 2 - r / 2, y: canvasSize.height / 2 - r / 2, width: r, height: r)),
                                with: .color(Theme.cleanCyan.opacity(0.09)), lineWidth: 2
                            )
                        }
                    }
                    BubbleCanvas(count: 22, color: .white).opacity(0.5)
                    SmokeCanvas(intensity: 0.6, color: Theme.murkGreen)

                    TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                        let t = context.date.timeIntervalSinceReferenceDate
                        BottleView(
                            vibrancy: game.vibrancy, dirt: game.grime, showEyes: false,
                            width: 56, height: 138, tilt: .degrees(t * 230)
                        )
                        .position(x: size.width * 0.5, y: size.height * 0.55)
                    }
                }
            },
            onFinish: { game.advanceFromStormDrainTunnel() }
        )
    }
}
