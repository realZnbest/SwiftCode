import SwiftUI

struct UnderwaterBackdrop: View {
    var surface: Color
    var deep: Color
    var murk: Double = 0
    var lightY: CGFloat = 0.06
    var t: Double? = nil

    var body: some View {
        Clocked(t: t, fps: 12) { t in
            Canvas { ctx, size in
                ctx.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .linearGradient(
                        Gradient(stops: [
                            .init(color: surface, location: 0),
                            .init(color: surface.mix(with: deep, amount: 0.55), location: 0.42),
                            .init(color: deep, location: 1)
                        ]),
                        startPoint: .zero,
                        endPoint: CGPoint(x: 0, y: size.height)
                    )
                )

                softBlob(
                    in: ctx,
                    center: CGPoint(x: size.width * 0.5, y: size.height * lightY),
                    radiusX: size.width * 0.72,
                    radiusY: size.height * 0.46,
                    color: surface.mix(with: .white, amount: 0.55),
                    peakOpacity: 0.15 * (1 - murk * 0.55)
                )

                let motes = Int(28 + murk * 44)
                let span = size.height + 40
                for i in 0..<motes {
                    let rise = CGFloat((t * (2.5 + Double(rnd(i, 902)) * 5.5))
                        .truncatingRemainder(dividingBy: Double(span)))
                    let x = rnd(i, 900) * size.width + CGFloat(sin(t * 0.22 + Double(i))) * 6
                    var y = rnd(i, 901) * size.height - rise
                    if y < -20 { y += span }
                    let r = 0.8 + rnd(i, 903) * 1.9
                    let depthFade = 1 - Double(y / max(size.height, 1)) * 0.4
                    ctx.opacity = (0.09 + Double(rnd(i, 904)) * 0.15) * (0.45 + murk) * depthFade
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)), with: .color(.white))
                }
                ctx.opacity = 1
            }
        }
        .allowsHitTesting(false)
    }
}

struct CausticBands: View {
    var color: Color
    var intensity: Double = 1
    var reach: CGFloat = 0.72
    var t: Double? = nil

    var body: some View {
        Clocked(t: t, fps: 15) { t in
            Canvas { ctx, size in
                let bands = 7
                for i in 0..<bands {
                    let depth = (Double(i) + 0.5) / Double(bands)
                    let y = size.height * CGFloat(depth) * reach
                    let fade = (1 - depth) * (1 - depth)
                    let amp = 5 + rnd(i, 950) * 9
                    let k = 0.009 + Double(rnd(i, 951)) * 0.007
                    let phase = t * (0.45 + Double(rnd(i, 952)) * 0.65) + Double(i) * 1.7

                    var path = Path()
                    var started = false
                    var x: CGFloat = -20
                    while x <= size.width + 20 {
                        let yy = y
                            + amp * CGFloat(sin(Double(x) * k + phase))
                            + amp * 0.42 * CGFloat(sin(Double(x) * k * 2.3 + phase * 1.7))
                        let p = CGPoint(x: x, y: yy)
                        if started { path.addLine(to: p) } else { path.move(to: p); started = true }
                        x += 14
                    }

                    let a = intensity * fade
                    ctx.stroke(path, with: .color(color.opacity(0.05 * a)),
                               style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    ctx.stroke(path, with: .color(color.opacity(0.13 * a)),
                               style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct MeniscusWaterline: View {
    var surfaceY: CGFloat
    var tint: Color
    var t: Double? = nil

    static func waveY(_ x: CGFloat, surfaceY: CGFloat, t: Double) -> CGFloat {
        surfaceY
            + 3.4 * CGFloat(sin(Double(x) * 0.021 + t * 1.5))
            + 1.6 * CGFloat(sin(Double(x) * 0.047 - t * 2.1))
    }

    var body: some View {
        Clocked(t: t, fps: 20) { t in
            Canvas { ctx, size in
                var crest = Path()
                var started = false
                var x: CGFloat = 0
                while x <= size.width + 10 {
                    let p = CGPoint(x: x, y: Self.waveY(x, surfaceY: surfaceY, t: t))
                    if started { crest.addLine(to: p) } else { crest.move(to: p); started = true }
                    x += 10
                }

                var band = crest
                band.addLine(to: CGPoint(x: size.width + 10, y: surfaceY + 26))
                band.addLine(to: CGPoint(x: 0, y: surfaceY + 26))
                band.closeSubpath()
                ctx.fill(band, with: .linearGradient(
                    Gradient(colors: [tint.opacity(0.34), tint.opacity(0)]),
                    startPoint: CGPoint(x: 0, y: surfaceY),
                    endPoint: CGPoint(x: 0, y: surfaceY + 26)
                ))

                ctx.stroke(crest, with: .color(tint.opacity(0.34)),
                           style: StrokeStyle(lineWidth: 5, lineCap: .round))
                ctx.stroke(crest, with: .color(.white.opacity(0.7)),
                           style: StrokeStyle(lineWidth: 1.6, lineCap: .round))

                for i in 0..<16 {
                    let gx = rnd(i, 960) * size.width
                    let twinkle = 0.5 + 0.5 * sin(t * (1.4 + Double(rnd(i, 961))) + Double(i) * 2.1)
                    let w: CGFloat = 2.4 + rnd(i, 962) * 5.5
                    let h: CGFloat = 0.7 + rnd(i, 963) * 0.6
                    let gy = Self.waveY(gx, surfaceY: surfaceY, t: t)
                    ctx.opacity = (0.12 + twinkle * 0.45) * Double(0.5 + rnd(i, 964) * 0.5)
                    ctx.fill(
                        Path(roundedRect: CGRect(x: gx - w / 2, y: gy - h / 2, width: w, height: h),
                             cornerRadius: h / 2),
                        with: .color(.white)
                    )
                }
                ctx.opacity = 1
            }
        }
        .allowsHitTesting(false)
    }
}
