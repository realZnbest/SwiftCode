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
                    let speed = 900 + rnd(i, 1) * 500
                    let x = rnd(i, 2) * size.width
                    let span = size.height + 80
                    let y = (CGFloat(t) * speed / 1000 + rnd(i, 3) * span).truncatingRemainder(dividingBy: span) - 40
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
                    path.move(to: CGPoint(x: x, y: y))
                    path.addQuadCurve(to: CGPoint(x: x + w, y: y), control: CGPoint(x: x + w * 0.5, y: y - h))
                    path.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: x + w * 0.5, y: y + h))
                    path.move(to: CGPoint(x: x + w, y: y))
                    path.addLine(to: CGPoint(x: x + w + 8 * dir, y: y - 6))
                    path.addLine(to: CGPoint(x: x + w + 8 * dir, y: y + 6))
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

/// A glowing waypoint icon used at every branching choice in the game
/// (the canal fork, the drain fork). `bright` marks the side the player is
/// currently leaning/dragging toward; `dim` marks a route the story has
/// temporarily closed off (e.g. after one detour already used).
struct PathChoiceIndicator: View {
    var systemImage: String
    var tint: Color
    var bright: Bool
    var dim: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [tint.opacity(bright ? 0.55 : 0.28), .clear],
                                     center: .center, startRadius: 0, endRadius: 80))
                .frame(width: 150, height: 150)
            // A faint neutral ring keeps the icon legible even when its
            // tint is close in hue to a murky/dark background.
            Circle()
                .strokeBorder(Color.white.opacity(bright ? 0.3 : 0.16), lineWidth: 1.5)
                .frame(width: 62, height: 62)
            Image(systemName: systemImage)
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(tint.opacity(bright ? 1 : 0.7))
        }
        .opacity(dim ? 0.25 : 1)
        .glow(tint, radius: bright ? 14 : 4, opacity: bright ? 0.6 : 0.15)
        .scaleEffect(bright ? 1.08 : 1)
        .animation(.easeInOut(duration: 0.4), value: bright)
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
