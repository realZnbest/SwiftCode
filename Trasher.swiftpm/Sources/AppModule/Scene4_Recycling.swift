import SwiftUI

/// 35-45s. A glowing recycling facility: drag the bottle into the right
/// bin, then watch it get rinsed, shredded into flakes, and re-formed into
/// a park bench while the world brightens.
struct RecyclingScene: View {
    @EnvironmentObject var game: GameState

    private enum Stage { case arriving, choosing, cleaning, shredding, reforming, done }

    @State private var stage: Stage = .arriving
    @State private var stageStart = Date()
    @State private var bottlePos = CGPoint(x: 0.5, y: 0.22)
    @State private var dragBase = CGPoint(x: 0.5, y: 0.22)
    @State private var misses = 0
    @State private var idleTask: Task<Void, Never>? = nil
    @State private var brighten: Double = 0

    private var reduceMotion: Bool { game.reduceMotion }

    private let landfillRect = CGRect(x: 0.08, y: 0.55, width: 0.30, height: 0.3)
    private let recyclingRect = CGRect(x: 0.62, y: 0.55, width: 0.30, height: 0.3)

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                background(brighten: brighten)

                machineryGlow(size: size)

                if stage == .choosing || stage == .arriving {
                    binView(rect: landfillRect, size: size, tint: .gray, systemImage: "trash.fill", bright: false)
                    binView(rect: recyclingRect, size: size, tint: Theme.cleanCyan,
                            systemImage: "arrow.3.trianglepath", bright: misses > 0)
                }

                stageContent(size: size)

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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(stage == .choosing
            ? "Recycling facility. Drag the bottle into the glowing recycling bin, not the trash bin."
            : "Recycling facility. The bottle is being cleaned and remade into a park bench.")
        .onAppear(perform: setup)
    }

    // MARK: Background

    private func background(brighten: Double) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    Theme.deepNavy.mix(with: Theme.cleanWhite, amount: brighten * 0.35),
                    Theme.nearBlack.mix(with: Theme.freshGreen, amount: brighten * 0.15)
                ],
                startPoint: .top, endPoint: .bottom
            )
            NeonStreakField(colors: [Theme.cleanCyan, Theme.freshGreen], reduceMotion: reduceMotion)
                .opacity(0.5 + brighten * 0.3)
            SparkleCanvas(count: Int(20 + brighten * 40), color: Theme.cleanWhite, reduceMotion: reduceMotion)
                .opacity(0.3 + brighten * 0.5)
        }
    }

    private func machineryGlow(size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 0.4 : 1.0 / 20)) { context in
            let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
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

    // MARK: Bins

    private func binView(rect: CGRect, size: CGSize, tint: Color, systemImage: String, bright: Bool) -> some View {
        let frame = CGRect(x: rect.minX * size.width, y: rect.minY * size.height,
                            width: rect.width * size.width, height: rect.height * size.height)
        return ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(tint.opacity(bright ? 0.22 : 0.12))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(tint.opacity(bright ? 0.9 : 0.4), lineWidth: bright ? 3 : 1.5))
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(tint.opacity(bright ? 1 : 0.6))
        }
        .frame(width: frame.width, height: frame.height)
        .position(x: frame.midX, y: frame.midY)
        .glow(tint, radius: bright ? 16 : 4, opacity: bright ? 0.5 : 0.1)
        .animation(.easeInOut(duration: 0.4), value: bright)
    }

    // MARK: Stage content

    @ViewBuilder
    private func stageContent(size: CGSize) -> some View {
        switch stage {
        case .arriving, .choosing:
            BottleView(vibrancy: game.vibrancy, dirt: game.grime, showEyes: false, width: 64, height: 156)
                .position(x: bottlePos.x * size.width, y: bottlePos.y * size.height)

        case .cleaning:
            let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
            TimelineView(.animation(minimumInterval: reduceMotion ? 0.3 : 1.0 / 30)) { context in
                let elapsed = context.date.timeIntervalSince(stageStart)
                ZStack {
                    RinseRipples(elapsed: elapsed, center: center, reduceMotion: reduceMotion)
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
            TimelineView(.animation(minimumInterval: reduceMotion ? 0.3 : 1.0 / 30)) { context in
                let elapsed = context.date.timeIntervalSince(stageStart)
                // shredProgress: 0 = still a whole bottle, 1 = fully scattered flakes.
                let shredProgress = min(1, elapsed / 1.6)
                ZStack {
                    BottleView(vibrancy: 1, dirt: 0, showEyes: false, width: 64, height: 156)
                        .position(center)
                        .opacity(1 - shredProgress)
                    // FlakeField's `mix` of 1 means "at target" (clustered at center),
                    // so we count it down as shredProgress rises to fly the flakes outward.
                    FlakeField(
                        count: 80, scatterCenter: center, scatterRadius: reduceMotion ? 40 : 130,
                        target: Array(repeating: center, count: 80),
                        mix: 1 - shredProgress, color: Theme.bottleBlue, opacity: shredProgress
                    )
                }
                .onChange(of: elapsed) { _, v in if v > 3.2 { advance(to: .reforming) } }
            }

        case .reforming:
            let origin = CGPoint(x: size.width * 0.5 - size.width * 0.16, y: size.height * 0.42)
            TimelineView(.animation(minimumInterval: reduceMotion ? 0.3 : 1.0 / 30)) { context in
                let elapsed = context.date.timeIntervalSince(stageStart)
                let mix = min(1, elapsed / 3.0)
                let targets = benchTargetPoints(count: 80, width: size.width * 0.32, height: size.height * 0.32, origin: origin)
                ZStack {
                    FlakeField(
                        count: 80, scatterCenter: CGPoint(x: size.width * 0.5, y: size.height * 0.5),
                        scatterRadius: reduceMotion ? 40 : 130,
                        target: targets, mix: mix, color: Theme.freshGreen.opacity(0.9), opacity: 1 - max(0, mix - 0.85) / 0.15
                    )
                    BenchView(width: size.width * 0.32, height: size.height * 0.32)
                        .position(x: origin.x + size.width * 0.16, y: origin.y + size.height * 0.16)
                        .opacity(max(0, (mix - 0.85) / 0.15))
                }
                .onChange(of: elapsed) { _, v in
                    if v > 1.2 && brighten < 1 { withAnimation(.easeInOut(duration: 2)) { brighten = 1 } }
                    if v > 3.6 { advance(to: .done) }
                }
            }

        case .done:
            BenchView(width: size.width * 0.32, height: size.height * 0.32)
                .position(x: size.width * 0.5, y: size.height * 0.58)
                .glow(Theme.freshGreen, radius: 20, opacity: 0.4)
        }
    }

    // MARK: Flow control

    private func setup() {
        stage = .arriving
        stageStart = Date()
        bottlePos = CGPoint(x: 0.5, y: 0.22)
        dragBase = bottlePos
        misses = 0
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.6))
            guard stage == .arriving else { return }
            stage = .choosing
            armIdleAutoAdvance()
        }
    }

    private func armIdleAutoAdvance() {
        idleTask?.cancel()
        idleTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(9))
            guard !Task.isCancelled, stage == .choosing else { return }
            withAnimation(.easeInOut(duration: 0.8)) {
                bottlePos = CGPoint(x: recyclingRect.midX, y: recyclingRect.midY)
            }
            try? await Task.sleep(for: .seconds(0.85))
            succeed()
        }
    }

    private func evaluateDrop() {
        dragBase = bottlePos
        if recyclingRect.contains(bottlePos) {
            succeed()
        } else if landfillRect.contains(bottlePos) {
            misses += 1
            game.registerBinMiss()
            withAnimation(.spring()) { bottlePos = CGPoint(x: 0.5, y: 0.22) }
            dragBase = bottlePos
            if misses >= 2 {
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.6))
                    guard stage == .choosing else { return }
                    withAnimation(.easeInOut(duration: 0.8)) {
                        bottlePos = CGPoint(x: recyclingRect.midX, y: recyclingRect.midY)
                    }
                    try? await Task.sleep(for: .seconds(0.85))
                    succeed()
                }
            }
        }
    }

    private func succeed() {
        guard stage == .choosing else { return }
        idleTask?.cancel()
        game.sound.impactThud()
        advance(to: .cleaning)
    }

    private func advance(to next: Stage) {
        guard stage != next else { return }
        stage = next
        stageStart = Date()
        if next == .done {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.6))
                game.finishRecycling()
            }
        }
    }
}

// MARK: - Reusable pieces

struct RinseRipples: View {
    var elapsed: Double
    var center: CGPoint
    var reduceMotion: Bool

    var body: some View {
        Canvas { ctx, size in
            guard !reduceMotion else { return }
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

/// A simple, stylized park-bench silhouette used both at the end of the
/// recycling scene and again in the closing park scene.
struct BenchView: View {
    var width: CGFloat
    var height: CGFloat

    var body: some View {
        ZStack {
            benchShape(RectSpec(x: 0.0, y: 0.5, w: 1.0, h: 0.1))
            benchShape(RectSpec(x: 0.72, y: 0.06, w: 0.10, h: 0.46))
            benchShape(RectSpec(x: 0.06, y: 0.6, w: 0.08, h: 0.35))
            benchShape(RectSpec(x: 0.80, y: 0.6, w: 0.08, h: 0.35))
        }
        .frame(width: width, height: height)
    }

    private func benchShape(_ r: RectSpec) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(
                LinearGradient(colors: [Color(red: 0.55, green: 0.4, blue: 0.24), Color(red: 0.36, green: 0.25, blue: 0.14)],
                               startPoint: .top, endPoint: .bottom)
            )
            .frame(width: r.w * width, height: r.h * height)
            .position(x: (r.x + r.w / 2) * width, y: (r.y + r.h / 2) * height)
    }
}

private struct RectSpec {
    let x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat
}

func benchTargetPoints(count: Int, width: CGFloat, height: CGFloat, origin: CGPoint) -> [CGPoint] {
    let rects: [RectSpec] = [
        RectSpec(x: 0.0, y: 0.5, w: 1.0, h: 0.1),
        RectSpec(x: 0.72, y: 0.06, w: 0.10, h: 0.46),
        RectSpec(x: 0.06, y: 0.6, w: 0.08, h: 0.35),
        RectSpec(x: 0.80, y: 0.6, w: 0.08, h: 0.35)
    ]
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
