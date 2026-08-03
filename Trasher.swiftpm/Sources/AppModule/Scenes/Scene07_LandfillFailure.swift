import SwiftUI

struct LandfillFailureScene: View {
    @EnvironmentObject var game: GameState
    @State private var showText = false
    @State private var sceneStart = Date()

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let groundY = size.height * 0.46

            TimelineView(.animation(minimumInterval: 1.0 / 24)) { context in
                let elapsed = context.date.timeIntervalSince(sceneStart)
                let clock = context.date.timeIntervalSinceReferenceDate
                let settle = min(1, max(0, elapsed / 3.0))
                let drain = settle * settle

                ZStack {
                    LinearGradient(
                        colors: [
                            Theme.nearBlack,
                            Color(red: 0.09, green: 0.07, blue: 0.05)
                                .mix(with: Color(white: 0.07), amount: drain * 0.7)
                        ],
                        startPoint: .top, endPoint: .bottom
                    )

                    LandfillCrow(t: clockStep(clock, 20), skyY: groundY * 0.42)

                    HeatHazeCanvas(baseY: groundY, t: clockStep(clock, 20))

                    SmokeCanvas(
                        intensity: 0.5,
                        color: Theme.smokeOrange.mix(with: Color(white: 0.32), amount: drain * 0.65),
                        t: clockStep(clock, 12)
                    )
                    .opacity(0.5)
                    .frame(height: groundY)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .clipped()

                    BottleView(
                        vibrancy: 0.3 * (1 - drain * 0.6), dirt: min(1, game.grime + 0.3), showEyes: false,
                        width: 54, height: 132, tilt: .degrees(16)
                    )
                    .saturation(0.25 * (1 - drain * 0.8))
                    .position(x: size.width * 0.52, y: groundY + 30)

                    LandfillGroundCanvas(groundY: groundY, drain: drain)

                    DustMotesCanvas(groundY: groundY, t: clockStep(clock, 15))

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

                    Vignette(strength: 0.75 + drain * 0.13)
                }
                .scaleEffect(1 + settle * 0.05)
            }
        }
        .onAppear {
            sceneStart = Date()
            runSequence()
        }
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

private struct HeatHazeCanvas: View {
    var baseY: CGFloat
    var t: Double

    var body: some View {
        Canvas { ctx, size in
            let bands = 9
            for i in 0..<bands {
                let f = Double(i) / Double(bands)
                let y = baseY - CGFloat(f) * baseY * 0.42
                let fade = (1 - f) * (1 - f)
                let amp = 2.5 + rnd(i, 1201) * 3.5
                let k = 0.012 + Double(rnd(i, 1202)) * 0.010
                let phase = t * (1.6 + Double(rnd(i, 1203)) * 1.4) + Double(i)

                var path = Path()
                var started = false
                var x: CGFloat = -10
                while x <= size.width + 10 {
                    let yy = y + amp * CGFloat(sin(Double(x) * k + phase))
                    let p = CGPoint(x: x, y: yy)
                    if started { path.addLine(to: p) } else { path.move(to: p); started = true }
                    x += 12
                }
                ctx.stroke(path, with: .color(Theme.smokeOrange.opacity(0.10 * fade)),
                           style: StrokeStyle(lineWidth: 7, lineCap: .round))
            }
        }
        .allowsHitTesting(false)
    }
}

private struct DustMotesCanvas: View {
    var groundY: CGFloat
    var t: Double

    var body: some View {
        Canvas { ctx, size in
            let count = 34
            let span = size.height - groundY + 80
            for i in 0..<count {
                let fall = CGFloat((t * (4 + Double(rnd(i, 1301)) * 8))
                    .truncatingRemainder(dividingBy: Double(span)))
                let x = rnd(i, 1300) * size.width + CGFloat(sin(t * 0.4 + Double(i) * 1.3)) * 11
                var y = groundY - 40 + rnd(i, 1302) * span + fall
                if y > size.height + 20 { y -= span }
                let r = 0.9 + rnd(i, 1303) * 2.0
                ctx.opacity = 0.10 + Double(rnd(i, 1304)) * 0.20
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                         with: .color(Color(red: 0.62, green: 0.52, blue: 0.36)))
            }
            ctx.opacity = 1
        }
        .allowsHitTesting(false)
    }
}

private struct LandfillCrow: View {
    var t: Double
    var skyY: CGFloat

    var body: some View {
        Canvas { ctx, size in
            let cycle = size.width + 240
            let x = CGFloat((t * 32).truncatingRemainder(dividingBy: Double(cycle))) - 120
            let y = skyY + CGFloat(sin(t * 0.85)) * 10
            let flap = CGFloat(sin(t * 5.0))
            let s: CGFloat = 1.5
            let ink = Color.black.opacity(0.5)

            var wings = Path()
            wings.move(to: CGPoint(x: x - 15 * s, y: y - flap * 8 * s))
            wings.addQuadCurve(to: CGPoint(x: x, y: y),
                               control: CGPoint(x: x - 7 * s, y: y - flap * 3 * s - 3 * s))
            wings.addQuadCurve(to: CGPoint(x: x + 15 * s, y: y - flap * 8 * s),
                               control: CGPoint(x: x + 7 * s, y: y - flap * 3 * s - 3 * s))
            ctx.stroke(wings, with: .color(ink), style: StrokeStyle(lineWidth: 2.4 * s, lineCap: .round))

            ctx.fill(Path(ellipseIn: CGRect(x: x - 3 * s, y: y - 2 * s, width: 6 * s, height: 4 * s)),
                     with: .color(ink))
        }
        .allowsHitTesting(false)
    }
}

private struct LandfillGroundCanvas: View {
    let groundY: CGFloat
    var drain: Double = 0

    var body: some View {
        Canvas { ctx, size in
            let ash = Color(white: 0.26)
            func drained(_ c: Color) -> Color { c.mix(with: ash, amount: drain * 0.5) }

            let dirtRect = CGRect(x: 0, y: groundY, width: size.width, height: size.height - groundY)
            ctx.fill(Path(dirtRect), with: .color(drained(Color(red: 0.22, green: 0.16, blue: 0.1))))

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
                ctx.stroke(band, with: .color(drained(color).opacity(0.85)), lineWidth: 10)
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
            ctx.stroke(edge, with: .color(drained(Color(red: 0.35, green: 0.25, blue: 0.15)).opacity(0.9)),
                       lineWidth: 3)

            for i in 0..<6 {
                let x = size.width * (0.4 + rnd(i, 750) * 0.24)
                let y = groundY - rnd(i, 751) * 22
                let r: CGFloat = 5 + rnd(i, 752) * 6
                ctx.fill(Path(ellipseIn: CGRect(x: x - r / 2, y: y - r / 2, width: r, height: r)),
                         with: .color(drained(Color(red: 0.26, green: 0.19, blue: 0.11)).opacity(0.8)))
            }
        }
        .allowsHitTesting(false)
    }
}
