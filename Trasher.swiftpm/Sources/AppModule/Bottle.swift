import SwiftUI

/// A stylized plastic-bottle silhouette: cap, tapered neck, shoulder,
/// gently waisted body, rounded base. Built entirely from curves so the
/// whole game needs zero image assets for its hero character.
struct BottleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let midX = rect.midX
        let minY = rect.minY

        func pt(_ xFrac: CGFloat, _ yFrac: CGFloat) -> CGPoint {
            CGPoint(x: midX + xFrac * w, y: minY + yFrac * h)
        }

        // (halfWidthFraction, heightFraction) profile from cap to base, right side only.
        let profile: [(CGFloat, CGFloat)] = [
            (0.10, 0.00),
            (0.115, 0.05),
            (0.09, 0.085),
            (0.16, 0.16),
            (0.33, 0.24),
            (0.31, 0.34),
            (0.29, 0.50),
            (0.30, 0.62),
            (0.33, 0.80),
            (0.335, 0.93),
            (0.30, 0.965),
            (0.27, 1.00)
        ]

        var path = Path()
        path.move(to: pt(-profile[0].0, profile[0].1))
        path.addLine(to: pt(profile[0].0, profile[0].1))

        for i in 1..<profile.count {
            let prev = profile[i - 1]
            let cur = profile[i]
            let midY = (prev.1 + cur.1) / 2
            path.addQuadCurve(to: pt(cur.0, cur.1), control: pt(cur.0, midY))
        }

        path.addLine(to: pt(-profile.last!.0, profile.last!.1))

        for i in stride(from: profile.count - 2, through: 0, by: -1) {
            let cur = profile[i]
            let next = profile[i + 1]
            let midY = (cur.1 + next.1) / 2
            path.addQuadCurve(to: pt(-cur.0, cur.1), control: pt(-next.0, midY))
        }

        path.closeSubpath()
        return path
    }
}

struct DirtSpeckleCanvas: View {
    var amount: Double

    var body: some View {
        Canvas { ctx, size in
            let count = Int(70 * amount)
            guard count > 0 else { return }
            for i in 0..<count {
                let x = rnd(i, 70) * size.width
                let y = rnd(i, 71) * size.height
                let r = 1.5 + rnd(i, 72) * 3
                ctx.opacity = 0.25 + rnd(i, 73) * 0.35
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                         with: .color(Theme.murkBrown))
            }
        }
    }
}

/// The bottle, our silent protagonist. A reflected highlight near the
/// shoulder reads faintly as a pair of eyes without ever becoming a
/// cartoon face — `showEyes` is only turned on for the close-up beats.
struct BottleView: View {
    var vibrancy: Double = 1
    var dirt: Double = 0
    var showEyes: Bool = false
    var glow: Double = 0
    var width: CGFloat = 90
    var height: CGFloat = 230
    var tilt: Angle = .zero

    @State private var blink = false

    var body: some View {
        ZStack {
            // Contact shadow: stays grounded regardless of how the bottle
            // itself tilts, the way a real shadow would.
            Ellipse()
                .fill(RadialGradient(colors: [Color.black.opacity(0.4), .clear],
                                     center: .center, startRadius: 0, endRadius: width * 0.62))
                .frame(width: width * 1.35, height: width * 0.36)
                .offset(y: height * 0.52)
                .blur(radius: 2)

            ZStack {
                BottleShape()
                    .fill(Theme.bottleBlue.opacity(0.3 + glow * 0.3))
                    .frame(width: width, height: height)
                    .blur(radius: 22 + glow * 12)
                    .opacity(0.45 + glow * 0.35)

                ZStack {
                    BottleShape()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Theme.bottleBlueDeep.opacity(0.55 * vibrancy + 0.15),
                                    Theme.bottleBlue.opacity(0.42 * vibrancy + 0.15),
                                    Theme.cleanCyan.opacity(0.12 * vibrancy),
                                    Theme.bottleBlueDeep.opacity(0.5 * vibrancy + 0.15)
                                ],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .saturation(0.35 + vibrancy * 0.65)

                    // Ambient occlusion: the seams where light naturally
                    // gets trapped — under the cap and at the base.
                    Capsule()
                        .fill(Color.black.opacity(0.28))
                        .frame(width: width * 0.5, height: height * 0.035)
                        .blur(radius: 3)
                        .offset(y: -height * 0.335)
                    Capsule()
                        .fill(Color.black.opacity(0.24))
                        .frame(width: width * 0.62, height: height * 0.04)
                        .blur(radius: 3)
                        .offset(y: height * 0.42)

                    Capsule()
                        .fill(
                            LinearGradient(colors: [.white.opacity(0.5), Theme.bottleBlueDeep.opacity(0.9 * vibrancy + 0.2)],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: width * 0.22, height: height * 0.075)
                        .offset(y: -height * 0.46)

                    HStack(spacing: width * 0.24) {
                        Capsule()
                            .fill(LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0)],
                                                 startPoint: .top, endPoint: .bottom))
                            .frame(width: width * 0.09, height: height * 0.5)
                        Capsule()
                            .fill(LinearGradient(colors: [.white.opacity(0.22), .white.opacity(0)],
                                                 startPoint: .top, endPoint: .bottom))
                            .frame(width: width * 0.05, height: height * 0.32)
                    }
                    .blendMode(.screen)
                    .offset(y: -height * 0.06)

                    if showEyes {
                        HStack(spacing: width * 0.16) {
                            eyeDot
                            eyeDot
                        }
                        .offset(y: -height * 0.02)
                        .opacity(0.85)
                    }

                    if dirt > 0.01 {
                        DirtSpeckleCanvas(amount: dirt)
                            .blendMode(.multiply)
                    }
                }
                .frame(width: width, height: height)
                .clipShape(BottleShape())
                .overlay(
                    // Fresnel-style rim light: brighter where the curved
                    // plastic edge catches light, dimmer on the shadow side.
                    BottleShape()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.5 * vibrancy + 0.08),
                                    Theme.cleanCyan.opacity(0.18 * vibrancy),
                                    Color.black.opacity(0.22)
                                ],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.4
                        )
                        .frame(width: width, height: height)
                )
            }
            .rotationEffect(tilt)
        }
        .frame(width: width, height: height)
        .onAppear(perform: scheduleBlink)
    }

    private var eyeDot: some View {
        Circle()
            .fill(
                RadialGradient(colors: [.white.opacity(0.9), .white.opacity(0)],
                               center: .center, startRadius: 0, endRadius: width * 0.09)
            )
            .frame(width: width * 0.14, height: blink ? width * 0.02 : width * 0.14)
    }

    private func scheduleBlink() {
        guard showEyes else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2.5...5)) {
            withAnimation(.easeInOut(duration: 0.09)) { blink = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.easeInOut(duration: 0.12)) { blink = false }
                scheduleBlink()
            }
        }
    }
}
