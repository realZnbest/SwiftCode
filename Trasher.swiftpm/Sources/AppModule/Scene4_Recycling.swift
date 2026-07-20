import SwiftUI

struct RecyclingScene: View {
    @EnvironmentObject var game: GameState

    private enum Stage { case arriving, choosing, cleaning, shredding, reforming, done }

    @State private var stage: Stage = .arriving
    @State private var stageStart = Date()
    @State private var bottlePos = CGPoint(x: 0.5, y: 0.22)
    @State private var dragBase = CGPoint(x: 0.5, y: 0.22)
    @State private var misses = 0
    @State private var brighten: Double = 0
    @State private var wrongDropFeedback = false
    @State private var showBenchCaption = false

    private let landfillRect = CGRect(x: 0.08, y: 0.55, width: 0.30, height: 0.3)
    private let recyclingRect = CGRect(x: 0.62, y: 0.55, width: 0.30, height: 0.3)

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                background(brighten: brighten)

                machineryGlow(size: size)

                if stage == .choosing || stage == .arriving {
                    let hoveringLandfill = stage == .choosing && landfillRect.contains(bottlePos)
                    let hoveringRecycling = stage == .choosing && recyclingRect.contains(bottlePos)
                    binView(rect: landfillRect, size: size, kind: .landfill, bright: hoveringLandfill, warning: wrongDropFeedback)
                    binView(rect: recyclingRect, size: size, kind: .recycling, bright: hoveringRecycling || misses > 0, warning: false)
                }

                stageContent(size: size)

                if wrongDropFeedback && stage == .choosing {
                    Label("ถังขยะใบนี้มีแต่จะทำให้มันถูกฝัง ลองเอาไปรีไซเคิลดูสิ!", systemImage: "exclamationmark.triangle.fill")
                        .font(Theme.line(16))
                        .foregroundStyle(Theme.neonAmber)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Theme.nearBlack.opacity(0.78), in: Capsule())
                        .position(x: size.width * 0.5, y: size.height * 0.44)
                        .transition(.opacity)
                }

                if showBenchCaption && stage == .done {
                    Text("ดูนี่สิ! ตอนนี้มันกลายเป็นม้านั่งที่ทำจากพลาสติกรีไซเคิลแล้ว")
                        .font(Theme.line(20))
                        .foregroundStyle(.white.opacity(0.95))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 26)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: Capsule())
                        .glow(Theme.freshGreen, radius: 10, opacity: 0.3)
                        .position(x: size.width * 0.5, y: size.height * 0.78)
                        .transition(.opacity)
                }

                Vignette(strength: 0.55 - brighten * 0.25)
            }
            .contentShape(Rectangle())
            .gesture(
                stage == .choosing ?
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        bottlePos = CGPoint(
                            x: min(0.95, max(0.05, dragBase.x + value.translation.width / size.width)),
                            y: min(0.95, max(0.05, dragBase.y + value.translation.height / size.height))
                        )
                    }
                    .onEnded { _ in evaluateDrop() }
                : nil
            )
        }
        .onAppear(perform: setup)
    }

    private func background(brighten: Double) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    Theme.deepNavy.mix(with: Theme.cleanWhite, amount: brighten * 0.35),
                    Theme.nearBlack.mix(with: Theme.freshGreen, amount: brighten * 0.15)
                ],
                startPoint: .top, endPoint: .bottom
            )
            FactorySilhouetteCanvas()
                .opacity(0.7)
            balesRow
                .opacity(0.55)
            LightRaysCanvas(color: Theme.cleanCyan, count: 3)
                .opacity(0.5 + brighten * 0.2)
            NeonStreakField(colors: [Theme.cleanCyan, Theme.freshGreen])
                .opacity(0.5 + brighten * 0.3)
            ConveyorBeltCanvas()
            SparkleCanvas(count: Int(20 + brighten * 40), color: Theme.cleanWhite)
                .opacity(0.3 + brighten * 0.5)
        }
    }

    private var balesRow: some View {
        GeometryReader { geo in
            let size = geo.size
            HStack(alignment: .bottom, spacing: size.width * 0.015) {
                ForEach(0..<6, id: \.self) { i in
                    let tint = [Theme.freshGreen, Theme.cleanCyan, Theme.smokeOrange][i % 3]
                    RoundedRectangle(cornerRadius: 2)
                        .fill(tint.opacity(0.16))
                        .overlay(RoundedRectangle(cornerRadius: 2).stroke(tint.opacity(0.3), lineWidth: 1))
                        .overlay(
                            Path { p in
                                p.move(to: CGPoint(x: 0, y: 0)); p.addLine(to: CGPoint(x: size.width * 0.05, y: size.height * 0.08))
                                p.move(to: CGPoint(x: size.width * 0.05, y: 0)); p.addLine(to: CGPoint(x: 0, y: size.height * 0.08))
                            }
                            .stroke(tint.opacity(0.35), lineWidth: 1)
                        )
                        .frame(width: size.width * 0.05, height: size.height * (0.16 + CGFloat((i * 37) % 5) * 0.025))
                }
            }
            .frame(width: size.width, alignment: .leading)
            .padding(.leading, size.width * 0.015)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, size.height * 0.14)
        }
    }

    private func machineryGlow(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { ctx, canvasSize in
                for i in 0..<4 {
                    let y = canvasSize.height * (0.15 + CGFloat(i) * 0.22)
                    let pulse = 0.4 + 0.3 * sin(t * 1.4 + Double(i))
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: canvasSize.width, y: y))
                    ctx.stroke(path, with: .color(Theme.cleanCyan.opacity(0.12 * pulse)), lineWidth: 3)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private enum BinKind { case landfill, recycling }

    private func binView(rect: CGRect, size: CGSize, kind: BinKind, bright: Bool, warning: Bool) -> some View {
        let frame = CGRect(x: rect.minX * size.width, y: rect.minY * size.height,
                            width: rect.width * size.width, height: rect.height * size.height)
        let glowColor = warning ? Theme.neonAmber : (kind == .landfill ? Theme.smokeOrange : Theme.freshGreen)
        let label = kind == .landfill ? "ถังขยะ" : "รีไซเคิล"

        return VStack(spacing: 6) {
            ZStack {
                if kind == .landfill {
                    SmokeCanvas(intensity: 0.5, color: Theme.murkGreen)
                        .frame(width: frame.width * 1.6, height: frame.height * 1.6)
                        .opacity(0.5)
                } else {
                    RisingSparksCanvas(color: Theme.freshGreen)
                        .frame(width: frame.width * 1.4, height: frame.height * 1.8)
                        .opacity(0.6)
                }

                Group {
                    if kind == .landfill {
                        TrashBinView(width: frame.width * 0.8, height: frame.height * 0.85)
                    } else {
                        RecycleBinView(width: frame.width * 0.8, height: frame.height * 0.85)
                    }
                }
                .overlay(
                    warning ?
                    RoundedRectangle(cornerRadius: 12).stroke(Theme.neonAmber, lineWidth: 3).opacity(0.85)
                        .frame(width: frame.width * 0.9, height: frame.height * 0.95)
                    : nil
                )
            }
            .frame(width: frame.width, height: frame.height)
            .glow(glowColor, radius: bright || warning ? 20 : 6, opacity: bright || warning ? 0.55 : (kind == .landfill ? 0.08 : 0.2))
            .scaleEffect(warning ? 1.035 : (bright ? 1.06 : 1))
            .animation(.easeInOut(duration: 0.25), value: bright)
            .animation(.easeInOut(duration: 0.18), value: warning)

            Text(label)
                .font(Theme.line(18))
                .foregroundStyle(.white.opacity(0.8))
                .shadow(color: .black.opacity(0.6), radius: 3)
        }
        .position(x: frame.midX, y: frame.midY)
    }

    private struct RisingSparksCanvas: View {
        var color: Color

        var body: some View {
            TimelineView(.animation(minimumInterval: 1.0 / 24)) { context in
                Canvas { ctx, size in
                    let t = context.date.timeIntervalSinceReferenceDate
                    for i in 0..<10 {
                        let cycle = 2.4 + rnd(i, 70) * 1.2
                        let phase = (t / cycle + rnd(i, 71)).truncatingRemainder(dividingBy: 1.0)
                        let x = size.width * rnd(i, 72)
                        let y = size.height * (1 - phase)
                        let r: CGFloat = 1.5 + rnd(i, 73) * 2
                        let fade = phase < 0.15 ? phase / 0.15 : 1 - (phase - 0.15) / 0.85
                        ctx.opacity = 0.15 + fade * 0.5
                        ctx.fill(Path(ellipseIn: CGRect(x: x - r / 2, y: y - r / 2, width: r, height: r)), with: .color(color))
                    }
                }
            }
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func stageContent(size: CGSize) -> some View {
        switch stage {
        case .arriving, .choosing:
            BottleView(vibrancy: game.vibrancy, dirt: game.grime, showEyes: false, width: 64, height: 156)
                .position(x: bottlePos.x * size.width, y: bottlePos.y * size.height)

        case .cleaning:
            let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                let elapsed = context.date.timeIntervalSince(stageStart)
                ZStack {
                    RinseRipples(elapsed: elapsed, center: center)
                    BottleView(
                        vibrancy: min(1, game.vibrancy + elapsed * 0.22),
                        dirt: max(0, game.grime - elapsed * 0.3),
                        showEyes: false, width: 64, height: 156
                    )
                    .position(center)
                }
                .onChange(of: elapsed) { _, v in if v > 3.4 { advance(to: .shredding) } }
            }

        case .shredding:
            let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                let elapsed = context.date.timeIntervalSince(stageStart)
                let shredProgress = min(1, elapsed / 1.6)
                ZStack {
                    BottleView(vibrancy: 1, dirt: 0, showEyes: false, width: 64, height: 156)
                        .position(center)
                        .opacity(1 - shredProgress)
                    FlakeField(
                        count: 80, scatterCenter: center, scatterRadius: 130,
                        target: Array(repeating: center, count: 80),
                        mix: 1 - shredProgress, color: Theme.bottleBlue, opacity: shredProgress
                    )
                }
                .onChange(of: elapsed) { _, v in if v > 3.2 { advance(to: .reforming) } }
            }

        case .reforming:
            let origin = CGPoint(x: size.width * 0.5 - size.width * 0.16, y: size.height * 0.42)
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                let elapsed = context.date.timeIntervalSince(stageStart)
                let mix = min(1, elapsed / 3.0)
                let targets = benchTargetPoints(count: 80, width: size.width * 0.32, height: size.height * 0.32, origin: origin)
                ZStack {
                    FlakeField(
                        count: 80, scatterCenter: CGPoint(x: size.width * 0.5, y: size.height * 0.5),
                        scatterRadius: 130,
                        target: targets, mix: mix, color: Theme.freshGreen.opacity(0.9), opacity: 1 - max(0, mix - 0.85) / 0.15
                    )
                    BenchView(width: size.width * 0.45, height: size.height * 0.18)
                        .position(x: origin.x + size.width * 0.16, y: origin.y + size.height * 0.16)
                        .opacity(max(0, (mix - 0.85) / 0.15))
                }
                .onChange(of: elapsed) { _, v in
                    if v > 1.2 && brighten < 1 { withAnimation(.easeInOut(duration: 2)) { brighten = 1 } }
                    if v > 3.6 { advance(to: .done) }
                }
            }

        case .done:
            BenchView(width: size.width * 0.45, height: size.height * 0.18)
                .position(x: size.width * 0.5, y: size.height * 0.58)
                .glow(Theme.freshGreen, radius: 20, opacity: 0.4)
        }
    }

    private func setup() {
        stage = .arriving
        stageStart = Date()
        bottlePos = CGPoint(x: 0.5, y: 0.22)
        dragBase = bottlePos
        misses = 0
        wrongDropFeedback = false
        showBenchCaption = false
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.6))
            guard stage == .arriving else { return }
            stage = .choosing
        }
    }

    private func evaluateDrop() {
        dragBase = bottlePos
        if recyclingRect.contains(bottlePos) {
            succeed()
        } else if landfillRect.contains(bottlePos) {
            misses += 1
            game.registerBinMiss()
            withAnimation(.easeOut(duration: 0.35)) {
                bottlePos = CGPoint(x: 0.5, y: 0.22)
                wrongDropFeedback = true
            }
            dragBase = bottlePos
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.6))
                guard stage == .choosing else { return }
                withAnimation(.easeOut(duration: 0.25)) { wrongDropFeedback = false }
            }
        }
    }

    private func succeed() {
        guard stage == .choosing else { return }
        game.sound.impactThud()
        advance(to: .cleaning)
    }

    private func advance(to next: Stage) {
        guard stage != next else { return }
        stage = next
        stageStart = Date()
        if next == .done {
            withAnimation(.easeIn(duration: 0.3)) { showBenchCaption = true }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(5.5))
                game.finishRecycling()
            }
        }
    }
}

struct RinseRipples: View {
    var elapsed: Double
    var center: CGPoint

    var body: some View {
        Canvas { ctx, size in
            for i in 0..<3 {
                let delay = Double(i) * 0.5
                let t = elapsed - delay
                guard t > 0 else { continue }
                let radius = CGFloat(t * 70).truncatingRemainder(dividingBy: 220)
                let opacity = max(0, 0.5 - Double(radius) / 220 * 0.5)
                ctx.stroke(
                    Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius * 0.5, width: radius * 2, height: radius)),
                    with: .color(Theme.cleanCyan.opacity(opacity)), lineWidth: 2
                )
            }
        }
    }
}

struct FlakeField: View {
    var count: Int
    var scatterCenter: CGPoint
    var scatterRadius: CGFloat
    var target: [CGPoint]
    var mix: Double
    var color: Color
    var opacity: Double

    var body: some View {
        Canvas { ctx, _ in
            guard count > 0 else { return }
            for i in 0..<count {
                let angle = Double(rnd(i, 90)) * 2 * .pi
                let radius = Double(rnd(i, 91)) * Double(scatterRadius)
                let scatterPoint = CGPoint(
                    x: scatterCenter.x + CGFloat(cos(angle) * radius),
                    y: scatterCenter.y + CGFloat(sin(angle) * radius)
                )
                let t = target[i % max(target.count, 1)]
                let x = scatterPoint.x + (t.x - scatterPoint.x) * CGFloat(mix)
                let y = scatterPoint.y + (t.y - scatterPoint.y) * CGFloat(mix)
                let flakeSize: CGFloat = 4 + rnd(i, 92) * 5
                let rect = CGRect(x: x - flakeSize / 2, y: y - flakeSize / 2, width: flakeSize, height: flakeSize * 0.6)
                ctx.opacity = opacity
                ctx.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(color))
            }
        }
    }
}

private struct RectSpec {
    let x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat
}

private let benchRectSpecs: [RectSpec] = [
    RectSpec(x: 0.15, y: 0.0, w: 0.09, h: 1.0),
    RectSpec(x: 0.76, y: 0.0, w: 0.09, h: 1.0),
    RectSpec(x: 0.0,  y: 0.52, w: 1.0,  h: 0.16),
    RectSpec(x: 0.08, y: 0.06, w: 0.84, h: 0.14),
    RectSpec(x: 0.08, y: 0.26, w: 0.84, h: 0.14),
]

struct BenchView: View {
    var width: CGFloat
    var height: CGFloat

    private let supportDark  = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let supportLight = Color(red: 0.22, green: 0.22, blue: 0.24)

    private let plankLight = Color(red: 0.46, green: 0.33, blue: 0.26)
    private let plankDark  = Color(red: 0.30, green: 0.19, blue: 0.14)

    private let speckleColors: [Color] = [
        Theme.bottleBlue, Theme.cleanCyan, Theme.freshGreen, Theme.neonAmber, .white
    ]

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height

            let supportGrad = Gradient(colors: [supportLight, supportDark])
            let plankGrad   = Gradient(colors: [plankLight, plankDark])

            drawTrapezoid(ctx: ctx, w: w, h: h,
                          bL: 0.15, bR: 0.24, tL: 0.17, tR: 0.22,
                          gradient: supportGrad)
            drawTrapezoid(ctx: ctx, w: w, h: h,
                          bL: 0.76, bR: 0.85, tL: 0.78, tR: 0.83,
                          gradient: supportGrad)

            let seatRect = CGRect(x: 0.0 * w, y: 0.50 * h,
                                  width: 1.0 * w, height: 0.16 * h)
            drawPlank(ctx: ctx, rect: seatRect, gradient: plankGrad, cr: 3, seed: 500)

            let topSlat = CGRect(x: 0.08 * w, y: 0.04 * h,
                                 width: 0.84 * w, height: 0.14 * h)
            drawPlank(ctx: ctx, rect: topSlat, gradient: plankGrad, cr: 2.5, seed: 600)

            let botSlat = CGRect(x: 0.08 * w, y: 0.24 * h,
                                 width: 0.84 * w, height: 0.14 * h)
            drawPlank(ctx: ctx, rect: botSlat, gradient: plankGrad, cr: 2.5, seed: 700)
        }
        .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 3)
        .frame(width: width, height: height)
    }

    private func drawTrapezoid(ctx: GraphicsContext, w: CGFloat, h: CGFloat,
                               bL: CGFloat, bR: CGFloat,
                               tL: CGFloat, tR: CGFloat,
                               gradient: Gradient) {
        var path = Path()
        path.move(to:    CGPoint(x: bL * w, y: h))
        path.addLine(to: CGPoint(x: tL * w, y: 0))
        path.addLine(to: CGPoint(x: tR * w, y: 0))
        path.addLine(to: CGPoint(x: bR * w, y: h))
        path.closeSubpath()

        ctx.fill(path, with: .linearGradient(gradient,
            startPoint: CGPoint(x: 0, y: 0),
            endPoint:   CGPoint(x: 0, y: h)))
        ctx.stroke(path, with: .color(.white.opacity(0.10)), lineWidth: 0.8)
    }

    private func drawPlank(ctx: GraphicsContext, rect: CGRect,
                           gradient: Gradient, cr: CGFloat, seed: Int) {
        let rr = Path(roundedRect: rect, cornerRadius: cr)

        ctx.fill(rr, with: .linearGradient(gradient,
            startPoint: CGPoint(x: 0, y: rect.minY),
            endPoint:   CGPoint(x: 0, y: rect.maxY)))
        ctx.stroke(rr, with: .color(.white.opacity(0.30)), lineWidth: 1.0)

        let count = max(6, Int(rect.width * rect.height / 80))
        for i in 0..<count {
            let sx = rect.minX + rnd(i, seed)     * rect.width
            let sy = rect.minY + rnd(i, seed + 1) * rect.height
            let sr: CGFloat = 0.5 + rnd(i, seed + 2) * 1.2
            let speckle = Path(ellipseIn: CGRect(x: sx - sr, y: sy - sr,
                                                  width: sr * 2, height: sr * 2))
            if rect.contains(CGPoint(x: sx, y: sy)) {
                let opacity = 0.16 + rnd(i, seed + 3) * 0.22
                let baseColor = speckleColors[i % speckleColors.count]
                ctx.fill(speckle, with: .color(baseColor.opacity(opacity)))
            }
        }
    }
}

private struct PlasticSpeckleCanvas: View {
    var body: some View { Color.clear }
}

func benchTargetPoints(count: Int, width: CGFloat, height: CGFloat, origin: CGPoint) -> [CGPoint] {
    let rects = benchRectSpecs
    let areas = rects.map { $0.w * $0.h }
    let total = areas.reduce(0, +)
    var cumulative: [CGFloat] = []
    var running: CGFloat = 0
    for a in areas {
        running += a / total
        cumulative.append(running)
    }

    return (0..<count).map { i in
        let pick = rnd(i, 100)
        let index = cumulative.firstIndex(where: { pick <= $0 }) ?? rects.count - 1
        let r = rects[index]
        let lx = r.x + rnd(i, 101) * r.w
        let ly = r.y + rnd(i, 102) * r.h
        return CGPoint(x: origin.x + lx * width, y: origin.y + ly * height)
    }
}

