import SwiftUI

struct StormDrainTunnelScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "ดำดิ่งสู่ความมืดมิด จนไม่มีใครมองเห็น",
            vignetteStrength: 0.7,
            showBottle: false,
            content: { size in
                ZStack {
                    Theme.nearBlack
                    VanishingLightGlow()
                    TunnelRingsCanvas()
                    TunnelWallStreakCanvas()
                    BubbleCanvas(count: 26, color: .white).opacity(0.55)
                    SmokeCanvas(intensity: 0.6, color: Theme.murkGreen)

                    TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                        let t = context.date.timeIntervalSinceReferenceDate
                        BottleView(
                            vibrancy: game.vibrancy, dirt: game.grime, showEyes: false,
                            width: 56, height: 138, tilt: .degrees(t * 65)
                        )
                        .position(x: size.width * 0.5, y: size.height * 0.55)
                        .glow(Theme.cleanCyan, radius: 10, opacity: 0.25)
                    }
                }
            },
            onFinish: { game.advanceFromStormDrainTunnel() }
        )
    }
}

/// A pulsing point of light at the vanishing point — anchors the sense of falling toward
/// (or away from) something, instead of just fading into flat black.
private struct VanishingLightGlow: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let pulse = 0.6 + 0.4 * sin(t * 0.55)
            Circle()
                .fill(RadialGradient(
                    colors: [Theme.cleanCyan.opacity(0.45 * pulse), .clear],
                    center: .center, startRadius: 0, endRadius: 100
                ))
                .frame(width: 200, height: 200)
                .blur(radius: 6)
        }
        .allowsHitTesting(false)
    }
}

/// Rings continuously spawning at the center and expanding outward while fading — reads as
/// motion through a tunnel, unlike 5 static rings that never moved.
private struct TunnelRingsCanvas: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let maxR = max(size.width, size.height) * 0.75
                let ringCount = 7
                let cycle = 6.5

                for i in 0..<ringCount {
                    let phase = ((t / cycle) + Double(i) / Double(ringCount)).truncatingRemainder(dividingBy: 1.0)
                    let r = CGFloat(phase) * maxR
                    let opacity = (1 - phase) * 0.3
                    let rect = CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)
                    ctx.stroke(Path(ellipseIn: rect), with: .color(Theme.cleanCyan.opacity(opacity)),
                               lineWidth: 1.5 + CGFloat(phase) * 2.5)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// Faint streaks radiating from center, flickering — the tunnel wall rushing past at speed.
private struct TunnelWallStreakCanvas: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let streakColor = Theme.murkGreen.mix(with: Theme.cleanCyan, amount: 0.4)
                let count = 16

                for i in 0..<count {
                    let baseAngle = Double(i) / Double(count) * 2 * .pi
                    let angle = baseAngle + sin(t * 0.16 + Double(i)) * 0.05
                    let dir = CGPoint(x: cos(angle), y: sin(angle))
                    let innerR = size.width * (0.12 + 0.04 * rnd(i, 8801))
                    let outerLen = size.width * (0.3 + 0.2 * rnd(i, 8802))
                    let p0 = CGPoint(x: center.x + dir.x * innerR, y: center.y + dir.y * innerR)
                    let p1 = CGPoint(x: center.x + dir.x * (innerR + outerLen), y: center.y + dir.y * (innerR + outerLen))

                    var line = Path()
                    line.move(to: p0)
                    line.addLine(to: p1)
                    let flicker = 0.5 + 0.5 * sin(t * 0.55 + Double(i) * 1.3)
                    ctx.stroke(line, with: .color(streakColor.opacity(0.16 * flicker)), lineWidth: 1.4)
                }
            }
        }
        .allowsHitTesting(false)
    }
}
