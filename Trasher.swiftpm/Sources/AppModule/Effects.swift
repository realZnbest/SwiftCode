import SwiftUI

/// Deterministic, code-only atmosphere effects built on Canvas +
/// TimelineView. Every particle's position is a pure function of elapsed
/// time and its own index, so there is no mutable per-particle state to
/// juggle and reduced-motion just lowers counts / freezes motion.
func rnd(_ i: Int, _ salt: Int = 0) -> CGFloat { CGFloat(Theme.hash(i, salt)) }

struct RainCanvas: View {
    var intensity: Double = 1
    var reduceMotion: Bool = false

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : nil)) { context in
            Canvas { ctx, size in
                guard !reduceMotion else {
                    // Soft static wash instead of falling streaks.
                    ctx.fill(Path(CGRect(origin: .zero, size: size)),
                             with: .color(.white.opacity(0.02)))
                    return
                }
                let t = context.date.timeIntervalSinceReferenceDate
                let count = Int(150 * intensity)
                for i in 0..<count {
                    // `speed` is meant as points/second directly — an
                    // earlier `/ 1000` here (as if `t` were milliseconds,
                    // which it isn't; timeIntervalSinceReferenceDate is
                    // seconds) throttled every drop to ~1pt/s, so the rain
                    // was technically animating but imperceptibly frozen.
                    let speed = 900 + rnd(i, 1) * 500
                    let x = rnd(i, 2) * size.width
                    let span = size.height + 80
                    let y = (CGFloat(t) * speed + rnd(i, 3) * span).truncatingRemainder(dividingBy: span) - 40
                    let length: CGFloat = 12 + rnd(i, 4) * 10
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: y))
                    path.addLine(to: CGPoint(x: x - 2, y: y + length))
                    ctx.stroke(path, with: .color(.white.opacity(0.14 + rnd(i, 5) * 0.14)), lineWidth: 1.1)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct NeonStreakField: View {
    var colors: [Color]
    var reduceMotion: Bool = false

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 2 : nil)) { context in
            Canvas { ctx, size in
                let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
                let count = 10
                for i in 0..<count {
                    let color = colors[i % colors.count]
                    let x = rnd(i, 20) * size.width
                    let drift = reduceMotion ? 0 : sin(t * 0.15 + Double(i)) * 14
                    let w: CGFloat = 30 + rnd(i, 21) * 70
                    let h = size.height * (0.3 + rnd(i, 22) * 0.5)
                    let rect = CGRect(x: x + drift, y: size.height - h, width: w, height: h)
                    ctx.opacity = 0.18 + rnd(i, 23) * 0.16
                    ctx.fill(Path(roundedRect: rect, cornerRadius: w / 2), with: .color(color))
                }
            }
            .blur(radius: 34)
        }
        .allowsHitTesting(false)
    }
}

struct BubbleCanvas: View {
    var count: Int = 18
    var color: Color = .white
    var reduceMotion: Bool = false

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : nil)) { context in
            Canvas { ctx, size in
                let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
                for i in 0..<count {
                    let x = rnd(i, 30) * size.width + sin(t * 0.6 + Double(i)) * 8
                    let span = size.height + 40
                    let rise = reduceMotion ? rnd(i, 31) * span : (CGFloat(t) * (20 + rnd(i, 32) * 30)).truncatingRemainder(dividingBy: span)
                    let y = size.height - rise
                    let r = 2 + rnd(i, 33) * 5
                    ctx.opacity = 0.15 + rnd(i, 34) * 0.25
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)), with: .color(color))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct FishSilhouettesCanvas: View {
    var darkness: Double
    var reduceMotion: Bool = false

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 2 : nil)) { context in
            Canvas { ctx, size in
                let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
                let count = 5
                for i in 0..<count {
                    let dir: CGFloat = i.isMultiple(of: 2) ? 1 : -1
                    let speed = 26.0 + Double(rnd(i, 40)) * 18
                    let span = size.width + 140
                    let progress = reduceMotion ? Double(rnd(i, 41)) : (t * speed).truncatingRemainder(dividingBy: span)
                    let x = dir > 0 ? CGFloat(progress) - 70 : size.width - CGFloat(progress) + 70
                    let y = size.height * (0.25 + rnd(i, 42) * 0.5)
                    let scale = 0.6 + rnd(i, 43) * 0.7
                    var path = Path()
                    let w: CGFloat = 34 * scale * dir
                    let h: CGFloat = 12 * scale
                    // The body is drawn from the trailing edge (x) toward the
                    // leading edge (x + w, in the direction of travel), so
                    // the tail fin below must attach at the trailing edge —
                    // otherwise the fin reads as leading the body and the
                    // fish appears to swim tail-first.
                    path.move(to: CGPoint(x: x, y: y))
                    path.addQuadCurve(to: CGPoint(x: x + w, y: y), control: CGPoint(x: x + w * 0.5, y: y - h))
                    path.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: x + w * 0.5, y: y + h))
                    path.move(to: CGPoint(x: x, y: y))
                    path.addLine(to: CGPoint(x: x - 8 * dir, y: y - 6))
                    path.addLine(to: CGPoint(x: x - 8 * dir, y: y + 6))
                    path.closeSubpath()
                    ctx.fill(path, with: .color(.black.opacity(0.25 + darkness * 0.35)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct SmokeCanvas: View {
    var intensity: Double
    var color: Color
    var reduceMotion: Bool = false

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 2 : nil)) { context in
            Canvas { ctx, size in
                let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
                let count = Int(6 * intensity) + 2
                for i in 0..<count {
                    let baseX = rnd(i, 50) * size.width
                    let drift = reduceMotion ? 0 : sin(t * 0.2 + Double(i) * 1.3) * 30
                    let y = size.height * (0.5 + rnd(i, 51) * 0.4)
                    let r = 40 + rnd(i, 52) * 60
                    ctx.opacity = 0.10 * intensity + rnd(i, 53) * 0.05
                    ctx.fill(Path(ellipseIn: CGRect(x: baseX + drift - r / 2, y: y - r / 2, width: r, height: r * 0.6)),
                             with: .color(color))
                }
            }
            .blur(radius: 24)
        }
        .allowsHitTesting(false)
    }
}

/// A few fragments that leave the bottle during the canal close-up. They
/// deliberately drift beyond the frame instead of converging back, making
/// the microplastic consequence readable without adding a separate asset.
struct MicroplasticDrift: View {
    var elapsed: Double
    var center: CGPoint
    var reduceMotion: Bool = false

    var body: some View {
        Canvas { ctx, size in
            let t = reduceMotion ? 0.7 : min(max(elapsed / 3.8, 0), 1)
            for i in 0..<13 {
                let angle = Double(rnd(i, 140)) * 2 * .pi
                let distance = CGFloat(42 + rnd(i, 141) * 300) * CGFloat(t)
                let x = center.x + CGFloat(cos(angle)) * distance + CGFloat(t * t) * 90
                let y = center.y + CGFloat(sin(angle)) * distance * 0.55 - CGFloat(t) * 36
                let flakeSize: CGFloat = 3 + rnd(i, 142) * 5
                let rect = CGRect(x: x - flakeSize / 2, y: y - flakeSize / 2,
                                  width: flakeSize, height: flakeSize * 0.65)
                ctx.opacity = max(0, 0.68 - t * 0.26)
                ctx.fill(Path(roundedRect: rect, cornerRadius: 1),
                         with: .color(Theme.cleanWhite.opacity(0.86)))
            }
        }
        .allowsHitTesting(false)
    }
}

struct SparkleCanvas: View {
    var count: Int = 40
    var color: Color = .white
    var reduceMotion: Bool = false

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : nil)) { context in
            Canvas { ctx, size in
                let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
                for i in 0..<count {
                    let x = rnd(i, 60) * size.width
                    let y = rnd(i, 61) * size.height
                    let twinkle = 0.5 + 0.5 * sin(t * (1.2 + Double(rnd(i, 62))) + Double(i))
                    let r = 1 + rnd(i, 63) * 2.2
                    ctx.opacity = 0.15 + twinkle * 0.5
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)), with: .color(color))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// Soft radial darkening toward the frame edges to keep focus on the bottle.
struct Vignette: View {
    var strength: Double = 0.55

    var body: some View {
        RadialGradient(
            colors: [.clear, Theme.nearBlack.opacity(strength)],
            center: .center,
            startRadius: 220,
            endRadius: 620
        )
        .allowsHitTesting(false)
    }
}

/// A tapered dumpster-style body, wider at the rim than the base — shared
/// by both bin illustrations so they read as the same family of object,
/// just finished very differently. Also reused (below) at every branching
/// choice in the game, so a "landfill" or "recycling" outcome always looks
/// like this same object, not a different improvised icon per scene.
struct BinBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        let inset = rect.width * 0.12
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + inset, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// A grimy, overflowing dumpster — dull metal, jammed with mismatched junk
/// poking over the rim, so "landfill" reads as a dead end before you even
/// drop anything in. Used both at the recycling facility's bin choice and
/// at the earlier street/canal forks, so every "wrong turn" in the game
/// looks like this same object.
struct TrashBinView: View {
    var width: CGFloat
    var height: CGFloat

    var body: some View {
        ZStack {
            HStack(spacing: width * 0.05) {
                ForEach(0..<4, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill([Theme.murkBrown, Theme.smokeOrange, Color.gray, Theme.murkGreen][i % 4].opacity(0.85))
                        .frame(width: width * 0.15, height: width * (0.12 + CGFloat(i % 3) * 0.05))
                        .rotationEffect(.degrees(Double(i) * 11 - 16))
                }
            }
            .offset(y: -height * 0.32)

            BinBodyShape()
                .fill(LinearGradient(colors: [Color(red: 0.32, green: 0.30, blue: 0.28), Color(red: 0.15, green: 0.14, blue: 0.13)],
                                      startPoint: .top, endPoint: .bottom))
                .overlay(BinBodyShape().stroke(Color.black.opacity(0.4), lineWidth: 1.5))
                .frame(width: width, height: height * 0.62)
                .offset(y: height * 0.19)

            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.22, green: 0.20, blue: 0.19))
                .frame(width: width * 1.05, height: height * 0.07)
                .offset(y: -height * 0.12)

            Image(systemName: "trash.fill")
                .font(.system(size: width * 0.26, weight: .medium))
                .foregroundStyle(.white.opacity(0.3))
                .offset(y: height * 0.2)
        }
        .frame(width: width, height: height)
    }
}

/// A clean, glowing bin that reads as active machinery, not a static panel
/// — an open, tilted lid with the universal recycling arrows glowing
/// inside it. Used both at the recycling facility and at the earlier
/// street/canal forks, so every "leads onward" outcome looks like this
/// same object.
struct RecycleBinView: View {
    var width: CGFloat
    var height: CGFloat

    var body: some View {
        ZStack {
            BinBodyShape()
                .fill(LinearGradient(colors: [Theme.freshGreen.opacity(0.32), Theme.freshGreen.opacity(0.1)],
                                      startPoint: .top, endPoint: .bottom))
                .overlay(BinBodyShape().stroke(Theme.freshGreen.opacity(0.85), lineWidth: 2))
                .frame(width: width, height: height * 0.62)
                .offset(y: height * 0.19)

            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.freshGreen.opacity(0.55))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Theme.freshGreen, lineWidth: 1.5))
                .frame(width: width * 1.05, height: height * 0.08)
                .rotationEffect(.degrees(-8), anchor: .leading)
                .offset(x: -width * 0.02, y: -height * 0.15)

            Image(systemName: "arrow.3.trianglepath")
                .font(.system(size: width * 0.3, weight: .semibold))
                .foregroundStyle(Theme.freshGreen)
                .offset(y: height * 0.2)
        }
        .frame(width: width, height: height)
    }
}

/// What a branching choice leads to — landfill and recycling reuse the
/// exact bin illustrations from the facility scene, so every occurrence of
/// the same outcome looks identical; storm drain and sea get their own
/// glyphs built at the same size and material language (gradient fill,
/// stroke, drop shadow) so nothing reads as a lower-effort placeholder.
enum PathKind {
    case landfill, stormDrain, sea, recyclingPoint

    var tint: Color {
        switch self {
        case .landfill: return Theme.smokeOrange
        case .stormDrain: return Theme.neonCyan
        case .sea: return Theme.mutedSeaTeal
        case .recyclingPoint: return Theme.freshGreen
        }
    }

    /// A short caption under the glyph — the illustrations read fine once
    /// you already know the story, but a judge seeing this cold shouldn't
    /// have to guess what a drain grate versus a wave crest means.
    var label: String {
        switch self {
        case .landfill: return "Landfill"
        case .stormDrain: return "Storm drain"
        // "Open sea" read as neutral, even pleasant — this is the bad,
        // dead-end choice (mirrors "Trash bin"), so the label should say so.
        case .sea: return "Lost at sea"
        case .recyclingPoint: return "Recycling"
        }
    }
}

/// A glowing waypoint used at every branching choice in the game (the
/// canal fork, the drain fork). `bright` marks the side the player is
/// currently leaning/dragging toward; `dim` marks a route the story has
/// temporarily closed off (e.g. after one detour already used).
///
/// `containerSize` is the fork scene's own GeometryReader size, and the
/// glyph is sized as a fraction of it — the same proportion the recycling
/// facility uses for its bins (`0.30 * size` framing an `0.8`-scaled bin) —
/// instead of a fixed point size, so this reads exactly as large and
/// prominent at every fork as the facility's bins do, not as a shrunken
/// stand-in.
struct PathChoiceIndicator: View {
    var kind: PathKind
    var bright: Bool
    var dim: Bool = false
    var containerSize: CGSize
    var showLabel: Bool = true

    private var glyphWidth: CGFloat { containerSize.width * 0.24 }
    private var glyphHeight: CGFloat { containerSize.height * 0.26 }

    var body: some View {
        VStack(spacing: 6) {
            glyph
                .frame(width: glyphWidth, height: glyphHeight)
                .opacity(bright ? 1 : 0.7)
                .scaleEffect(bright ? 1.06 : 1)
                .animation(.easeInOut(duration: 0.4), value: bright)

            if showLabel {
                Text(kind.label)
                    .font(Theme.line(18))
                    .foregroundStyle(.white.opacity(0.8))
                    .shadow(color: .black.opacity(0.6), radius: 3)
            }
        }
        .opacity(dim ? 0.25 : 1)
    }

    @ViewBuilder
    private var glyph: some View {
        switch kind {
        case .landfill: LandfillMoundGlyph(bright: bright, size: max(glyphWidth, glyphHeight))
        case .stormDrain: StormDrainGlyph(bright: bright, size: max(glyphWidth, glyphHeight))
        case .sea: SeaGlyph(bright: bright, size: max(glyphWidth, glyphHeight))
        case .recyclingPoint: RecycleBinView(width: glyphWidth, height: glyphHeight)
        }
    }
}

/// A cross-section of a landfill mound — layered dirt strata with a bottle
/// half-buried in one of the layers — not a trash bin. This is the street
/// fork's "wrong turn" choice, and the scene it leads to says "Buried is
/// not gone": a bin (something you'd empty) undersold that permanence, so
/// this reads as ground the bottle disappears *into*, not a container.
private struct LandfillMoundGlyph: View {
    var bright: Bool
    var size: CGFloat

    var body: some View {
        Canvas { ctx, canvasSize in
            let s = min(canvasSize.width, canvasSize.height)
            let baseY = s * 0.9
            let topY = s * 0.22
            let midX = s * 0.5
            let baseHalf = s * 0.42
            let topHalf = s * 0.11

            // A pyramid's proportions (wide base, narrow top) built from
            // jittered points instead of straight edges, so the silhouette
            // reads as a heaped dirt pile, not a ruler-drawn shape.
            func jaggedEdge(from: CGPoint, to: CGPoint, steps: Int, seed: Int) -> [CGPoint] {
                (0...steps).map { i in
                    let t = CGFloat(i) / CGFloat(steps)
                    let x = from.x + (to.x - from.x) * t
                    let y = from.y + (to.y - from.y) * t
                    guard i != 0 && i != steps else { return CGPoint(x: x, y: y) }
                    let jx = (rnd(seed + i, 640) - 0.5) * s * 0.07
                    let jy = (rnd(seed + i, 641) - 0.5) * s * 0.045
                    return CGPoint(x: x + jx, y: y + jy)
                }
            }

            let left = jaggedEdge(from: CGPoint(x: midX - baseHalf, y: baseY), to: CGPoint(x: midX - topHalf, y: topY), steps: 5, seed: 10)
            let top = jaggedEdge(from: CGPoint(x: midX - topHalf, y: topY), to: CGPoint(x: midX + topHalf, y: topY), steps: 3, seed: 30)
            let right = jaggedEdge(from: CGPoint(x: midX + topHalf, y: topY), to: CGPoint(x: midX + baseHalf, y: baseY), steps: 5, seed: 50)

            var mound = Path()
            mound.move(to: left[0])
            for p in left.dropFirst() { mound.addLine(to: p) }
            for p in top.dropFirst() { mound.addLine(to: p) }
            for p in right.dropFirst() { mound.addLine(to: p) }
            mound.closeSubpath()

            ctx.fill(mound, with: .color(Color(red: 0.3, green: 0.22, blue: 0.14)))

            var clipped = ctx
            clipped.clip(to: mound)

            // Strata bands follow the mound's own taper (jittered, not flat
            // shelves), instead of uniform-width stacked rectangles that
            // read as drawers.
            let bandColors: [Color] = [
                Color(red: 0.38, green: 0.29, blue: 0.18),
                Color(red: 0.27, green: 0.2, blue: 0.12),
                Color(red: 0.2, green: 0.14, blue: 0.08)
            ]
            for (i, color) in bandColors.enumerated() {
                let bandT = CGFloat(i + 1) / CGFloat(bandColors.count + 1)
                let y = baseY + (topY - baseY) * bandT
                var band = Path()
                for j in 0...6 {
                    let t = CGFloat(j) / 6
                    let x = midX - baseHalf + baseHalf * 2 * t
                    let jitter = (rnd(i * 10 + j, 660) - 0.5) * s * 0.035
                    let pt = CGPoint(x: x, y: y + jitter)
                    if j == 0 { band.move(to: pt) } else { band.addLine(to: pt) }
                }
                clipped.stroke(band, with: .color(color.opacity(0.85)), lineWidth: s * 0.05)
            }

            // Debris flecks scattered through the mound.
            for i in 0..<8 {
                let x = midX - baseHalf * 0.6 + rnd(i, 700) * baseHalf * 1.2
                let y = baseY - rnd(i, 701) * (baseY - topY) * 0.8
                let r = s * 0.02
                clipped.fill(Path(ellipseIn: CGRect(x: x - r / 2, y: y - r / 2, width: r, height: r)), with: .color(.black.opacity(0.3)))
            }

            // The bottle, half-swallowed partway up — the whole point of
            // the icon.
            var bottleLayer = clipped
            bottleLayer.translateBy(x: midX + s * 0.02, y: baseY - (baseY - topY) * 0.5)
            bottleLayer.rotate(by: .degrees(14))
            let bottlePath = Path(roundedRect: CGRect(x: -s * 0.05, y: -s * 0.12, width: s * 0.1, height: s * 0.24), cornerRadius: s * 0.03)
            bottleLayer.fill(bottlePath, with: .color(Theme.bottleBlue.opacity(bright ? 0.9 : 0.65)))
        }
        .frame(width: size, height: size)
    }
}

/// A drain grate over a dark opening — reads as "down and gone" at a
/// glance, the opposite of the recycling bin's open, upward glow. Built at
/// the same size and gradient/stroke/shadow language as the bins so it
/// doesn't read as a lower-effort placeholder next to them.
private struct StormDrainGlyph: View {
    var bright: Bool
    var size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(RadialGradient(colors: [Color.black.opacity(0.9), Theme.deepNavy.opacity(0.6)],
                                      center: .center, startRadius: 0, endRadius: size * 0.5))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.5), lineWidth: 1.5))
                .frame(width: size * 0.82, height: size * 0.6)
                .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 3)
            VStack(spacing: size * 0.09) {
                ForEach(0..<4, id: \.self) { _ in
                    Capsule()
                        .fill(Theme.neonCyan.opacity(bright ? 1 : 0.65))
                        .frame(width: size * 0.66, height: size * 0.045)
                        .overlay(Capsule().stroke(Theme.neonCyan.opacity(bright ? 0.6 : 0.3), lineWidth: 0.5))
                }
            }
        }
        .frame(width: size, height: size)
    }
}

/// Stacked wave crests — the sea path, distinct from the drain's straight
/// bars so the two "down and gone" routes (landfill, sea) don't blur
/// together visually across scenes. Same size/shadow language as the bins.
private struct SeaGlyph: View {
    var bright: Bool
    var size: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                WaveCrestShape()
                    .fill(
                        LinearGradient(
                            colors: [Theme.mutedSeaTeal.opacity(bright ? 1 : 0.75), Theme.mutedSeaTeal.opacity(bright ? 0.6 : 0.4)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .overlay(WaveCrestShape().stroke(Color.white.opacity(bright ? 0.35 : 0.18), lineWidth: 1))
                    .frame(width: size * 0.78, height: size * 0.2)
                    .offset(y: CGFloat(i) * size * 0.19 - size * 0.16)
                    .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 2)
            }
        }
        .frame(width: size, height: size)
    }
}

private struct WaveCrestShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control1: CGPoint(x: rect.width * 0.28, y: rect.minY),
            control2: CGPoint(x: rect.width * 0.72, y: rect.maxY)
        )
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct GlowOrb: View {
    var color: Color
    var size: CGFloat

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: size * 0.5)
            .opacity(0.7)
    }
}

/// Soft diagonal light shafts — sunbeams through canal water, or shafts of
/// facility light — that sway gently rather than sitting static.
struct LightRaysCanvas: View {
    var color: Color
    var count: Int = 4
    var reduceMotion: Bool = false

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 2 : 1.0 / 20)) { context in
            Canvas { ctx, size in
                let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
                for i in 0..<count {
                    let baseX = (rnd(i, 300) * 0.8 + 0.1) * size.width
                    let sway = reduceMotion ? 0 : sin(t * 0.18 + Double(i) * 1.7) * 24
                    let width: CGFloat = 46 + rnd(i, 301) * 60
                    let tilt: CGFloat = 26 + rnd(i, 302) * 22

                    var path = Path()
                    path.move(to: CGPoint(x: baseX + sway, y: -20))
                    path.addLine(to: CGPoint(x: baseX + sway + width, y: -20))
                    path.addLine(to: CGPoint(x: baseX + sway + width - tilt, y: size.height))
                    path.addLine(to: CGPoint(x: baseX + sway - tilt, y: size.height))
                    path.closeSubpath()

                    ctx.fill(path, with: .linearGradient(
                        Gradient(colors: [color.opacity(0.14 + rnd(i, 303) * 0.08), .clear]),
                        startPoint: CGPoint(x: baseX, y: -20),
                        endPoint: CGPoint(x: baseX, y: size.height * 0.85)
                    ))
                }
            }
            .blur(radius: 10)
        }
        .allowsHitTesting(false)
    }
}

/// Soft drifting cloud clusters for the daylight park ending.
struct CloudDriftCanvas: View {
    var reduceMotion: Bool = false

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 3 : 1.0 / 12)) { context in
            Canvas { ctx, size in
                let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
                for i in 0..<5 {
                    let speed = 5.0 + Double(rnd(i, 320)) * 4
                    let span = size.width + 320
                    let travel = reduceMotion ? rnd(i, 321) * span : CGFloat((t * speed).truncatingRemainder(dividingBy: Double(span)))
                    let x = travel - 160
                    let y = size.height * (0.06 + rnd(i, 322) * 0.22)
                    let w = 120 + rnd(i, 323) * 110
                    for puff in 0..<4 {
                        let puffX = x + CGFloat(puff) * w * 0.28
                        let puffW = w * (0.5 + rnd(i * 7 + puff, 324) * 0.4)
                        // Volume shading: a cooler, dimmer underside beneath
                        // each puff so the cloud reads as a solid form lit
                        // from above rather than a flat blurred blob.
                        let shadeRect = CGRect(x: puffX, y: y + puffW * 0.16, width: puffW, height: puffW * 0.5)
                        ctx.opacity = 0.22 + rnd(i, 326) * 0.1
                        ctx.fill(Path(ellipseIn: shadeRect), with: .color(Color(red: 0.55, green: 0.62, blue: 0.72)))

                        ctx.opacity = 0.4 + rnd(i, 325) * 0.25
                        ctx.fill(Path(ellipseIn: CGRect(x: puffX, y: y, width: puffW, height: puffW * 0.6)),
                                 with: .color(.white))
                    }
                }
            }
            .blur(radius: 14)
        }
        .allowsHitTesting(false)
    }
}

/// A horizon line of rounded tree/foliage silhouettes where sky meets
/// grass, so the park reads as a place rather than a color gradient.
struct TreeLineCanvas: View {
    var body: some View {
        Canvas { ctx, size in
            let baseY = size.height * 0.78
            let count = 8
            let lightGreen = Color(red: 0.42, green: 0.68, blue: 0.32)
            let trunkColor = Color(red: 0.17, green: 0.11, blue: 0.07)

            for i in 0..<count {
                let slot = size.width / CGFloat(count)
                let x = slot * (CGFloat(i) + 0.5) + (rnd(i, 340) - 0.5) * slot * 0.5
                let canopyR = slot * (0.42 + rnd(i, 341) * 0.3)
                let trunkH = canopyR * (0.55 + rnd(i, 344) * 0.4)
                let trunkW = max(3, canopyR * 0.16)
                let canopyCenterY = baseY - trunkH - canopyR * 0.6

                // Trunk, planted at the ground (its bottom sits exactly on
                // baseY, never past it) and rising up to overlap slightly
                // into the canopy so there's no visible gap.
                let trunkTop = canopyCenterY + canopyR * 0.3
                ctx.fill(
                    Path(roundedRect: CGRect(x: x - trunkW / 2, y: trunkTop, width: trunkW, height: baseY - trunkTop),
                         cornerRadius: trunkW * 0.4),
                    with: .color(trunkColor.opacity(0.65))
                )

                // A cluster of overlapping round puffs reads as foliage far
                // more clearly than one squashed oval — the irregular
                // silhouette is what makes it legible as a tree.
                for puff in 0..<3 {
                    let seed = i * 11 + puff
                    let px = x + (rnd(seed, 342) - 0.5) * canopyR * 0.9
                    let py = canopyCenterY - rnd(seed, 343) * canopyR * 0.35
                    let pr = canopyR * (0.68 + rnd(seed, 345) * 0.4)
                    ctx.fill(Path(ellipseIn: CGRect(x: px - pr / 2, y: py - pr / 2, width: pr, height: pr)),
                             with: .color(lightGreen.opacity(0.65)))
                }
                // A brighter top puff catches the light and separates the
                // canopy's silhouette from the flat trunk/ground color.
                let hlR = canopyR * 0.5
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x - hlR / 2, y: canopyCenterY - canopyR * 0.4 - hlR / 2, width: hlR, height: hlR)),
                    with: .color(Color(red: 0.62, green: 0.82, blue: 0.42).opacity(0.45))
                )
            }

            ctx.fill(Path(CGRect(x: 0, y: baseY, width: size.width, height: size.height - baseY)),
                     with: .color(lightGreen.opacity(0.28)))
        }
        .allowsHitTesting(false)
    }
}

/// Dark tree silhouettes lining a roadside — cooler and flatter than
/// `TreeLineCanvas` (which is built for a sunlit park) so they read as
/// night foliage rather than daytime greenery, with a faint amber rim
/// catching nearby streetlamp glow. `height` is the target ground-to-canopy-top
/// height (with slight per-tree jitter) so trees can be matched to the
/// street lamps standing alongside them.
struct RoadsideTreesCanvas: View {
    let roadTopY: CGFloat
    var count: Int = 5
    var height: CGFloat = 150
    /// Explicit x positions (in points) to use instead of automatic even
    /// spacing — lets a scene place a single tree (or a custom layout)
    /// rather than a full evenly-spaced row.
    var positions: [CGFloat]? = nil

    var body: some View {
        Canvas { ctx, size in
            let dark = Color(red: 0.03, green: 0.055, blue: 0.04)
            let rim = Theme.neonAmber.opacity(0.15)
            let slot = size.width / CGFloat(count)
            let xs = positions ?? (0..<count).map { i -> CGFloat in
                var x = slot * (CGFloat(i) + 0.5) + (rnd(i, 512) - 0.5) * slot * 0.4
                // Shift the leftmost tree to the right to avoid overlapping the first street lamp
                if i == 0 { x += 50 }
                return x
            }

            for (i, x) in xs.enumerated() {

                // H ≈ trunkH + canopyR·1.6, and trunkH = canopyR·1.1, so
                // canopyR = H / 2.7 keeps the tree's total height at target.
                let treeH = height * (0.9 + rnd(i, 517) * 0.2)
                let canopyR = treeH / 2.7
                let trunkH = canopyR * 1.1
                let trunkW = max(2, canopyR * 0.12)
                let canopyCenterY = roadTopY - trunkH - canopyR * 0.55

                ctx.fill(
                    Path(roundedRect: CGRect(x: x - trunkW / 2, y: canopyCenterY, width: trunkW, height: roadTopY - canopyCenterY),
                         cornerRadius: trunkW * 0.4),
                    with: .color(dark.opacity(0.85))
                )

                for puff in 0..<3 {
                    let seed = i * 13 + puff
                    let px = x + (rnd(seed, 514) - 0.5) * canopyR * 0.8
                    let py = canopyCenterY - rnd(seed, 515) * canopyR * 0.3
                    let pr = canopyR * (0.7 + rnd(seed, 516) * 0.35)
                    ctx.fill(Path(ellipseIn: CGRect(x: px - pr / 2, y: py - pr / 2, width: pr, height: pr)),
                             with: .color(dark))
                }

                let hlR = canopyR * 0.22
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x + canopyR * 0.28 - hlR / 2, y: canopyCenterY - canopyR * 0.3 - hlR / 2, width: hlR, height: hlR)),
                    with: .color(rim)
                )
            }
        }
        .allowsHitTesting(false)
    }
}

/// Street lamps ("ไฟกิ่ง") evenly spaced along a road, all facing the same
/// direction so the row reads as one consistent streetscape rather than
/// alternating arms. Drawn on one `Canvas` with pole/arm/bulb all placed
/// from the same explicit `roadTopY` anchor — a nested-view + `.offset()`
/// version of this previously let the pole's reported layout frame drift
/// from its drawn position, so the pole sank below the road and the bulb
/// floated off the lamp head. Canvas coordinates sidestep that entirely:
/// the pole base is always exactly `roadTopY`, and the bulb is always
/// exactly at the arm's end point.
struct StreetLampRow: View {
    let roadTopY: CGFloat
    var count: Int = 4
    var height: CGFloat = 150
    /// Which way every lamp's arm reaches: `1` = right, `-1` = left.
    var direction: CGFloat = 1
    /// Explicit x positions (in points) to use instead of automatic even
    /// spacing — lets a scene place a single lamp (or a custom layout)
    /// rather than a full evenly-spaced row.
    var positions: [CGFloat]? = nil

    var body: some View {
        Canvas { ctx, size in
            let slot = size.width / CGFloat(count)
            let xs = positions ?? (0..<count).map { slot * (CGFloat($0) + 0.5) }

            for x in xs {
                let armDir = direction
                let topY = roadTopY - height

                // Pole: base planted exactly on the road line, rising to topY.
                ctx.fill(
                    Path(roundedRect: CGRect(x: x - 2.5, y: topY, width: 5, height: height), cornerRadius: 2.5),
                    with: .linearGradient(
                        Gradient(colors: [Color(white: 0.24), Color(white: 0.06)]),
                        startPoint: CGPoint(x: x, y: topY), endPoint: CGPoint(x: x, y: roadTopY)
                    )
                )

                // Arm reaching from the pole top out to the lamp head.
                let armStart = CGPoint(x: x, y: topY + 14)
                let headPoint = CGPoint(x: x + armDir * 32, y: topY + 6)
                var arm = Path()
                arm.move(to: armStart)
                arm.addLine(to: headPoint)
                ctx.stroke(arm, with: .color(Color(white: 0.14)), style: StrokeStyle(lineWidth: 4, lineCap: .round))

                // Warm glow spilling from the head, and the bulb itself —
                // both centered on the exact same headPoint as the arm's end.
                let glowRect = CGRect(x: headPoint.x - 50, y: headPoint.y - 50, width: 100, height: 100)
                ctx.fill(
                    Path(ellipseIn: glowRect),
                    with: .radialGradient(
                        Gradient(colors: [Theme.neonAmber.opacity(0.5), .clear]),
                        center: headPoint, startRadius: 2, endRadius: 50
                    )
                )
                let bulbR: CGFloat = 4
                ctx.fill(
                    Path(ellipseIn: CGRect(x: headPoint.x - bulbR, y: headPoint.y - bulbR, width: bulbR * 2, height: bulbR * 2)),
                    with: .color(Theme.neonAmber)
                )
            }
        }
        .allowsHitTesting(false)
    }
}

/// A slowly scrolling dashed conveyor line along the facility floor.
struct ConveyorBeltCanvas: View {
    var reduceMotion: Bool = false

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1.0 / 20)) { context in
            Canvas { ctx, size in
                let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
                let y = size.height * 0.9
                let dashLength: CGFloat = 30
                let gap: CGFloat = 22
                let cycle = dashLength + gap
                let offset = reduceMotion ? 0 : CGFloat((-t * 70).truncatingRemainder(dividingBy: Double(cycle)))
                var x = -cycle + offset
                while x < size.width {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: y))
                    path.addLine(to: CGPoint(x: x + dashLength, y: y))
                    ctx.stroke(path, with: .color(Theme.cleanCyan.opacity(0.28)), lineWidth: 3)
                    x += cycle
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// Pipe, crane, and gear silhouettes framing every factory/facility scene
/// (origin line, sorting line, recycling facility) so they read as one real
/// industrial space instead of a generic glowing void. The gears actually
/// turn and the windows actually flicker — a static silhouette reads as a
/// backdrop painting; a few moving parts read as a place that's running.
struct FactorySilhouetteCanvas: View {
    var reduceMotion: Bool = false

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1.0 / 20)) { context in
            let t = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let factoryColor = Color(red: 0.05, green: 0.09, blue: 0.11).opacity(0.8)
                let highlightColor = Theme.cleanCyan.opacity(0.18)

                // A hazy, distant second facility building behind everything
                // else, for depth instead of one flat plane of machinery.
                for i in 0..<3 {
                    let bx = size.width * (0.12 + CGFloat(i) * 0.38)
                    let bw = size.width * 0.26
                    let bh = size.height * (0.32 + rnd(i, 500) * 0.12)
                    let rect = CGRect(x: bx, y: size.height * 0.18 - bh * 0.3, width: bw, height: bh)
                    ctx.fill(Path(rect), with: .color(Color(red: 0.04, green: 0.07, blue: 0.09).opacity(0.5)))
                    // A handful of lit windows so the distant building reads
                    // as occupied/running, not a dead silhouette.
                    for w in 0..<6 {
                        guard rnd(i * 11 + w, 501) > 0.55 else { continue }
                        let wx = rect.minX + rect.width * (CGFloat(w % 3) + 0.5) / 3
                        let wy = rect.minY + rect.height * (CGFloat(w / 3) + 0.5) / 2
                        let flicker = 0.4 + 0.3 * sin(t * 0.6 + Double(w) * 2.1)
                        ctx.fill(Path(CGRect(x: wx - 3, y: wy - 4, width: 6, height: 8)),
                                 with: .color(Theme.cleanCyan.opacity(0.25 * flicker)))
                    }
                }

                // Overhead crane/beam
                var beam = Path()
                beam.addRect(CGRect(x: 0, y: size.height * 0.05, width: size.width, height: size.height * 0.08))
                ctx.fill(beam, with: .color(factoryColor))
                ctx.stroke(beam, with: .color(highlightColor), style: StrokeStyle(lineWidth: 1.5))

                // A slow steam wisp drifting up from the beam — the one
                // purely atmospheric touch that sells "running machinery"
                // at a glance, before you even notice the gears or windows.
                for i in 0..<3 {
                    let phase = (t * 0.05 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                    let sx = size.width * (0.3 + CGFloat(i) * 0.22)
                    let sy = size.height * 0.05 - size.height * 0.28 * CGFloat(phase)
                    let r = size.width * (0.04 + 0.05 * CGFloat(phase))
                    ctx.opacity = (1 - phase) * 0.12
                    ctx.fill(Path(ellipseIn: CGRect(x: sx - r, y: sy - r * 0.6, width: r * 2, height: r * 1.2)),
                             with: .color(.white))
                }
                ctx.opacity = 1

                // Hanging central nozzle/crane (aligns above bottle)
                var nozzle = Path()
                let nx = size.width * 0.5
                let ny = size.height * 0.13
                nozzle.move(to: CGPoint(x: nx - 30, y: ny))
                nozzle.addLine(to: CGPoint(x: nx + 30, y: ny))
                nozzle.addLine(to: CGPoint(x: nx + 15, y: ny + size.height * 0.12))
                nozzle.addLine(to: CGPoint(x: nx - 15, y: ny + size.height * 0.12))
                nozzle.closeSubpath()
                ctx.fill(nozzle, with: .color(factoryColor))
                ctx.stroke(nozzle, with: .color(highlightColor), style: StrokeStyle(lineWidth: 1.5))

                // Pipes, angled struts, and lit port windows down each side.
                let sides: [CGFloat] = [0.08, 0.92]
                for side in sides {
                    let x = side * size.width

                    var pipe = Path()
                    pipe.addRect(CGRect(x: x - 12, y: size.height * 0.13, width: 24, height: size.height * 0.87))
                    ctx.fill(pipe, with: .color(factoryColor))

                    var strut = Path()
                    strut.move(to: CGPoint(x: x + (side < 0.5 ? 12 : -12), y: size.height * 0.3))
                    strut.addLine(to: CGPoint(x: x + (side < 0.5 ? 60 : -60), y: size.height * 0.13))
                    ctx.stroke(strut, with: .color(factoryColor), style: StrokeStyle(lineWidth: 16))
                    ctx.stroke(strut, with: .color(highlightColor), style: StrokeStyle(lineWidth: 1.5))

                    for j in 0..<4 {
                        let ringY = size.height * 0.25 + CGFloat(j) * size.height * 0.18
                        let pulse = 0.5 + 0.5 * sin(t * 1.1 + Double(j) + Double(side))
                        ctx.stroke(Path(CGRect(x: x - 15, y: ringY, width: 30, height: 10)),
                                   with: .color(highlightColor.opacity(0.4 + pulse * 0.6)), style: StrokeStyle(lineWidth: 2))
                    }
                }

                // Background gears, actually turning — a dashed ring that
                // rotates reads as a real turning gear, not wallpaper.
                let gearX: [CGFloat] = [0.2, 0.85]
                let gearY: [CGFloat] = [0.15, 0.4]
                let gearR: [CGFloat] = [0.1, 0.15]
                for i in 0..<2 {
                    let gearCenter = CGPoint(x: size.width * gearX[i], y: size.height * gearY[i])
                    let r = size.width * gearR[i]
                    var gear = Path()
                    gear.addEllipse(in: CGRect(x: gearCenter.x - r, y: gearCenter.y - r, width: r * 2, height: r * 2))
                    ctx.stroke(gear, with: .color(Theme.cleanCyan.opacity(0.1)), style: StrokeStyle(lineWidth: 12))

                    var teeth = ctx
                    teeth.translateBy(x: gearCenter.x, y: gearCenter.y)
                    teeth.rotate(by: .radians(t * (i.isMultiple(of: 2) ? 0.25 : -0.2)))
                    teeth.translateBy(x: -gearCenter.x, y: -gearCenter.y)
                    teeth.stroke(gear, with: .color(Theme.cleanCyan.opacity(0.15)), style: StrokeStyle(lineWidth: 4, dash: [10, 15]))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// A small head/torso/legs person, used everywhere the game needs a human
/// figure (the park's community cleanup, the ending's bystanders) instead
/// of an abstract capsule that reads as an unlabeled blob.
///
/// `bending` pivots only the torso+head forward from the hip — the legs
/// stay planted vertically — with a reaching arm, so it clearly reads as
/// "picking something up" instead of a whole body just tilting sideways.
struct PersonFigure: View {
    var shirt: Color
    var bending: Bool = false

    private let skinTone = Color(red: 0.55, green: 0.4, blue: 0.3)
    private let pantsColor = Color(red: 0.2, green: 0.16, blue: 0.14)

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 2) {
                Circle().fill(skinTone).frame(width: 16, height: 16)
                ZStack {
                    // Back arm: hangs at rest normally, swings back
                    // slightly as a counterbalance while bending.
                    Capsule().fill(skinTone).frame(width: 5, height: 20)
                        .rotationEffect(.degrees(bending ? 25 : 0), anchor: .top)
                        .offset(x: -13, y: 2)
                    RoundedRectangle(cornerRadius: 6).fill(shirt.opacity(0.85)).frame(width: 22, height: 28)
                    // Front arm: hangs at rest, reaches down to pick
                    // something up while bending.
                    Capsule().fill(skinTone).frame(width: 5, height: 20)
                        .rotationEffect(.degrees(bending ? -65 : 0), anchor: .top)
                        .offset(x: 12, y: 2)
                }
            }
            .rotationEffect(.degrees(bending ? 55 : 0), anchor: .bottom)

            HStack(spacing: 10) {
                Capsule().fill(pantsColor).frame(width: 7, height: 22)
                Capsule().fill(pantsColor).frame(width: 7, height: 22)
            }
        }
        .frame(width: 34, height: 68)
    }
}
