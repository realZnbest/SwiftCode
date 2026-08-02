import SwiftUI

struct LandfillFailureScene: View {
    @EnvironmentObject var game: GameState
    @State private var showText = false

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let groundY = size.height * 0.46

            ZStack {
                LinearGradient(colors: [Theme.nearBlack, Color(red: 0.09, green: 0.07, blue: 0.05)],
                               startPoint: .top, endPoint: .bottom)

                SmokeCanvas(intensity: 0.5, color: Theme.smokeOrange)
                    .opacity(0.5)
                    .frame(height: groundY)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .clipped()

                BottleView(
                    vibrancy: 0.3, dirt: min(1, game.grime + 0.3), showEyes: false,
                    width: 54, height: 132, tilt: .degrees(16)
                )
                .saturation(0.25)
                .position(x: size.width * 0.52, y: groundY + 30)

                LandfillGroundCanvas(groundY: groundY)

                if showText {
                    Text(game.t(Loc.landfillFailureLine))
                        .font(Theme.line(24))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 26)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: Capsule())
                        .transition(.opacity)
                        .position(x: size.width * 0.5, y: size.height * 0.22)
                }

                Vignette(strength: 0.75)
            }
        }
        .onAppear(perform: runSequence)
    }

    private func runSequence() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.4))
            withAnimation(.easeIn(duration: 0.6)) { showText = true }
            try? await Task.sleep(for: .seconds(2.4))
            withAnimation(.easeOut(duration: 0.4)) { showText = false }
            try? await Task.sleep(for: .seconds(0.4))
            game.returnToForkFromLandfill()
        }
    }
}

private struct LandfillGroundCanvas: View {
    let groundY: CGFloat

    var body: some View {
        Canvas { ctx, size in
            let dirtRect = CGRect(x: 0, y: groundY, width: size.width, height: size.height - groundY)
            ctx.fill(Path(dirtRect), with: .color(Color(red: 0.22, green: 0.16, blue: 0.1)))

            let bandColors: [Color] = [
                Color(red: 0.3, green: 0.22, blue: 0.13),
                Color(red: 0.24, green: 0.17, blue: 0.1),
                Color(red: 0.17, green: 0.12, blue: 0.07),
                Color(red: 0.12, green: 0.08, blue: 0.05)
            ]
            for (i, color) in bandColors.enumerated() {
                let bandT = CGFloat(i + 1) / CGFloat(bandColors.count + 1)
                let y = groundY + (size.height - groundY) * bandT
                var band = Path()
                let steps = 10
                for j in 0...steps {
                    let t = CGFloat(j) / CGFloat(steps)
                    let x = size.width * t
                    let jitter = (rnd(i * 20 + j, 720) - 0.5) * 14
                    let pt = CGPoint(x: x, y: y + jitter)
                    if j == 0 { band.move(to: pt) } else { band.addLine(to: pt) }
                }
                ctx.stroke(band, with: .color(color.opacity(0.85)), lineWidth: 10)
            }

            for i in 0..<20 {
                let x = rnd(i, 730) * size.width
                let y = groundY + rnd(i, 731) * (size.height - groundY)
                let r: CGFloat = 2 + rnd(i, 732) * 3
                ctx.fill(Path(ellipseIn: CGRect(x: x - r / 2, y: y - r / 2, width: r, height: r)),
                         with: .color(.black.opacity(0.3)))
            }

            var edge = Path()
            let edgeSteps = 14
            for j in 0...edgeSteps {
                let t = CGFloat(j) / CGFloat(edgeSteps)
                let x = size.width * t
                let jitter = (rnd(j, 740) - 0.5) * 10
                let pt = CGPoint(x: x, y: groundY + jitter)
                if j == 0 { edge.move(to: pt) } else { edge.addLine(to: pt) }
            }
            ctx.stroke(edge, with: .color(Color(red: 0.35, green: 0.25, blue: 0.15).opacity(0.9)), lineWidth: 3)

            for i in 0..<6 {
                let x = size.width * (0.4 + rnd(i, 750) * 0.24)
                let y = groundY - rnd(i, 751) * 22
                let r: CGFloat = 5 + rnd(i, 752) * 6
                ctx.fill(Path(ellipseIn: CGRect(x: x - r / 2, y: y - r / 2, width: r, height: r)),
                         with: .color(Color(red: 0.26, green: 0.19, blue: 0.11).opacity(0.8)))
            }
        }
        .allowsHitTesting(false)
    }
}
