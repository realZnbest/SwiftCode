import SwiftUI

private struct CityBuilding {
    let x: CGFloat
    let w: CGFloat
    let topY: CGFloat
    let baseY: CGFloat
    let seed: Int
    let layer: Int
    let cols: Int
    let floorH: CGFloat
}

private struct CityLayerSpec {
    let count: Int
    let hMin: CGFloat
    let hMax: CGFloat
    let baseFrac: CGFloat
    let haze: Double
    let cols: Int
    let floorH: CGFloat
}

private let cityLayers: [CityLayerSpec] = [
    CityLayerSpec(count: 15, hMin: 0.20, hMax: 0.38, baseFrac: 1.00, haze: 0.80, cols: 0, floorH: 0),
    CityLayerSpec(count: 11, hMin: 0.26, hMax: 0.50, baseFrac: 1.00, haze: 0.42, cols: 3, floorH: 14),
    CityLayerSpec(count: 7,  hMin: 0.34, hMax: 0.62, baseFrac: 1.00, haze: 0.02, cols: 4, floorH: 16)
]

private let cityWidthFactor: [ClosedRange<CGFloat>] = [
    0.80...1.15,
    0.62...0.92,
    0.52...0.78
]

private func cityLayout(_ size: CGSize) -> [CityBuilding] {
    var out: [CityBuilding] = []
    for (li, spec) in cityLayers.enumerated() {
        let slot = size.width / CGFloat(spec.count)
        for i in 0..<spec.count {
            let seed = li * 1000 + i
            let span = cityWidthFactor[li]
            let w = slot * (span.lowerBound + rnd(seed, 8010) * (span.upperBound - span.lowerBound))
            let x = slot * CGFloat(i) + (rnd(seed, 8011) - 0.5) * slot * 0.34
            let h = size.height * (spec.hMin + rnd(seed, 8012) * (spec.hMax - spec.hMin))
            let baseY = size.height * spec.baseFrac
            out.append(CityBuilding(x: x, w: w, topY: baseY - h, baseY: baseY,
                                    seed: seed, layer: li, cols: spec.cols, floorH: spec.floorH))
        }
    }
    return out
}

private func buildingPath(_ b: CityBuilding) -> Path {
    var p = Path()
    let kind = Int(rnd(b.seed, 8100) * 100) % 4

    switch kind {
    case 1:
        let stepY = b.topY + (b.baseY - b.topY) * (0.20 + rnd(b.seed, 8101) * 0.18)
        let inset = b.w * (0.13 + rnd(b.seed, 8102) * 0.11)
        p.move(to: CGPoint(x: b.x, y: b.baseY))
        p.addLine(to: CGPoint(x: b.x, y: stepY))
        p.addLine(to: CGPoint(x: b.x + inset, y: stepY))
        p.addLine(to: CGPoint(x: b.x + inset, y: b.topY))
        p.addLine(to: CGPoint(x: b.x + b.w - inset, y: b.topY))
        p.addLine(to: CGPoint(x: b.x + b.w - inset, y: stepY))
        p.addLine(to: CGPoint(x: b.x + b.w, y: stepY))
        p.addLine(to: CGPoint(x: b.x + b.w, y: b.baseY))
    case 2:
        let cut = b.w * (0.16 + rnd(b.seed, 8103) * 0.24)
        p.move(to: CGPoint(x: b.x, y: b.baseY))
        p.addLine(to: CGPoint(x: b.x, y: b.topY + cut))
        p.addLine(to: CGPoint(x: b.x + cut, y: b.topY))
        p.addLine(to: CGPoint(x: b.x + b.w, y: b.topY))
        p.addLine(to: CGPoint(x: b.x + b.w, y: b.baseY))
    default:
        p.addRect(CGRect(x: b.x, y: b.topY, width: b.w, height: b.baseY - b.topY))
    }
    p.closeSubpath()
    return p
}

private func windowRect(_ b: CityBuilding, row: Int, col: Int) -> CGRect {
    let pad = b.w * 0.14
    let usable = b.w - pad * 2
    let cw = usable / CGFloat(b.cols)
    let ww = cw * 0.38
    let wh = b.floorH * 0.54
    let wx = b.x + pad + cw * (CGFloat(col) + 0.5) - ww / 2
    let wy = b.topY + b.floorH * (CGFloat(row) + 0.6)
    return CGRect(x: wx, y: wy, width: ww, height: wh)
}

private func windowIsFlickerer(_ b: CityBuilding, row: Int, col: Int) -> Bool {
    rnd(b.seed &* 977 &+ row &* 31 &+ col, 8305) > 0.93
}

private func windowIsLit(_ b: CityBuilding, row: Int, col: Int) -> Bool {
    let floorMood = rnd(b.seed &* 61 &+ row, 8201)
    let cell = rnd(b.seed &* 331 &+ row &* 17 &+ col, 8202)
    return cell > (floorMood > 0.62 ? 0.22 : 0.74)
}

private func windowTint(_ b: CityBuilding, row: Int, col: Int) -> Color {
    let pick = rnd(b.seed, 8203)
    let base: Color = pick > 0.78 ? Theme.neonCyan : (pick > 0.68 ? Theme.neonPink : Theme.neonAmber)
    let warmth = rnd(b.seed &* 13 &+ row, 8204)
    return base.mix(with: Color(red: 1.0, green: 0.93, blue: 0.78), amount: Double(warmth) * 0.5)
}

private func hasBeacon(_ b: CityBuilding) -> Bool {
    b.layer == 2 && rnd(b.seed, 8400) > 0.45
}

struct SkylineCanvas: View {
    var t: Double? = nil

    private let deepBase = Color(red: 0.035, green: 0.05, blue: 0.10)
    private let hazeColor = Color(red: 0.22, green: 0.31, blue: 0.46)

    var body: some View {
        ZStack {
            Canvas { ctx, size in
                let buildings = cityLayout(size)

                ctx.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .linearGradient(
                        Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: hazeColor.opacity(0.14), location: 0.55),
                            .init(color: Theme.neonAmber.mix(with: hazeColor, amount: 0.55).opacity(0.22),
                                  location: 1)
                        ]),
                        startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)
                    )
                )

                softBlob(in: ctx,
                         center: CGPoint(x: size.width * 0.42, y: size.height * 0.74),
                         radiusX: size.width * 0.62, radiusY: size.height * 0.46,
                         color: Theme.neonAmber.mix(with: Theme.neonPink, amount: 0.3),
                         peakOpacity: 0.20)

                softBlob(in: ctx,
                         center: CGPoint(x: size.width * 0.78, y: size.height * 0.80),
                         radiusX: size.width * 0.40, radiusY: size.height * 0.34,
                         color: Theme.neonCyan,
                         peakOpacity: 0.13)

                for (li, spec) in cityLayers.enumerated() {
                    let fill = deepBase.mix(with: hazeColor, amount: spec.haze)

                    for b in buildings where b.layer == li {
                        let path = buildingPath(b)
                        ctx.fill(path, with: .color(fill))

                        let rimShade = hazeColor.opacity(0.16 + spec.haze * 0.2)
                        ctx.stroke(path, with: .color(rimShade), lineWidth: 1)

                        if li == 2 { drawRoofDetail(in: ctx, b: b, color: fill) }

                        guard b.cols > 0 else { continue }
                        var lit = ctx
                        lit.clip(to: path)
                        let rows = max(0, Int((b.baseY - b.topY) / b.floorH) - 1)
                        for r in 0..<rows {
                            for c in 0..<b.cols {
                                guard !windowIsFlickerer(b, row: r, col: c) else { continue }
                                guard windowIsLit(b, row: r, col: c) else { continue }
                                let rect = windowRect(b, row: r, col: c)
                                let tint = windowTint(b, row: r, col: c)
                                let strength = 0.30 + Double(rnd(b.seed &* 7 &+ r &* 3 &+ c, 8205)) * 0.55
                                lit.fill(Path(rect), with: .color(tint.opacity(strength * (1 - spec.haze * 0.55))))
                            }
                        }
                    }

                    if li < 2 {
                        let bandTop = size.height * (0.62 + CGFloat(li) * 0.1)
                        ctx.fill(
                            Path(CGRect(x: 0, y: bandTop, width: size.width, height: size.height - bandTop)),
                            with: .linearGradient(
                                Gradient(colors: [.clear, hazeColor.opacity(0.16 - Double(li) * 0.05)]),
                                startPoint: CGPoint(x: 0, y: bandTop),
                                endPoint: CGPoint(x: 0, y: size.height)
                            )
                        )
                    }
                }
            }

            SkylineLifeCanvas(t: t)
        }
        .allowsHitTesting(false)
    }
}

private func drawRoofDetail(in ctx: GraphicsContext, b: CityBuilding, color: Color) {
    let pick = rnd(b.seed, 8500)
    let cx = b.x + b.w * 0.5

    if pick > 0.66 {
        let mastH = b.w * (0.28 + rnd(b.seed, 8501) * 0.34)
        var mast = Path()
        mast.move(to: CGPoint(x: cx, y: b.topY))
        mast.addLine(to: CGPoint(x: cx, y: b.topY - mastH))
        ctx.stroke(mast, with: .color(color), lineWidth: max(1.2, b.w * 0.035))
    } else if pick > 0.34 {
        let tw = b.w * 0.30
        let th = b.w * 0.20
        let tx = b.x + b.w * (0.18 + rnd(b.seed, 8502) * 0.44)
        ctx.fill(Path(CGRect(x: tx, y: b.topY - th, width: tw, height: th)), with: .color(color))
        var legs = Path()
        legs.move(to: CGPoint(x: tx + tw * 0.2, y: b.topY))
        legs.addLine(to: CGPoint(x: tx + tw * 0.2, y: b.topY - th))
        legs.move(to: CGPoint(x: tx + tw * 0.8, y: b.topY))
        legs.addLine(to: CGPoint(x: tx + tw * 0.8, y: b.topY - th))
        ctx.stroke(legs, with: .color(color), lineWidth: 1.2)
    }
}

private struct SkylineLifeCanvas: View {
    var t: Double? = nil

    var body: some View {
        Clocked(t: t, fps: 5) { t in
            Canvas { ctx, size in
                let buildings = cityLayout(size)

                for b in buildings {
                    if b.cols > 0 {
                        let rows = max(0, Int((b.baseY - b.topY) / b.floorH) - 1)
                        let haze = cityLayers[b.layer].haze
                        for r in 0..<rows {
                            for c in 0..<b.cols where windowIsFlickerer(b, row: r, col: c) {
                                let bucket = Int(t * 0.45) &+ b.seed &* 3 &+ r &+ c
                                guard rnd(bucket, 8306) > 0.42 else { continue }
                                let rect = windowRect(b, row: r, col: c)
                                ctx.fill(Path(rect),
                                         with: .color(windowTint(b, row: r, col: c)
                                            .opacity(0.62 * (1 - haze * 0.55))))
                            }
                        }
                    }

                    guard hasBeacon(b) else { continue }
                    let phase = Double(rnd(b.seed, 8401)) * 6.28
                    let on = sin(t * 1.9 + phase) > 0.45
                    guard on else { continue }
                    let mastH = rnd(b.seed, 8500) > 0.66 ? b.w * (0.28 + rnd(b.seed, 8501) * 0.34) : 0
                    let p = CGPoint(x: b.x + b.w * 0.5, y: b.topY - mastH - 2)
                    softBlob(in: ctx, center: p, radiusX: 9, radiusY: 9,
                             color: Theme.neonPink, peakOpacity: 0.7)
                    ctx.fill(Path(ellipseIn: CGRect(x: p.x - 1.5, y: p.y - 1.5, width: 3, height: 3)),
                             with: .color(Color(red: 1, green: 0.55, blue: 0.6)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
