import SwiftUI

private struct MontageVignette {
    let colors: [Color]
    let label: Loc.Entry
    let kind: Kind

    enum Kind { case city, river, everywhere }
}

private let montageVignettes: [MontageVignette] = [
    MontageVignette(colors: [Theme.smokeOrange, Theme.neonPink], label: Loc.montageCity, kind: .city),
    MontageVignette(colors: [Theme.murkGreen, Theme.cleanCyan], label: Loc.montageRiver, kind: .river),
    MontageVignette(colors: [Theme.cleanCyan, Theme.freshGreen], label: Loc.montageEverywhere, kind: .everywhere)
]

struct MontageScene: View {
    @EnvironmentObject var game: GameState

    @State private var index = 0
    @State private var advanceTask: Task<Void, Never>?

    private let perVignette: Double = 1.7

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                ForEach(Array(montageVignettes.enumerated()), id: \.offset) { i, vignette in
                    if i == index {
                        vignetteView(vignette, size: size)
                            .transition(.opacity)
                    }
                }
            }
        }
        .onAppear(perform: runSequence)
        .onDisappear { advanceTask?.cancel() }
    }

    @ViewBuilder
    private func vignetteView(_ vignette: MontageVignette, size: CGSize) -> some View {
        ZStack {
            LinearGradient(colors: [vignette.colors[0].opacity(0.35), Theme.nearBlack],
                           startPoint: .top, endPoint: .bottom)

            switch vignette.kind {
            case .city:
                SkylineCanvas()
                NeonStreakField(colors: [Theme.neonAmber, Theme.neonPink])
            case .river:
                FishSilhouettesCanvas(darkness: 0.3)
                BubbleCanvas(count: 20, color: Theme.cleanCyan)
            case .everywhere:
                EverywhereBackdrop()
                Image(systemName: "arrow.3.trianglepath")
                    .font(.system(size: size.width * 0.14, weight: .bold))
                    .foregroundStyle(.white)
                    .glow(Theme.freshGreen, radius: 18, opacity: 0.9)
                    .position(x: size.width / 2, y: size.height * 0.36)
            }

            Text(game.t(vignette.label))
                .font(Theme.line(26))
                .foregroundStyle(.white.opacity(0.9))
                .position(x: size.width / 2, y: size.height * 0.8)
                .transition(.asymmetric(
                    insertion: .opacity.animation(.easeIn(duration: 0.35).delay(0.25)),
                    removal: .opacity.animation(.easeOut(duration: 0.2))
                ))

            Vignette(strength: 0.45)
        }
    }

    private func runSequence() {
        index = 0
        advanceTask?.cancel()
        advanceTask = Task { @MainActor in
            for step in 1..<montageVignettes.count {
                try? await Task.sleep(for: .seconds(perVignette))
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.5)) { index = step }
            }
            try? await Task.sleep(for: .seconds(perVignette))
            guard !Task.isCancelled else { return }
            game.advanceFromMontage()
        }
    }
}

private struct EverywhereBackdrop: View {
    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let horizonY = size.height * 0.58

            ZStack {
                GlowOrb(color: Theme.cleanWhite, size: 70)
                    .position(x: size.width * 0.8, y: size.height * 0.14)
                CloudDriftCanvas().opacity(0.45)

                MountainRidgeCanvas(horizonY: horizonY)
                BirdFlockCanvas(count: 5)

                LandAndSeaCanvas(horizonY: horizonY)

                LitterScatterCanvas(horizonY: horizonY)

                SparkleCanvas(count: 40, color: Theme.cleanWhite).opacity(0.4)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct MountainRidgeCanvas: View {
    var horizonY: CGFloat

    var body: some View {
        Canvas { ctx, size in
            drawRange(ctx: ctx, size: size, baseY: horizonY - 8,
                      peakY: horizonY - size.height * 0.42,
                      color: Color(red: 0.14, green: 0.18, blue: 0.22).opacity(0.4), seed: 5, peakCount: 4,
                      snowCap: true)
            drawRange(ctx: ctx, size: size, baseY: horizonY - 4,
                      peakY: horizonY - size.height * 0.30,
                      color: Color(red: 0.10, green: 0.14, blue: 0.16).opacity(0.6), seed: 10, peakCount: 5,
                      snowCap: false)
            drawRange(ctx: ctx, size: size, baseY: horizonY + 2,
                      peakY: horizonY - size.height * 0.18,
                      color: Color(red: 0.06, green: 0.09, blue: 0.11).opacity(0.85), seed: 40, peakCount: 6,
                      snowCap: false)
        }
    }

    private func drawRange(ctx: GraphicsContext, size: CGSize, baseY: CGFloat, peakY: CGFloat,
                            color: Color, seed: Int, peakCount: Int, snowCap: Bool) {
        var peaks: [CGPoint] = []
        let slot = size.width / CGFloat(peakCount)
        for i in 0...peakCount {
            let x = CGFloat(i) * slot
            let jitter = (rnd(i, seed) - 0.5) * size.height * 0.12
            let y = i.isMultiple(of: 2) ? baseY : peakY + jitter
            peaks.append(CGPoint(x: x, y: y))
        }

        var path = Path()
        path.move(to: CGPoint(x: 0, y: baseY))
        for p in peaks { path.addLine(to: p) }
        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.addLine(to: CGPoint(x: 0, y: size.height))
        path.closeSubpath()
        ctx.fill(path, with: .color(color))

        guard snowCap else { return }
        for i in stride(from: 1, to: peaks.count, by: 2) {
            let p = peaks[i]
            var cap = Path()
            cap.move(to: CGPoint(x: p.x - slot * 0.22, y: p.y + slot * 0.22))
            cap.addLine(to: CGPoint(x: p.x, y: p.y))
            cap.addLine(to: CGPoint(x: p.x + slot * 0.22, y: p.y + slot * 0.22))
            ctx.stroke(cap, with: .color(.white.opacity(0.4)), style: StrokeStyle(lineWidth: 3, lineJoin: .round))
        }
    }
}

private struct LandAndSeaCanvas: View {
    var horizonY: CGFloat

    var body: some View {
        Canvas { ctx, size in
            let seaColor = Color(red: 0.07, green: 0.20, blue: 0.26)
            let seaRect = CGRect(x: 0, y: horizonY, width: size.width, height: size.height - horizonY)
            ctx.fill(Path(seaRect), with: .linearGradient(
                Gradient(colors: [seaColor, seaColor.mix(with: .black, amount: 0.3)]),
                startPoint: CGPoint(x: 0, y: horizonY), endPoint: CGPoint(x: 0, y: size.height)
            ))

            for i in 0..<5 {
                let y = horizonY + 12 + CGFloat(i) * ((size.height - horizonY) / 6)
                var wave = Path()
                var started = false
                var x: CGFloat = size.width * 0.5
                while x <= size.width {
                    let wy = y + sin(x * 0.1 + CGFloat(i)) * 3
                    if !started { wave.move(to: CGPoint(x: x, y: wy)); started = true }
                    else { wave.addLine(to: CGPoint(x: x, y: wy)) }
                    x += size.width * 0.04
                }
                ctx.stroke(wave, with: .color(.white.opacity(0.16)), lineWidth: 1.2)
                if i.isMultiple(of: 2) {
                    ctx.stroke(wave, with: .color(.white.opacity(0.28)), style: StrokeStyle(lineWidth: 0.8, dash: [3, 5]))
                }
            }

            let landColor = Color(red: 0.18, green: 0.30, blue: 0.17)
            let shoreX = size.width * 0.5
            var land = Path()
            land.move(to: CGPoint(x: 0, y: horizonY))
            land.addLine(to: CGPoint(x: shoreX, y: horizonY))
            land.addQuadCurve(to: CGPoint(x: shoreX - 34, y: size.height), control: CGPoint(x: shoreX - 6, y: horizonY + 60))
            land.addLine(to: CGPoint(x: 0, y: size.height))
            land.closeSubpath()
            ctx.fill(land, with: .linearGradient(
                Gradient(colors: [landColor, landColor.mix(with: .black, amount: 0.35)]),
                startPoint: CGPoint(x: 0, y: horizonY), endPoint: CGPoint(x: 0, y: size.height)
            ))

            var shore = Path()
            shore.move(to: CGPoint(x: shoreX, y: horizonY))
            shore.addQuadCurve(to: CGPoint(x: shoreX - 34, y: size.height), control: CGPoint(x: shoreX - 6, y: horizonY + 60))
            ctx.stroke(shore, with: .color(Color(red: 0.75, green: 0.68, blue: 0.5).opacity(0.5)), lineWidth: 4)

            let tuftColor = landColor.mix(with: .black, amount: 0.3)
            let tuftCount = 22
            for i in 0..<tuftCount {
                let tx = size.width * 0.02 + (shoreX - 20) * rnd(i, 601)
                guard tx < shoreX - 10 else { continue }
                let ty = horizonY + (size.height - horizonY) * rnd(i, 602)
                let h: CGFloat = 5 + rnd(i, 603) * 6
                var blade = Path()
                blade.move(to: CGPoint(x: tx, y: ty))
                blade.addLine(to: CGPoint(x: tx + (rnd(i, 604) - 0.5) * 5, y: ty - h))
                ctx.stroke(blade, with: .color(tuftColor.opacity(0.5)), lineWidth: 1.2)
            }

            let rockColor = Color(red: 0.3, green: 0.3, blue: 0.28)
            for i in 0..<8 {
                let rx = size.width * 0.03 + (shoreX - 30) * rnd(i, 621)
                guard rx < shoreX - 15 else { continue }
                let ry = horizonY + (size.height - horizonY) * (0.4 + rnd(i, 622) * 0.55)
                let rs: CGFloat = 4 + rnd(i, 623) * 5
                ctx.fill(Path(ellipseIn: CGRect(x: rx - rs / 2, y: ry - rs * 0.4, width: rs, height: rs * 0.6)),
                         with: .color(rockColor.opacity(0.6)))
            }

            let farRowCount = 9
            for i in 0..<farRowCount {
                let tx = size.width * (0.02 + (shoreX / size.width - 0.06) * CGFloat(i) / CGFloat(farRowCount - 1))
                let baseY = horizonY + (size.height - horizonY) * (0.12 + rnd(i, 631) * 0.1)
                let h: CGFloat = 14 + rnd(i, 632) * 6
                if i % 2 == 0 {
                    drawPine(ctx: ctx, x: tx, baseY: baseY, height: h, opacity: 0.55)
                } else {
                    drawRoundedTree(ctx: ctx, x: tx, baseY: baseY, height: h, opacity: 0.55)
                }
            }

            let nearRowCount = 7
            for i in 0..<nearRowCount {
                let tx = size.width * (0.05 + (shoreX / size.width - 0.14) * rnd(i, 641))
                let baseY = horizonY + (size.height - horizonY) * (0.32 + rnd(i, 642) * 0.4)
                let h: CGFloat = 26 + rnd(i, 643) * 16
                if i % 2 == 0 {
                    drawPine(ctx: ctx, x: tx, baseY: baseY, height: h, opacity: 0.95)
                } else {
                    drawRoundedTree(ctx: ctx, x: tx, baseY: baseY, height: h, opacity: 0.95)
                }
            }
        }
    }

    private func drawRoundedTree(ctx: GraphicsContext, x: CGFloat, baseY: CGFloat, height: CGFloat, opacity: Double) {
        let trunkColor = Color(red: 0.25, green: 0.17, blue: 0.1)
        let leafColor = Color(red: 0.16, green: 0.32, blue: 0.16)

        var trunk = Path()
        trunk.addRect(CGRect(x: x - height * 0.05, y: baseY - height * 0.18, width: height * 0.1, height: height * 0.18))
        ctx.fill(trunk, with: .color(trunkColor.opacity(opacity)))

        let canopyR = height * 0.42
        let canopyCenter = CGPoint(x: x, y: baseY - height * 0.18 - canopyR * 0.75)
        for (dx, dy, scale) in [(0.0, 0.0, 1.0), (-0.5, 0.15, 0.7), (0.5, 0.15, 0.7)] {
            let r = canopyR * scale
            let c = CGPoint(x: canopyCenter.x + canopyR * dx, y: canopyCenter.y + canopyR * dy)
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                     with: .color(leafColor.opacity(opacity)))
        }
    }

    private func drawPine(ctx: GraphicsContext, x: CGFloat, baseY: CGFloat, height: CGFloat, opacity: Double) {
        let trunkColor = Color(red: 0.25, green: 0.17, blue: 0.1)
        let leafColor = Color(red: 0.09, green: 0.22, blue: 0.12)

        var trunk = Path()
        trunk.addRect(CGRect(x: x - height * 0.05, y: baseY - height * 0.2, width: height * 0.1, height: height * 0.2))
        ctx.fill(trunk, with: .color(trunkColor.opacity(opacity)))

        for tier in 0..<3 {
            let tierW = height * (0.6 - CGFloat(tier) * 0.14)
            let tierTopY = baseY - height * (0.2 + CGFloat(tier + 1) * 0.28)
            let tierBotY = baseY - height * (0.2 + CGFloat(tier) * 0.28)
            var cone = Path()
            cone.move(to: CGPoint(x: x, y: tierTopY))
            cone.addLine(to: CGPoint(x: x - tierW / 2, y: tierBotY))
            cone.addLine(to: CGPoint(x: x + tierW / 2, y: tierBotY))
            cone.closeSubpath()
            ctx.fill(cone, with: .color(leafColor.opacity(opacity * 0.9)))
        }
    }
}

private struct LitterScatterCanvas: View {
    var horizonY: CGFloat

    var body: some View {
        Canvas { ctx, size in
            let itemCount = 24
            let litterColors = [Theme.smokeOrange, Theme.neonPink, Theme.bottleBlueDeep, Color.white.opacity(0.6)]

            for i in 0..<itemCount {
                let x = size.width * rnd(i, 7701)
                let y = horizonY + (size.height - horizonY) * (0.15 + rnd(i, 7702) * 0.82)
                guard y > horizonY else { continue }
                let s: CGFloat = 6 + rnd(i, 7703) * 6
                let color = litterColors[i % litterColors.count]
                let shapeKind = i % 3

                switch shapeKind {
                case 0:
                    var bottle = Path()
                    bottle.addRoundedRect(in: CGRect(x: x - s * 0.28, y: y - s, width: s * 0.56, height: s), cornerSize: CGSize(width: 1.5, height: 1.5))
                    bottle.addRect(CGRect(x: x - s * 0.12, y: y - s * 1.25, width: s * 0.24, height: s * 0.3))
                    ctx.fill(bottle, with: .color(color.opacity(0.75)))
                case 1:
                    ctx.fill(Path(ellipseIn: CGRect(x: x - s / 2, y: y - s * 0.4, width: s, height: s * 0.55)),
                             with: .color(color.opacity(0.6)))
                default:
                    ctx.fill(Path(ellipseIn: CGRect(x: x - s * 0.4, y: y - s * 0.15, width: s * 0.8, height: s * 0.3)),
                             with: .color(color.opacity(0.7)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
