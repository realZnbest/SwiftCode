import SwiftUI

/// 35-45s. A glowing recycling facility: drag the bottle into the right
/// bin, then watch it get rinsed, shredded into flakes, and re-formed into
/// a recycled-plastic park bench while the world brightens.
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
    @State private var wrongDropFeedback = false

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
                    binView(rect: landfillRect, size: size, kind: .landfill, bright: false, warning: wrongDropFeedback, reduceMotion: reduceMotion)
                    binView(rect: recyclingRect, size: size, kind: .recycling, bright: misses > 0, warning: false, reduceMotion: reduceMotion)
                }

                stageContent(size: size)

                if wrongDropFeedback && stage == .choosing {
                    Label("This bin keeps it buried. Try recycling.", systemImage: "exclamationmark.triangle.fill")
                        .font(Theme.line(16))
                        .foregroundStyle(Theme.neonAmber)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Theme.nearBlack.opacity(0.78), in: Capsule())
                        .position(x: size.width * 0.5, y: size.height * 0.44)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(stage == .choosing
            ? "Recycling facility. Drag the bottle into the glowing recycling bin, not the trash bin."
            : "Recycling facility. The bottle is being cleaned, shredded, and remade into a bench made of recycled plastic.")
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
            FactorySilhouetteCanvas()
                .opacity(0.7)
            LightRaysCanvas(color: Theme.cleanCyan, count: 3, reduceMotion: reduceMotion)
                .opacity(0.5 + brighten * 0.2)
            NeonStreakField(colors: [Theme.cleanCyan, Theme.freshGreen], reduceMotion: reduceMotion)
                .opacity(0.5 + brighten * 0.3)
            ConveyorBeltCanvas(reduceMotion: reduceMotion)
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

    private enum BinKind { case landfill, recycling }

    /// Each choice is a real illustrated object, not a bare icon in a
    /// translucent panel — a grimy overflowing dumpster you can tell is a
    /// dead end at a glance, next to a glowing bin that's obviously part of
    /// the machinery around it. The murky haze/upward sparks behind each one
    /// foreshadow what happens next, so the choice reads on sight.
    private func binView(rect: CGRect, size: CGSize, kind: BinKind, bright: Bool, warning: Bool, reduceMotion: Bool) -> some View {
        let frame = CGRect(x: rect.minX * size.width, y: rect.minY * size.height,
                            width: rect.width * size.width, height: rect.height * size.height)
        let glowColor = warning ? Theme.neonAmber : (kind == .landfill ? Theme.smokeOrange : Theme.cleanCyan)

        return ZStack {
            if kind == .landfill {
                SmokeCanvas(intensity: 0.5, color: Theme.murkGreen, reduceMotion: reduceMotion)
                    .frame(width: frame.width * 1.6, height: frame.height * 1.6)
                    .opacity(0.5)
            } else {
                RisingSparksCanvas(color: Theme.cleanCyan, reduceMotion: reduceMotion)
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
        .position(x: frame.midX, y: frame.midY)
        .glow(glowColor, radius: bright || warning ? 20 : 6, opacity: bright || warning ? 0.55 : (kind == .landfill ? 0.08 : 0.2))
        .scaleEffect(warning ? 1.035 : 1)
        .animation(.easeInOut(duration: 0.25), value: bright)
        .animation(.easeInOut(duration: 0.18), value: warning)
    }

    // MARK: - Bin illustrations

    /// Small motes drifting upward and fading — placed behind the recycling
    /// bin so it visibly leads onward/upward, the opposite of the landfill
    /// bin's low, sinking smoke.
    private struct RisingSparksCanvas: View {
        var color: Color
        var reduceMotion: Bool = false

        var body: some View {
            TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1.0 / 24)) { context in
                Canvas { ctx, size in
                    let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
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

    // MARK: Flow control

    private func setup() {
        stage = .arriving
        stageStart = Date()
        bottlePos = CGPoint(x: 0.5, y: 0.22)
        dragBase = bottlePos
        misses = 0
        wrongDropFeedback = false
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

private struct RectSpec {
    let x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat
}

/// A wide, front-on park-bench silhouette matching the classic recycled-
/// plastic lumber bench: two dark trapezoidal end supports (wider at
/// bottom, narrower at top) with brown seat plank overhanging both sides
/// and two brown backrest slats separated by a gap.
///
/// `benchRectSpecs` approximates the filled area for particle-target
/// distribution during the recycling animation; the actual drawing uses
/// trapezoids via Canvas for the supports.
private let benchRectSpecs: [RectSpec] = [
    // ── Left support (rectangle approximation of trapezoid) ──
    RectSpec(x: 0.15, y: 0.0, w: 0.09, h: 1.0),
    // ── Right support ──
    RectSpec(x: 0.76, y: 0.0, w: 0.09, h: 1.0),
    // ── Seat slab (thick, full-width, overhangs supports) ──
    RectSpec(x: 0.0,  y: 0.52, w: 1.0,  h: 0.16),
    // ── Top backrest slat ──
    RectSpec(x: 0.08, y: 0.06, w: 0.84, h: 0.14),
    // ── Bottom backrest slat ──
    RectSpec(x: 0.08, y: 0.26, w: 0.84, h: 0.14),
]

/// A park-bench silhouette used both at the end of the recycling scene and
/// again in the closing park scene. Drawn with Canvas so the end supports
/// can be proper trapezoids — the shape that immediately reads "bench" at
/// any scale. Two-tone: dark supports + warm brown planks with recycled-
/// plastic speckle effect.
struct BenchView: View {
    var width: CGFloat
    var height: CGFloat

    // Support colors (dark charcoal, like molded recycled HDPE)
    private let supportDark  = Color(red: 0.12, green: 0.12, blue: 0.14)
    private let supportLight = Color(red: 0.22, green: 0.22, blue: 0.24)

    // Plank colors (warm brown, like recycled plastic lumber)
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

            // ── 1. Trapezoidal end supports (drawn first, behind planks) ──
            // Left support: wider at bottom, narrower at top
            drawTrapezoid(ctx: ctx, w: w, h: h,
                          bL: 0.15, bR: 0.24, tL: 0.17, tR: 0.22,
                          gradient: supportGrad)
            // Right support (mirror)
            drawTrapezoid(ctx: ctx, w: w, h: h,
                          bL: 0.76, bR: 0.85, tL: 0.78, tR: 0.83,
                          gradient: supportGrad)

            // ── 2. Seat plank (thick, overhangs supports on both sides) ──
            let seatRect = CGRect(x: 0.0 * w, y: 0.50 * h,
                                  width: 1.0 * w, height: 0.16 * h)
            drawPlank(ctx: ctx, rect: seatRect, gradient: plankGrad, cr: 3, seed: 500)

            // ── 3. Backrest slats (two planks with a gap) ──
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

    /// Draws a trapezoid (wider at bottom, narrower at top) filled with a
    /// vertical linear gradient plus a subtle edge highlight.
    private func drawTrapezoid(ctx: GraphicsContext, w: CGFloat, h: CGFloat,
                               bL: CGFloat, bR: CGFloat,
                               tL: CGFloat, tR: CGFloat,
                               gradient: Gradient) {
        var path = Path()
        path.move(to:    CGPoint(x: bL * w, y: h))        // bottom-left
        path.addLine(to: CGPoint(x: tL * w, y: 0))        // top-left
        path.addLine(to: CGPoint(x: tR * w, y: 0))        // top-right
        path.addLine(to: CGPoint(x: bR * w, y: h))        // bottom-right
        path.closeSubpath()

        ctx.fill(path, with: .linearGradient(gradient,
            startPoint: CGPoint(x: 0, y: 0),
            endPoint:   CGPoint(x: 0, y: h)))
        // Subtle edge highlight for depth
        ctx.stroke(path, with: .color(.white.opacity(0.10)), lineWidth: 0.8)
    }

    /// Draws a rounded-rect plank with gradient fill, highlight stroke, and
    /// recycled-plastic speckle dots.
    private func drawPlank(ctx: GraphicsContext, rect: CGRect,
                           gradient: Gradient, cr: CGFloat, seed: Int) {
        let rr = Path(roundedRect: rect, cornerRadius: cr)

        // Fill
        ctx.fill(rr, with: .linearGradient(gradient,
            startPoint: CGPoint(x: 0, y: rect.minY),
            endPoint:   CGPoint(x: 0, y: rect.maxY)))
        // Highlight stroke for 3D sheen
        ctx.stroke(rr, with: .color(.white.opacity(0.30)), lineWidth: 1.0)

        // Recycled-plastic speckle dots (clipped to plank rect)
        let count = max(6, Int(rect.width * rect.height / 80))
        for i in 0..<count {
            let sx = rect.minX + rnd(i, seed)     * rect.width
            let sy = rect.minY + rnd(i, seed + 1) * rect.height
            let sr: CGFloat = 0.5 + rnd(i, seed + 2) * 1.2
            let speckle = Path(ellipseIn: CGRect(x: sx - sr, y: sy - sr,
                                                  width: sr * 2, height: sr * 2))
            // Only draw if inside the plank bounds
            if rect.contains(CGPoint(x: sx, y: sy)) {
                let opacity = 0.16 + rnd(i, seed + 3) * 0.22
                let baseColor = speckleColors[i % speckleColors.count]
                ctx.fill(speckle, with: .color(baseColor.opacity(opacity)))
            }
        }
    }
}

/// No longer needed as a separate view — speckles are drawn inline in
/// `BenchView.drawPlank`. Kept as a no-op so any stale references compile.
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

