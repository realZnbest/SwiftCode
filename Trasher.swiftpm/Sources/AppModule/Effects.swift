import SwiftUI

func rnd(_ i: Int, _ salt: Int = 0) -> CGFloat { CGFloat(Theme.hash(i, salt)) }

struct RainCanvas: View {
    var intensity: Double = 1

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
            Canvas { ctx, size in
                let t = context.date.timeIntervalSinceReferenceDate
                let count = Int(150 * intensity)
                for i in 0..<count {
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

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
            Canvas { ctx, size in
                let t = context.date.timeIntervalSinceReferenceDate
                let count = 10
                for i in 0..<count {
                    let color = colors[i % colors.count]
                    let x = rnd(i, 20) * size.width
                    let drift = sin(t * 0.15 + Double(i)) * 14
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

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
            Canvas { ctx, size in
                let t = context.date.timeIntervalSinceReferenceDate
                for i in 0..<count {
                    let x = rnd(i, 30) * size.width + sin(t * 0.6 + Double(i)) * 8
                    let span = size.height + 40
                    let rise = (CGFloat(t) * (20 + rnd(i, 32) * 30)).truncatingRemainder(dividingBy: span)
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

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
            Canvas { ctx, size in
                let t = context.date.timeIntervalSinceReferenceDate
                let count = 5
                for i in 0..<count {
                    let dir: CGFloat = i.isMultiple(of: 2) ? 1 : -1
                    let speed = 26.0 + Double(rnd(i, 40)) * 18
                    let span = size.width + 140
                    let progress = (t * speed).truncatingRemainder(dividingBy: span)
                    let x = dir > 0 ? CGFloat(progress) - 70 : size.width - CGFloat(progress) + 70
                    let y = size.height * (0.25 + rnd(i, 42) * 0.5)
                    let scale = 0.6 + rnd(i, 43) * 0.7
                    var path = Path()
                    let w: CGFloat = 34 * scale * dir
                    let h: CGFloat = 12 * scale
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

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
            Canvas { ctx, size in
                let t = context.date.timeIntervalSinceReferenceDate
                let count = Int(6 * intensity) + 2
                for i in 0..<count {
                    let baseX = rnd(i, 50) * size.width
                    let drift = sin(t * 0.2 + Double(i) * 1.3) * 30
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

struct MicroplasticDrift: View {
    var elapsed: Double
    var center: CGPoint

    var body: some View {
        Canvas { ctx, size in
            let t = min(max(elapsed / 3.8, 0), 1)
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

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
            Canvas { ctx, size in
                let t = context.date.timeIntervalSinceReferenceDate
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

    var label: String {
        switch self {
        case .landfill: return "ฝังดิน"
        case .stormDrain: return "ท่อระบายน้ำ"
        case .sea: return "ล่องลอยต่อไป"
        case .recyclingPoint: return "รีไซเคิล"
        }
    }
}

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

            for i in 0..<8 {
                let x = midX - baseHalf * 0.6 + rnd(i, 700) * baseHalf * 1.2
                let y = baseY - rnd(i, 701) * (baseY - topY) * 0.8
                let r = s * 0.02
                clipped.fill(Path(ellipseIn: CGRect(x: x - r / 2, y: y - r / 2, width: r, height: r)), with: .color(.black.opacity(0.3)))
            }

            var bottleLayer = clipped
            bottleLayer.translateBy(x: midX + s * 0.02, y: baseY - (baseY - topY) * 0.5)
            bottleLayer.rotate(by: .degrees(14))
            let bottlePath = Path(roundedRect: CGRect(x: -s * 0.05, y: -s * 0.12, width: s * 0.1, height: s * 0.24), cornerRadius: s * 0.03)
            bottleLayer.fill(bottlePath, with: .color(Theme.bottleBlue.opacity(bright ? 0.9 : 0.65)))
        }
        .frame(width: size, height: size)
    }
}

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

struct LightRaysCanvas: View {
    var color: Color
    var count: Int = 4

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20)) { context in
            Canvas { ctx, size in
                let t = context.date.timeIntervalSinceReferenceDate
                for i in 0..<count {
                    let baseX = (rnd(i, 300) * 0.8 + 0.1) * size.width
                    let sway = sin(t * 0.18 + Double(i) * 1.7) * 24
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

struct CloudDriftCanvas: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 12)) { context in
            Canvas { ctx, size in
                let t = context.date.timeIntervalSinceReferenceDate
                for i in 0..<5 {
                    let speed = 5.0 + Double(rnd(i, 320)) * 4
                    let span = size.width + 320
                    let travel = CGFloat((t * speed).truncatingRemainder(dividingBy: Double(span)))
                    let x = travel - 160
                    let y = size.height * (0.06 + rnd(i, 322) * 0.22)
                    let w = 120 + rnd(i, 323) * 110
                    for puff in 0..<4 {
                        let puffX = x + CGFloat(puff) * w * 0.28
                        let puffW = w * (0.5 + rnd(i * 7 + puff, 324) * 0.4)
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

struct TreeLineCanvas: View {
    var body: some View {
        Canvas { ctx, size in
            let baseY = size.height * 0.78
            let count = 8
            let shadowGreen = Color(red: 0.22, green: 0.42, blue: 0.19)
            let midGreen = Color(red: 0.42, green: 0.68, blue: 0.32)
            let highlightGreen = Color(red: 0.68, green: 0.86, blue: 0.46)
            let trunkColor = Color(red: 0.17, green: 0.11, blue: 0.07)

            for i in 0..<count {
                let slot = size.width / CGFloat(count)
                let x = slot * (CGFloat(i) + 0.5) + (rnd(i, 340) - 0.5) * slot * 0.5
                let canopyR = slot * (0.42 + rnd(i, 341) * 0.3)
                let trunkH = canopyR * (0.55 + rnd(i, 344) * 0.4)
                let trunkW = max(3, canopyR * 0.16)
                let canopyCenterY = baseY - trunkH - canopyR * 0.6

                drawTree(in: &ctx, seedBase: i, x: x, baseY: baseY, canopyCenterY: canopyCenterY,
                         canopyR: canopyR, trunkH: trunkH, trunkW: trunkW, trunkColor: trunkColor,
                         shadow: shadowGreen, mid: midGreen, highlight: highlightGreen,
                         canopyOpacity: 0.7, highlightOpacity: 0.55)
            }

            ctx.fill(Path(CGRect(x: 0, y: baseY, width: size.width, height: size.height - baseY)),
                     with: .color(midGreen.opacity(0.28)))
        }
        .allowsHitTesting(false)
    }
}

private func drawTree(
    in ctx: inout GraphicsContext,
    seedBase: Int, x: CGFloat, baseY: CGFloat, canopyCenterY: CGFloat,
    canopyR: CGFloat, trunkH: CGFloat, trunkW: CGFloat,
    trunkColor: Color, shadow: Color, mid: Color, highlight: Color,
    canopyOpacity: Double, highlightOpacity: Double
) {
    let trunkTop = canopyCenterY + canopyR * 0.32
    let baseHalfW = trunkW * 0.55
    let topHalfW = trunkW * 0.3
    var trunkPath = Path()
    trunkPath.move(to: CGPoint(x: x - baseHalfW, y: baseY))
    trunkPath.addLine(to: CGPoint(x: x - topHalfW, y: trunkTop))
    trunkPath.addLine(to: CGPoint(x: x + topHalfW, y: trunkTop))
    trunkPath.addLine(to: CGPoint(x: x + baseHalfW, y: baseY))
    trunkPath.closeSubpath()
    ctx.fill(trunkPath, with: .color(trunkColor.opacity(0.75)))

    let forkDir: CGFloat = rnd(seedBase, 601) > 0.5 ? 1 : -1
    var fork = Path()
    let forkStart = CGPoint(x: x + topHalfW * 0.5 * forkDir, y: trunkTop + trunkH * 0.1)
    fork.move(to: forkStart)
    fork.addLine(to: CGPoint(x: forkStart.x + forkDir * canopyR * 0.3, y: forkStart.y - canopyR * 0.34))
    ctx.stroke(fork, with: .color(trunkColor.opacity(0.7)), lineWidth: max(1.4, trunkW * 0.3))

    for puff in 0..<5 {
        let seed = seedBase * 31 + puff + 900
        let angle = rnd(seed, 1) * .pi * 2
        let dist = rnd(seed, 2) * canopyR * 0.5
        let px = x + cos(angle) * dist
        let py = canopyCenterY + sin(angle) * dist * 0.55
        let pr = canopyR * (0.62 + rnd(seed, 3) * 0.4)
        ctx.fill(Path(ellipseIn: CGRect(x: px - pr / 2, y: py - pr / 2, width: pr, height: pr)),
                 with: .color(shadow.opacity(canopyOpacity)))
    }

    for puff in 0..<7 {
        let seed = seedBase * 47 + puff + 300
        let angle = rnd(seed, 4) * .pi * 2
        let dist = rnd(seed, 5) * canopyR * 0.4
        let px = x + cos(angle) * dist
        let py = canopyCenterY - canopyR * 0.05 + sin(angle) * dist * 0.5
        let pr = canopyR * (0.48 + rnd(seed, 6) * 0.32)
        ctx.fill(Path(ellipseIn: CGRect(x: px - pr / 2, y: py - pr / 2, width: pr, height: pr)),
                 with: .color(mid.opacity(min(1, canopyOpacity * 1.05))))
    }

    for puff in 0..<3 {
        let seed = seedBase * 71 + puff + 60
        let px = x - canopyR * 0.15 + rnd(seed, 7) * canopyR * 0.5
        let py = canopyCenterY - canopyR * (0.32 + rnd(seed, 8) * 0.26)
        let pr = canopyR * (0.24 + rnd(seed, 9) * 0.22)
        ctx.fill(Path(ellipseIn: CGRect(x: px - pr / 2, y: py - pr / 2, width: pr, height: pr)),
                 with: .color(highlight.opacity(highlightOpacity)))
    }
}

struct RoadsideTreesCanvas: View {
    let roadTopY: CGFloat
    var count: Int = 5
    var height: CGFloat = 150
    var positions: [CGFloat]? = nil

    var body: some View {
        Canvas { ctx, size in
            let darkShadow = Color(red: 0.015, green: 0.03, blue: 0.02)
            let dark = Color(red: 0.03, green: 0.055, blue: 0.04)
            let slot = size.width / CGFloat(count)
            let xs = positions ?? (0..<count).map { i -> CGFloat in
                var x = slot * (CGFloat(i) + 0.5) + (rnd(i, 512) - 0.5) * slot * 0.4
                if i == 0 { x += 50 }
                return x
            }

            for (i, x) in xs.enumerated() {
                let treeH = height * (0.9 + rnd(i, 517) * 0.2)
                let canopyR = treeH / 2.7
                let trunkH = canopyR * 1.1
                let trunkW = max(2, canopyR * 0.12)
                let canopyCenterY = roadTopY - trunkH - canopyR * 0.55

                drawTree(in: &ctx, seedBase: i, x: x, baseY: roadTopY, canopyCenterY: canopyCenterY,
                         canopyR: canopyR, trunkH: trunkH, trunkW: trunkW, trunkColor: dark,
                         shadow: darkShadow, mid: dark, highlight: Theme.neonAmber,
                         canopyOpacity: 0.88, highlightOpacity: 0)
            }
        }
        .allowsHitTesting(false)
    }
}

struct StreetLampRow: View {
    let roadTopY: CGFloat
    var count: Int = 4
    var height: CGFloat = 150
    var direction: CGFloat = 1
    var positions: [CGFloat]? = nil

    var body: some View {
        Canvas { ctx, size in
            let slot = size.width / CGFloat(count)
            let xs = positions ?? (0..<count).map { slot * (CGFloat($0) + 0.5) }

            for x in xs {
                let armDir = direction
                let topY = roadTopY - height

                ctx.fill(
                    Path(roundedRect: CGRect(x: x - 2.5, y: topY, width: 5, height: height), cornerRadius: 2.5),
                    with: .linearGradient(
                        Gradient(colors: [Color(white: 0.24), Color(white: 0.06)]),
                        startPoint: CGPoint(x: x, y: topY), endPoint: CGPoint(x: x, y: roadTopY)
                    )
                )

                let armStart = CGPoint(x: x, y: topY + 14)
                let headPoint = CGPoint(x: x + armDir * 32, y: topY + 6)
                var arm = Path()
                arm.move(to: armStart)
                arm.addLine(to: headPoint)
                ctx.stroke(arm, with: .color(Color(white: 0.14)), style: StrokeStyle(lineWidth: 4, lineCap: .round))

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

struct ConveyorBeltCanvas: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20)) { context in
            Canvas { ctx, size in
                let t = context.date.timeIntervalSinceReferenceDate
                let y = size.height * 0.9
                let dashLength: CGFloat = 30
                let gap: CGFloat = 22
                let cycle = dashLength + gap
                let offset = CGFloat((-t * 70).truncatingRemainder(dividingBy: Double(cycle)))
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

struct FactorySilhouetteCanvas: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let factoryColor = Color(red: 0.05, green: 0.09, blue: 0.11).opacity(0.8)
                let highlightColor = Theme.cleanCyan.opacity(0.18)

                var beam = Path()
                beam.addRect(CGRect(x: 0, y: size.height * 0.05, width: size.width, height: size.height * 0.08))
                ctx.fill(beam, with: .color(factoryColor))
                ctx.stroke(beam, with: .color(highlightColor), style: StrokeStyle(lineWidth: 1.5))

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

                let gearSide: [CGFloat] = [0.08, 0.92]
                let gearY: [CGFloat] = [0.32, 0.56]
                let gearR: [CGFloat] = [0.075, 0.06]
                for i in 0..<2 {
                    let side = gearSide[i]
                    let armDir: CGFloat = side < 0.5 ? 1 : -1
                    let pipeX = side * size.width
                    let r = size.width * gearR[i]
                    let gearCenter = CGPoint(x: pipeX + armDir * (r + 20), y: size.height * gearY[i])

                    var bracket = Path()
                    bracket.move(to: CGPoint(x: pipeX + armDir * 12, y: gearCenter.y))
                    bracket.addLine(to: CGPoint(x: gearCenter.x, y: gearCenter.y))
                    ctx.stroke(bracket, with: .color(factoryColor), style: StrokeStyle(lineWidth: 6))
                    ctx.stroke(bracket, with: .color(highlightColor), style: StrokeStyle(lineWidth: 1))

                    var cog = Path()
                    let teethCount = 10
                    for tIdx in 0..<teethCount * 2 {
                        let angle = Double(tIdx) / Double(teethCount * 2) * 2 * .pi
                        let radius = tIdx.isMultiple(of: 2) ? r : r * 0.78
                        let pt = CGPoint(x: gearCenter.x + CGFloat(cos(angle)) * radius,
                                         y: gearCenter.y + CGFloat(sin(angle)) * radius)
                        if tIdx == 0 { cog.move(to: pt) } else { cog.addLine(to: pt) }
                    }
                    cog.closeSubpath()

                    var spinning = ctx
                    spinning.translateBy(x: gearCenter.x, y: gearCenter.y)
                    spinning.rotate(by: .radians(t * (i.isMultiple(of: 2) ? 0.22 : -0.18)))
                    spinning.translateBy(x: -gearCenter.x, y: -gearCenter.y)
                    spinning.fill(cog, with: .color(Color(red: 0.08, green: 0.12, blue: 0.14)))
                    spinning.stroke(cog, with: .color(highlightColor), lineWidth: 1.5)

                    let hubR = r * 0.32
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: gearCenter.x - hubR, y: gearCenter.y - hubR, width: hubR * 2, height: hubR * 2)),
                        with: .color(Theme.cleanCyan.opacity(0.3))
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

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
                    Capsule().fill(skinTone).frame(width: 5, height: 20)
                        .rotationEffect(.degrees(bending ? 25 : 0), anchor: .top)
                        .offset(x: -13, y: 2)
                    RoundedRectangle(cornerRadius: 6).fill(shirt.opacity(0.85)).frame(width: 22, height: 28)
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
