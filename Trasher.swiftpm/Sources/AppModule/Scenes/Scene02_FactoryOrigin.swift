import SwiftUI

struct FactoryOriginScene: View {
    @EnvironmentObject var game: GameState

    private let birthXFrac: CGFloat = 0.25

    @State private var heroBottleX: CGFloat = 0.25
    @State private var heroBottleY: CGFloat = 0.77
    @State private var heroBottleVisible = false
    @State private var heroBottleScale: CGFloat = 0.3
    @State private var nozzleY: CGFloat = -0.03
    @State private var flashOpacity: Double = 0
    @State private var bgBottleOffset: CGFloat = 0
    @State private var headSquash: CGFloat = 1
    @State private var ringScale: CGFloat = 0.4
    @State private var ringOpacity: Double = 0

    var body: some View {
        VignetteScene(
            line: game.t(Loc.factoryOriginLine),
            hold: 5.3,
            showBottle: false,
            textPosition: UnitPoint(x: 0.5, y: 0.65),
            content: { size in
                ZStack {
                    LinearGradient(
                        colors: [Color(red: 0.05, green: 0.07, blue: 0.10), Color(red: 0.11, green: 0.13, blue: 0.17)],
                        startPoint: .top, endPoint: .bottom
                    )
                    FactoryWindowWall()
                    FactoryTrussRow()
                    FactoryFloorPanels(beltYFrac: 0.9)
                    FactorySideColumns()
                    SteamVentCanvas(xFrac: 0.06)
                    SteamVentCanvas(xFrac: 0.94)
                    SmokeCanvas(intensity: 0.18, color: Theme.deepNavy).opacity(0.22)
                    ConveyorBeltStructure(beltYFrac: 0.9)
                    HazardStripeBand()
                        .frame(height: 7)
                        .frame(maxHeight: .infinity, alignment: .bottom)

                    HStack(spacing: 200) {
                        ForEach(0..<12, id: \.self) { _ in
                            BottleView(vibrancy: 1, dirt: 0, showEyes: false, glow: 0, width: 40, height: 98, tilt: .zero)
                                .opacity(0.3)
                        }
                    }
                    .offset(x: bgBottleOffset)
                    .position(x: size.width * 0.5, y: size.height * 0.82 + 25)
                    .onAppear {
                        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                            bgBottleOffset = 240
                        }
                    }

                    BottleView(
                        vibrancy: 1, dirt: 0, showEyes: false,
                        glow: 0.35, width: 60, height: 148, tilt: .zero
                    )
                    .scaleEffect(heroBottleScale)
                    .opacity(heroBottleVisible ? 1 : 0)
                    .position(x: size.width * heroBottleX, y: size.height * heroBottleY)

                    CappingMachineView(size: size, xFrac: birthXFrac, headY: size.height * nozzleY, capping: flashOpacity > 0, squash: headSquash)

                    Circle()
                        .stroke(Theme.cleanCyan, lineWidth: 3.5)
                        .frame(width: 70, height: 70)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)
                        .position(x: size.width * birthXFrac, y: size.height * 0.72)

                    if flashOpacity > 0 {
                        Circle()
                            .fill(Theme.neonCyan)
                            .frame(width: 104, height: 104)
                            .blur(radius: 22)
                            .opacity(flashOpacity)
                            .position(x: size.width * birthXFrac, y: size.height * 0.75)
                    }

                    LightRaysCanvas(color: Theme.cleanCyan, count: 3)
                    SparkleCanvas(count: 18, color: .white).opacity(0.4)
                }
                .onAppear(perform: runAnimation)
            },
            onFinish: { game.advanceFromFactoryOrigin() }
        )
    }

    private let hoverY: CGFloat = 0.58
    private let punchY: CGFloat = 0.69

    private func stampBeat() {
        game.sound.impactThud()
        withAnimation(.spring(response: 0.13, dampingFraction: 0.42)) { headSquash = 0.66 }
        ringScale = 0.35
        ringOpacity = 0.8
        withAnimation(.easeOut(duration: 0.5)) {
            ringScale = 2.1
            ringOpacity = 0
        }
        game.sound.success()
        withAnimation(.easeOut(duration: 0.08)) { flashOpacity = 0.9 }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.6)) {
            heroBottleVisible = true
            heroBottleScale = 1.0
        }
        withAnimation(.easeIn(duration: 0.4).delay(0.1)) { flashOpacity = 0 }
    }

    private func runAnimation() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.0))

            withAnimation(.easeIn(duration: 0.36)) { nozzleY = hoverY }
            try? await Task.sleep(for: .seconds(0.42))

            withAnimation(.easeIn(duration: 0.16)) { nozzleY = punchY }
            try? await Task.sleep(for: .seconds(0.16))

            stampBeat()

            try? await Task.sleep(for: .seconds(0.09))
            withAnimation(.spring(response: 0.22, dampingFraction: 0.55)) { headSquash = 1 }

            try? await Task.sleep(for: .seconds(0.35))
            withAnimation(.easeIn(duration: 0.81)) { nozzleY = -0.03 }
            withAnimation(.interpolatingSpring(stiffness: 70, damping: 14)) {
                heroBottleY = 0.82
            }

            try? await Task.sleep(for: .seconds(0.4))
            withAnimation(.easeInOut(duration: 2.4)) {
                heroBottleX = 1.2
            }
        }
    }
}

private struct CappingMachineView: View {
    var size: CGSize
    var xFrac: CGFloat = 0.5
    var headY: CGFloat
    var capping: Bool
    var squash: CGFloat = 1

    private let housingCenterY: CGFloat = -8
    private let housingHeight: CGFloat = 34
    private let cylinderHeight: CGFloat = 96
    private let headHeight: CGFloat = 26

    var body: some View {
        let housingBottom = housingCenterY + housingHeight / 2
        let cylinderCenterY = housingBottom + cylinderHeight / 2
        let cylinderBottom = housingBottom + cylinderHeight
        let rodTop = cylinderBottom - 16
        let rodBottom = headY - headHeight / 2 + 4
        let rodLen = max(6, rodBottom - rodTop)
        let rodCenterY = rodTop + rodLen / 2
        let midX = size.width * xFrac

        ZStack {
            Rectangle()
                .fill(LinearGradient(colors: [Color(white: 0.5), Color(white: 0.3), Color(white: 0.46)],
                                      startPoint: .leading, endPoint: .trailing))
                .frame(width: 24, height: rodLen)
                .overlay(
                    VStack(spacing: rodLen / 3.4) {
                        ForEach(0..<3, id: \.self) { _ in
                            Rectangle().fill(Color.black.opacity(0.35)).frame(height: 2.5)
                        }
                    }
                )
                .position(x: midX, y: rodCenterY)

            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(colors: [Color(white: 0.28), Color(white: 0.1), Color(white: 0.24)],
                                      startPoint: .leading, endPoint: .trailing))
                .frame(width: 40, height: cylinderHeight)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.14), lineWidth: 1))
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(white: 0.16))
                        .frame(width: 44, height: 7)
                        .offset(y: cylinderHeight / 2 - 4)
                )
                .position(x: midX, y: cylinderCenterY)

            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(colors: [Color(white: 0.44), Color(white: 0.18)], startPoint: .top, endPoint: .bottom))
                .frame(width: 78, height: housingHeight)
                .overlay(
                    HStack(spacing: 46) {
                        boltDot
                        boltDot
                    }
                )
                .overlay(
                    HazardStripeBand()
                        .frame(width: 78, height: 8)
                        .offset(y: housingHeight / 2 - 5)
                )
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.18), lineWidth: 1))
                .position(x: midX, y: housingCenterY)

            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(colors: [Color(white: 0.56), Color(white: 0.24)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 58, height: headHeight)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.35), lineWidth: 1))

                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.cleanCyan)
                    .frame(width: 52, height: 6)
                    .offset(y: headHeight / 2 - 3)
                    .glow(Theme.cleanCyan, radius: capping ? 16 : 5, opacity: capping ? 1 : 0.55)
            }
            .scaleEffect(CGSize(width: 2 - squash, height: squash), anchor: .bottom)
            .position(x: midX, y: headY)
        }
    }

    private var boltDot: some View {
        Circle()
            .fill(Color.black.opacity(0.5))
            .frame(width: 6, height: 6)
            .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
    }
}

private struct HazardStripeBand: View {
    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black.opacity(0.85)))
            let stripeW: CGFloat = 4
            var x: CGFloat = -size.height
            while x < size.width {
                var p = Path()
                p.move(to: CGPoint(x: x, y: size.height))
                p.addLine(to: CGPoint(x: x + size.height, y: 0))
                p.addLine(to: CGPoint(x: x + size.height + stripeW, y: 0))
                p.addLine(to: CGPoint(x: x + stripeW, y: size.height))
                p.closeSubpath()
                ctx.fill(p, with: .color(Theme.neonAmber.opacity(0.85)))
                x += stripeW * 2
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 1.5))
    }
}

private struct FactoryWindowWall: View {
    var body: some View {
        Canvas { ctx, size in
            let bandTop = size.height * 0.04
            let bandHeight = size.height * 0.22
            let wallColor = Color(red: 0.08, green: 0.10, blue: 0.13)
            ctx.fill(Path(CGRect(x: 0, y: bandTop, width: size.width, height: bandHeight)), with: .color(wallColor))

            let windowCount = 6
            let margin = size.width * 0.03
            let gap = size.width * 0.018
            let windowW = (size.width - margin * 2 - gap * CGFloat(windowCount - 1)) / CGFloat(windowCount)
            let inset = bandHeight * 0.14
            let windowTop = bandTop + inset

            for i in 0..<windowCount {
                let x = margin + CGFloat(i) * (windowW + gap)
                let rect = CGRect(x: x, y: windowTop, width: windowW, height: bandHeight - inset * 2)
                let warmth = 0.3 + 0.5 * rnd(i, 3301)
                let glow = Theme.neonAmber.mix(with: Theme.smokeOrange, amount: warmth)

                ctx.fill(Path(roundedRect: rect, cornerRadius: 3), with: .linearGradient(
                    Gradient(colors: [glow.opacity(0.8), glow.opacity(0.3)]),
                    startPoint: CGPoint(x: rect.midX, y: rect.minY), endPoint: CGPoint(x: rect.midX, y: rect.maxY)
                ))

                var mullion = Path()
                mullion.move(to: CGPoint(x: rect.midX, y: rect.minY))
                mullion.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
                mullion.move(to: CGPoint(x: rect.minX, y: rect.midY))
                mullion.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
                ctx.stroke(mullion, with: .color(wallColor), lineWidth: 2)
                ctx.stroke(Path(roundedRect: rect, cornerRadius: 3), with: .color(.black.opacity(0.4)), lineWidth: 1.4)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct FactoryTrussRow: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let trussY = size.height * 0.29
                let beamColor = Color(red: 0.15, green: 0.17, blue: 0.19)

                ctx.fill(Path(CGRect(x: 0, y: trussY, width: size.width, height: 6)), with: .color(beamColor))
                ctx.stroke(Path(CGRect(x: 0, y: trussY, width: size.width, height: 6)),
                           with: .color(.white.opacity(0.08)), lineWidth: 1)

                let lampCount = 4
                for i in 0..<lampCount {
                    let x = size.width * (CGFloat(i) + 0.5) / CGFloat(lampCount)
                    let cableTop = trussY + 6
                    let shadeY = cableTop + size.height * 0.05

                    var cable = Path()
                    cable.move(to: CGPoint(x: x, y: cableTop))
                    cable.addLine(to: CGPoint(x: x, y: shadeY))
                    ctx.stroke(cable, with: .color(beamColor), lineWidth: 1.6)

                    var shade = Path()
                    shade.move(to: CGPoint(x: x - 4, y: shadeY))
                    shade.addLine(to: CGPoint(x: x + 4, y: shadeY))
                    shade.addLine(to: CGPoint(x: x + 13, y: shadeY + 12))
                    shade.addLine(to: CGPoint(x: x - 13, y: shadeY + 12))
                    shade.closeSubpath()
                    ctx.fill(shade, with: .color(beamColor))
                    ctx.stroke(shade, with: .color(.white.opacity(0.12)), lineWidth: 1)

                    let flicker = 0.75 + 0.25 * sin(t * 2.4 + Double(i) * 1.7)
                    let bulb = CGPoint(x: x, y: shadeY + 13)
                    let glowRect = CGRect(x: bulb.x - 20, y: bulb.y - 4, width: 40, height: size.height * 0.24)
                    ctx.fill(Path(ellipseIn: glowRect), with: .radialGradient(
                        Gradient(colors: [Theme.cleanCyan.opacity(0.22 * flicker), .clear]),
                        center: bulb, startRadius: 2, endRadius: 46
                    ))
                    ctx.fill(Path(ellipseIn: CGRect(x: bulb.x - 3, y: bulb.y - 3, width: 6, height: 6)),
                             with: .color(Theme.cleanCyan.opacity(flicker)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct ConveyorBeltStructure: View {
    var beltYFrac: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let y = size.height * beltYFrac
                let beltHeight: CGFloat = 14
                let beltRect = CGRect(x: 0, y: y - beltHeight / 2, width: size.width, height: beltHeight)
                let rubber = Color(red: 0.08, green: 0.08, blue: 0.09)
                let rail = Color(red: 0.32, green: 0.34, blue: 0.36)

                ctx.fill(Path(beltRect), with: .color(rubber))

                let chevronW: CGFloat = 26
                let offset = CGFloat((t * 90).truncatingRemainder(dividingBy: Double(chevronW)))
                var x = -chevronW + offset
                while x < size.width {
                    var chevron = Path()
                    chevron.move(to: CGPoint(x: x, y: beltRect.minY + 2))
                    chevron.addLine(to: CGPoint(x: x + chevronW * 0.5, y: beltRect.maxY - 2))
                    chevron.addLine(to: CGPoint(x: x + chevronW * 0.5 + 4, y: beltRect.maxY - 2))
                    chevron.addLine(to: CGPoint(x: x + 4, y: beltRect.minY + 2))
                    chevron.closeSubpath()
                    ctx.fill(chevron, with: .color(.black.opacity(0.35)))
                    x += chevronW
                }

                ctx.fill(Path(CGRect(x: 0, y: beltRect.minY, width: size.width, height: 1.5)), with: .color(rail))
                ctx.fill(Path(CGRect(x: 0, y: beltRect.maxY - 1.5, width: size.width, height: 1.5)), with: .color(rail))

                for edgeX in [CGFloat(0), size.width] {
                    let rollerRect = CGRect(x: edgeX - 10, y: y - 10, width: 20, height: 20)
                    ctx.fill(Path(ellipseIn: rollerRect), with: .color(rail))
                    ctx.stroke(Path(ellipseIn: rollerRect), with: .color(.black.opacity(0.4)), lineWidth: 1.5)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct FactoryFloorPanels: View {
    var beltYFrac: CGFloat

    var body: some View {
        Canvas { ctx, size in
            let floorTop = size.height * beltYFrac + 10
            let floorColor = Color(red: 0.06, green: 0.07, blue: 0.09)
            let seamColor = Color.white.opacity(0.05)
            let floorRect = CGRect(x: 0, y: floorTop, width: size.width, height: size.height - floorTop)

            ctx.fill(Path(floorRect), with: .linearGradient(
                Gradient(colors: [floorColor, floorColor.mix(with: .black, amount: 0.4)]),
                startPoint: CGPoint(x: 0, y: floorTop), endPoint: CGPoint(x: 0, y: size.height)
            ))

            let reflectionRect = CGRect(x: 0, y: floorTop, width: size.width, height: min(26, floorRect.height))
            ctx.fill(Path(reflectionRect), with: .linearGradient(
                Gradient(colors: [Theme.cleanCyan.opacity(0.08), .clear]),
                startPoint: CGPoint(x: 0, y: floorTop), endPoint: CGPoint(x: 0, y: reflectionRect.maxY)
            ))

            let panelW = size.width / 9
            var x: CGFloat = panelW
            while x < size.width {
                var seam = Path()
                seam.move(to: CGPoint(x: x, y: floorTop))
                seam.addLine(to: CGPoint(x: x, y: size.height))
                ctx.stroke(seam, with: .color(seamColor), lineWidth: 1)

                for riveted in [floorTop + 6, size.height - 6] {
                    ctx.fill(Path(ellipseIn: CGRect(x: x - 1.6, y: riveted - 1.6, width: 3.2, height: 3.2)),
                             with: .color(.white.opacity(0.1)))
                }
                x += panelW
            }
        }
        .allowsHitTesting(false)
    }
}

private struct FactorySideColumns: View {
    var body: some View {
        Canvas { ctx, size in
            let beamColor = Color(red: 0.11, green: 0.13, blue: 0.15)
            let highlight = Color.white.opacity(0.06)
            let columnW: CGFloat = size.width * 0.045

            for edgeX in [CGFloat(0), size.width - columnW] {
                let rect = CGRect(x: edgeX, y: 0, width: columnW, height: size.height)
                ctx.fill(Path(rect), with: .linearGradient(
                    Gradient(colors: [beamColor.opacity(0.95), beamColor.opacity(0.7)]),
                    startPoint: CGPoint(x: rect.minX, y: 0), endPoint: CGPoint(x: rect.maxX, y: 0)
                ))
                ctx.stroke(Path(CGRect(x: rect.maxX - 1.5, y: 0, width: 1.5, height: size.height)),
                           with: .color(highlight), lineWidth: 1.5)

                var y: CGFloat = 30
                while y < size.height {
                    for dx: CGFloat in [6, columnW - 6] {
                        ctx.fill(Path(ellipseIn: CGRect(x: rect.minX + dx - 2, y: y - 2, width: 4, height: 4)),
                                 with: .color(.black.opacity(0.4)))
                    }
                    y += 46
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct SteamVentCanvas: View {
    var xFrac: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let x = size.width * xFrac
                let ventY = size.height * 0.97
                let ventColor = Color(red: 0.13, green: 0.15, blue: 0.17)

                ctx.fill(Path(roundedRect: CGRect(x: x - 10, y: ventY - 6, width: 20, height: 12), cornerRadius: 2),
                         with: .color(ventColor))

                let cycle = 2.6
                let phase = (t + Double(xFrac) * 5).truncatingRemainder(dividingBy: cycle) / cycle
                guard phase < 0.75 else { return }
                let rise = CGFloat(phase / 0.75)
                let puffY = ventY - 6 - rise * size.height * 0.16
                let puffR = 10 + rise * 22
                let puffOpacity = (1 - rise) * 0.22

                ctx.fill(Path(ellipseIn: CGRect(x: x - puffR / 2, y: puffY - puffR / 2, width: puffR, height: puffR)),
                         with: .color(.white.opacity(puffOpacity)))
            }
        }
        .allowsHitTesting(false)
    }
}
