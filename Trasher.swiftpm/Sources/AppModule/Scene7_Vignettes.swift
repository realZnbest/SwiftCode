import SwiftUI

/// A shared shape for every short (~5-6s) story beat added between the
/// original six scenes: full-bleed visuals, an optional bottle, one line of
/// text that fades in then out, then an automatic advance. Ten scenes
/// repeating that fade/hold/advance boilerplate individually would be ten
/// places to get the timing subtly wrong — one wrapper keeps them
/// consistent and easy to re-time as a group.
struct VignetteScene<Content: View>: View {
    @EnvironmentObject var game: GameState

    var line: String
    var accessibilityText: String
    var hold: Double = 5.0
    var vignetteStrength: Double = 0.55
    var showBottle: Bool = true
    var bottleWidth: CGFloat = 60
    var bottleHeight: CGFloat = 148
    var bottlePosition: UnitPoint = UnitPoint(x: 0.5, y: 0.55)
    var bottleShowEyes: Bool = false
    var bottleGlow: Double = 0
    var bottleTilt: Angle = .zero
    var textPosition: UnitPoint = UnitPoint(x: 0.5, y: 0.86)
    var content: (CGSize) -> Content
    var onFinish: () -> Void

    @State private var showText = false

    private var reduceMotion: Bool { game.reduceMotion }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                content(size)

                if showBottle {
                    BottleView(
                        vibrancy: game.vibrancy, dirt: game.grime, showEyes: bottleShowEyes,
                        glow: bottleGlow, width: bottleWidth, height: bottleHeight, tilt: bottleTilt
                    )
                    .position(x: bottlePosition.x * size.width, y: bottlePosition.y * size.height)
                }

                if showText {
                    Text(line)
                        .font(Theme.line(22))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 26)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: Capsule())
                        .transition(.opacity)
                        .position(x: textPosition.x * size.width, y: textPosition.y * size.height)
                }

                Vignette(strength: vignetteStrength)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
        .onAppear(perform: run)
    }

    private func run() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(reduceMotion ? 0.3 : 0.5))
            withAnimation(.easeIn(duration: 0.5)) { showText = true }
            try? await Task.sleep(for: .seconds(reduceMotion ? hold * 0.6 : hold))
            withAnimation(.easeOut(duration: 0.35)) { showText = false }
            try? await Task.sleep(for: .seconds(0.3))
            onFinish()
        }
    }
}

// MARK: - 1. Factory origin (before the opening hand-drop)

struct FactoryOriginScene: View {
    @EnvironmentObject var game: GameState

    // The machine — and so the bottle's birth point — sits toward the left
    // of the line, leaving the rest of the belt for it to travel along
    // before it exits, rather than being born dead-center.
    private let birthXFrac: CGFloat = 0.25

    // The hero bottle doesn't exist until the machine produces it — it
    // starts invisible, pops into being at the machine's head the instant
    // it stamps down, then drops to the conveyor line and finally slides
    // off to the right.
    @State private var heroBottleX: CGFloat = 0.25
    @State private var heroBottleY: CGFloat = 0.77
    @State private var heroBottleVisible = false
    @State private var heroBottleScale: CGFloat = 0.3
    // The capping head's own Y position (as a fraction of scene height) —
    // not a composite-assembly center. Idle sits fully above the visible
    // frame (negative) so the machine genuinely isn't there yet when the
    // scene opens, instead of its head already peeking in at the top edge;
    // producing extends it down to the birth point.
    @State private var nozzleY: CGFloat = -0.03
    @State private var flashOpacity: Double = 0
    @State private var bgBottleOffset: CGFloat = 0

    var body: some View {
        VignetteScene(
            line: "มันถูกผลิตมา เพื่อใช้เพียงครั้งเดียว",
            accessibilityText: "A factory line. The bottle is filled and sealed, brand new.",
            // Timed to the birth-and-travel sequence below (roughly 6.1s
            // from appearing to sliding off the right edge, including the
            // 2s opening pause) so the scene cuts away right after the
            // bottle exits, instead of lingering on an empty belt.
            hold: 5.3,
            showBottle: false, // We'll render it ourselves in the ZStack
            textPosition: UnitPoint(x: 0.5, y: 0.65),
            content: { size in
                ZStack {
                    LinearGradient(colors: [Theme.deepNavy, Theme.nearBlack], startPoint: .top, endPoint: .bottom)
                    FactorySilhouetteCanvas(reduceMotion: game.reduceMotion).opacity(0.6)
                    ConveyorBeltCanvas(reduceMotion: game.reduceMotion)

                    // Continuous Background Bottles
                    HStack(spacing: 200) {
                        ForEach(0..<12, id: \.self) { _ in
                            BottleView(vibrancy: 1, dirt: 0, showEyes: false, glow: 0, width: 40, height: 98, tilt: .zero)
                                .opacity(0.3)
                        }
                    }
                    .offset(x: bgBottleOffset)
                    // 0.82 * size.height is the hero bottle center. 
                    // To match the hero bottle's bottom edge (148/2 = 74 down), 
                    // we shift the 98-height bg bottles down by 25 (74 - 49).
                    .position(x: size.width * 0.5, y: size.height * 0.82 + 25)
                    .onAppear {
                        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                            bgBottleOffset = 240
                        }
                    }

                    // Hero Bottle — doesn't exist until the machine produces it.
                    BottleView(
                        vibrancy: 1, dirt: 0, showEyes: false,
                        glow: 0.35, width: 60, height: 148, tilt: .zero
                    )
                    .scaleEffect(heroBottleScale)
                    .opacity(heroBottleVisible ? 1 : 0)
                    .position(x: size.width * heroBottleX, y: size.height * heroBottleY)

                    // Capping machine: a gantry-mounted piston that
                    // stamps down and is the bottle's point of origin. The
                    // housing stays fixed just above the frame and the
                    // shaft always spans the gap down to the head, so it
                    // can never look like a short rod floating free of
                    // anything above it.
                    CappingMachineView(size: size, xFrac: birthXFrac, headY: size.height * nozzleY, capping: flashOpacity > 0)

                    // Cap Flash
                    if flashOpacity > 0 {
                        Circle()
                            .fill(Theme.neonCyan)
                            .frame(width: 150, height: 150)
                            .blur(radius: 30)
                            .opacity(flashOpacity)
                            .position(x: size.width * birthXFrac, y: size.height * 0.77)
                    }

                    LightRaysCanvas(color: Theme.cleanCyan, count: 3, reduceMotion: game.reduceMotion)
                    SparkleCanvas(count: 18, color: .white, reduceMotion: game.reduceMotion).opacity(0.4)
                }
                .onAppear(perform: runAnimation)
            },
            onFinish: { game.advanceFromFactoryOrigin() }
        )
    }

    private func runAnimation() {
        let scale = game.reduceMotion ? 0.6 : 1.0

        Task { @MainActor in
            // 1. Only the background bottles run the line at first — the
            // hero bottle doesn't exist yet.
            try? await Task.sleep(for: .seconds(2.0 * scale))

            // 2. The machine stamps down to its birth point — 10% quicker
            // than its previous pace (response lowered from 0.8 to 0.72).
            withAnimation(.spring(response: 0.72 * scale, dampingFraction: 0.75)) {
                nozzleY = 0.77
            }
            try? await Task.sleep(for: .seconds(0.9 * scale))

            // 3. Flash & sound — the bottle is produced right at the head.
            // The flash itself stays quick (it's a spark, not a motion), but
            // the bottle eases into being rather than popping instantly.
            game.sound.success()
            withAnimation(.easeOut(duration: 0.1)) {
                flashOpacity = 0.8
            }
            withAnimation(.spring(response: 0.6 * scale, dampingFraction: 0.65)) {
                heroBottleVisible = true
                heroBottleScale = 1.0
            }
            try? await Task.sleep(for: .seconds(0.1))
            withAnimation(.easeIn(duration: 0.4)) {
                flashOpacity = 0
            }

            // 4. The machine retracts fully out of frame as the new bottle
            // settles onto the conveyor — also 10% quicker.
            try? await Task.sleep(for: .seconds(0.3 * scale))
            withAnimation(.easeIn(duration: 0.81 * scale)) {
                nozzleY = -0.03
            }
            withAnimation(.interpolatingSpring(stiffness: 70, damping: 14)) {
                heroBottleY = 0.82
            }

            // 5. Bottle travels the length of the belt and slides out to
            // the right — slow and steady once moving, but without a long
            // dead pause between settling onto the belt and setting off.
            try? await Task.sleep(for: .seconds(0.4 * scale))
            withAnimation(.easeInOut(duration: 2.4 * scale)) {
                heroBottleX = 1.2
            }
        }
    }
}

/// A capping fixture that reads as actual machinery instead of an
/// abstract rectangle-and-capsule stamp: a gantry housing bolted to the
/// rail above, a hydraulic piston shaft banded with a hazard stripe, and a
/// glowing capping head that brightens at the moment of contact.
///
/// The housing is pinned at a fixed point just above the visible frame —
/// it never moves — and the shaft is drawn to always span exactly from the
/// housing down to `headY`. A shaft with an independent fixed length used
/// to visibly detach from the housing whenever the head traveled further
/// than that length allowed, reading as a short bar floating in mid-air
/// instead of a piston reaching down from something mounted above.
private struct CappingMachineView: View {
    var size: CGSize
    var xFrac: CGFloat = 0.5
    var headY: CGFloat
    var capping: Bool

    private let housingCenterY: CGFloat = -14
    private let housingHeight: CGFloat = 22
    private let headHeight: CGFloat = 17

    var body: some View {
        let shaftTop = housingCenterY + housingHeight / 2
        let shaftBottom = headY - headHeight / 2
        let shaftLen = max(4, shaftBottom - shaftTop)
        let shaftCenterY = shaftTop + shaftLen / 2
        let midX = size.width * xFrac

        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(LinearGradient(colors: [Color(white: 0.38), Color(white: 0.16)], startPoint: .top, endPoint: .bottom))
                .frame(width: 48, height: housingHeight)
                .overlay(
                    HStack(spacing: 30) {
                        Circle().fill(Color.black.opacity(0.55)).frame(width: 4, height: 4)
                        Circle().fill(Color.black.opacity(0.55)).frame(width: 4, height: 4)
                    }
                )
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.white.opacity(0.15), lineWidth: 1))
                .position(x: midX, y: housingCenterY)

            ZStack {
                Rectangle()
                    .fill(LinearGradient(colors: [Color(white: 0.6), Color(white: 0.28), Color(white: 0.55)],
                                          startPoint: .leading, endPoint: .trailing))
                    .frame(width: 18, height: shaftLen)

                HazardStripeBand()
                    .frame(width: 22, height: 9)
                    .offset(y: -shaftLen * 0.18)
            }
            .position(x: midX, y: shaftCenterY)

            ZStack {
                Capsule()
                    .fill(LinearGradient(colors: [Theme.cleanCyan, Theme.cleanCyan.opacity(0.55)],
                                          startPoint: .top, endPoint: .bottom))
                    .frame(width: 52, height: headHeight)
                Capsule().stroke(Color.white.opacity(0.55), lineWidth: 1.3).frame(width: 52, height: headHeight)
            }
            .glow(Theme.cleanCyan, radius: capping ? 16 : 5, opacity: capping ? 0.9 : 0.45)
            .position(x: midX, y: headY)
        }
    }
}

/// A repeating black/amber diagonal hazard stripe, used on the capping
/// piston to read as an industrial safety marking rather than a bare rod.
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

// MARK: - 2. Storm drain tunnel (after choosing the drain)

struct StormDrainTunnelScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "ดำดิ่งสู่ความมืดมิด จนไม่มีใครมองเห็น",
            accessibilityText: "A storm drain tunnel. The bottle tumbles through rushing water, out of sight.",
            vignetteStrength: 0.7,
            showBottle: false,
            content: { size in
                ZStack {
                    Theme.nearBlack
                    Canvas { ctx, canvasSize in
                        for i in 0..<5 {
                            let r = canvasSize.width * (0.15 + CGFloat(i) * 0.18)
                            ctx.stroke(
                                Path(ellipseIn: CGRect(x: canvasSize.width / 2 - r / 2, y: canvasSize.height / 2 - r / 2, width: r, height: r)),
                                with: .color(Theme.cleanCyan.opacity(0.09)), lineWidth: 2
                            )
                        }
                    }
                    BubbleCanvas(count: 22, color: .white, reduceMotion: game.reduceMotion).opacity(0.5)
                    SmokeCanvas(intensity: 0.6, color: Theme.murkGreen, reduceMotion: game.reduceMotion)

                    TimelineView(.animation(minimumInterval: game.reduceMotion ? 1 : 1.0 / 30)) { context in
                        let t = game.reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
                        BottleView(
                            vibrancy: game.vibrancy, dirt: game.grime, showEyes: false,
                            width: 56, height: 138, tilt: .degrees(game.reduceMotion ? 25 : t * 230)
                        )
                        .position(x: size.width * 0.5, y: size.height * 0.55)
                    }
                }
            },
            onFinish: { game.advanceFromStormDrainTunnel() }
        )
    }
}

// MARK: - 3. Second bottle mirror (right before the canal)

struct SecondBottleMirrorScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "ไม่ใช่ทุกชิ้นที่จะออกมาได้",
            accessibilityText: "The canal. Another bottle, snagged in debris, will not move again.",
            bottlePosition: UnitPoint(x: 0.38, y: 0.48),
            bottleShowEyes: true,
            content: { size in
                ZStack {
                    LinearGradient(
                        colors: [Color(red: 0.04, green: 0.13, blue: 0.16), Color(red: 0.02, green: 0.05, blue: 0.06)],
                        startPoint: .top, endPoint: .bottom
                    )
                    BubbleCanvas(count: 14, color: Theme.murkBrown, reduceMotion: game.reduceMotion)
                    SmokeCanvas(intensity: 0.5, color: Theme.murkGreen, reduceMotion: game.reduceMotion)
                    FishSilhouettesCanvas(darkness: 0.6, reduceMotion: game.reduceMotion)

                    // A second, motionless bottle — tangled and desaturated —
                    // as a quiet contrast to the one still drifting free.
                    BottleView(vibrancy: 0.25, dirt: 0.8, showEyes: false, width: 48, height: 118)
                        .saturation(0.2)
                        .opacity(0.55)
                        .rotationEffect(.degrees(35))
                        .position(x: size.width * 0.68, y: size.height * 0.62)
                }
            },
            onFinish: { game.advanceFromSecondBottleMirror() }
        )
    }
}

// MARK: - 4. Night into day (after the canal fork resolves toward recycling)

struct NightIntoDayScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "เมื่อเวลาผ่านไป",
            accessibilityText: "Dawn breaks over the water. Time keeps moving forward.",
            content: { size in
                ZStack {
                    LinearGradient(
                        colors: [Color(red: 0.09, green: 0.13, blue: 0.28), Color(red: 0.72, green: 0.55, blue: 0.4)],
                        startPoint: .top, endPoint: .bottom
                    )
                    GlowOrb(color: Theme.neonAmber, size: 130)
                        .position(x: size.width * 0.78, y: size.height * 0.62)
                    CloudDriftCanvas(reduceMotion: game.reduceMotion).opacity(0.6)
                    SparkleCanvas(count: 20, color: .white, reduceMotion: game.reduceMotion).opacity(0.25)
                }
            },
            onFinish: { game.advanceFromNightIntoDay() }
        )
    }
}

// MARK: - 5. Fishing net rescue (before the recycling facility)

struct FishingNetRescueScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "มีใครบางคนหยิบมันขึ้นมา",
            accessibilityText: "A hand net reaches into the water and lifts the bottle out.",
            bottlePosition: UnitPoint(x: 0.5, y: 0.46),
            bottleShowEyes: true,
            content: { size in
                ZStack {
                    LinearGradient(
                        colors: [Color(red: 0.06, green: 0.24, blue: 0.28), Color(red: 0.03, green: 0.1, blue: 0.12)],
                        startPoint: .top, endPoint: .bottom
                    )
                    LightRaysCanvas(color: Theme.cleanCyan, count: 4, reduceMotion: game.reduceMotion)
                    BubbleCanvas(count: 16, color: .white, reduceMotion: game.reduceMotion)
                    FishSilhouettesCanvas(darkness: 0.15, reduceMotion: game.reduceMotion)

                    HandNetCanvas()
                }
            },
            onFinish: { game.advanceFromFishingNetRescue() }
        )
    }
}

/// A real hand net — a rim, a handle reaching off-frame (implying someone
/// holding it just outside the shot), and a diamond mesh that actually sags
/// into a pouch under its own weight — instead of two flat sets of straight
/// lines crossing each other.
private struct HandNetCanvas: View {
    var body: some View {
        Canvas { ctx, size in
            // The pouch's bottom sits below the bottle's own position in
            // FishingNetRescueScene (bottlePosition: 0.5, 0.46; default
            // bottleHeight 148 means its bottom edge lands around +0.46 +
            // 74pt) so the bottle rests inside the bag, cradled by mesh
            // behind and beneath it — converging the mesh exactly at the
            // bottle's own center instead pinched to a point right through
            // its middle, reading as speared rather than caught.
            let bottleCenter = CGPoint(x: size.width * 0.5, y: size.height * 0.46)
            let catchPoint = CGPoint(x: bottleCenter.x, y: bottleCenter.y + 60)
            let hoopCenter = CGPoint(x: size.width * 0.62, y: size.height * 0.06)
            let hoopRadius = size.width * 0.22
            let hoopRect = CGRect(x: hoopCenter.x - hoopRadius, y: hoopCenter.y - hoopRadius * 0.38,
                                   width: hoopRadius * 2, height: hoopRadius * 0.76)

            // Handle, reaching off the top-right corner as if held from
            // outside the frame.
            var handle = Path()
            handle.move(to: CGPoint(x: hoopRect.maxX - hoopRadius * 0.25, y: hoopRect.minY + hoopRadius * 0.1))
            handle.addLine(to: CGPoint(x: size.width * 1.08, y: -size.height * 0.08))
            ctx.stroke(handle, with: .color(Color(red: 0.5, green: 0.44, blue: 0.36)), lineWidth: 5)
            ctx.stroke(handle, with: .color(Color(red: 0.68, green: 0.6, blue: 0.5).opacity(0.6)), lineWidth: 1.5)

            // Diamond mesh sagging into a pouch below the hoop, pinching
            // down to the catch point — instead of a flat triangle of
            // straight crossing lines that don't converge on anything.
            let cols = 7
            let rows = 5
            func meshPoint(_ col: Int, _ row: Int) -> CGPoint {
                let colFrac = CGFloat(col) / CGFloat(cols)
                let rowFrac = CGFloat(row) / CGFloat(rows)
                let rimX = hoopRect.minX + hoopRect.width * colFrac
                let rimY = hoopRect.midY
                // A rounded, never-fully-pinched bottom (minSpread keeps
                // some width even at rowFrac 1) so the pouch reads as a bag
                // wrapping around the bottle, not a spike converging to a
                // single point through it.
                let minSpread = hoopRadius * 0.3
                let spread = minSpread + hoopRadius * 0.4 * (1 - rowFrac)
                let pouchX = catchPoint.x + (colFrac - 0.5) * spread
                let x = rimX + (pouchX - rimX) * rowFrac
                let y = rimY + (catchPoint.y - rimY) * (rowFrac * rowFrac)
                return CGPoint(x: x, y: y)
            }
            for row in 0...rows {
                var p = Path()
                for col in 0...cols {
                    let pt = meshPoint(col, row)
                    if col == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
                ctx.stroke(p, with: .color(.white.opacity(0.3 - Double(row) * 0.03)), lineWidth: 1.1)
            }
            for col in 0...cols {
                var p = Path()
                for row in 0...rows {
                    let pt = meshPoint(col, row)
                    if row == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
                ctx.stroke(p, with: .color(.white.opacity(0.24)), lineWidth: 1.0)
            }

            // Rim on top of the mesh so the net reads as opening toward the
            // viewer, not a flat grid floating in space.
            ctx.stroke(Path(ellipseIn: hoopRect), with: .color(.white.opacity(0.6)), lineWidth: 3)
        }
    }
}

// MARK: - 6. Sorting line (facility approach, before cleaning/shredding)

struct SortingLineScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "มันถูกแยกออกมาจากสิ่งแปลกปลอมทั้งหมด",
            accessibilityText: "A sorting line. Optical scanners separate plastic from glass and metal.",
            bottlePosition: UnitPoint(x: 0.5, y: 0.8),
            content: { size in
                ZStack {
                    LinearGradient(colors: [Theme.deepNavy, Theme.nearBlack], startPoint: .top, endPoint: .bottom)
                    FactorySilhouetteCanvas(reduceMotion: game.reduceMotion).opacity(0.6)
                    ConveyorBeltCanvas(reduceMotion: game.reduceMotion)
                    LightRaysCanvas(color: Theme.cleanCyan, count: 3, reduceMotion: game.reduceMotion)

                    TimelineView(.animation(minimumInterval: game.reduceMotion ? 1 : 1.0 / 30)) { context in
                        let t = game.reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
                        let x = size.width * (0.2 + 0.6 * (0.5 + 0.5 * sin(t * 1.3)))
                        Rectangle()
                            .fill(LinearGradient(colors: [.clear, Theme.cleanCyan.opacity(0.55), .clear], startPoint: .top, endPoint: .bottom))
                            .frame(width: 4, height: size.height)
                            .position(x: x, y: size.height / 2)
                            .blur(radius: 2)
                    }
                }
            },
            onFinish: { game.advanceFromSortingLine() }
        )
    }
}

// MARK: - 7. Pellet reveal (right after finishing recycling)

struct PelletRevealScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "ส่วนชิ้นนี้มันไม่ได้เหมือนเดิม แต่ก็ไม่ได้หายไปไหน",
            accessibilityText: "Shredded plastic reforms into small raw pellets, ready to be shaped again.",
            showBottle: false,
            content: { size in
                ZStack {
                    LinearGradient(
                        colors: [Theme.nearBlack.mix(with: Theme.freshGreen, amount: 0.18), Theme.nearBlack],
                        startPoint: .top, endPoint: .bottom
                    )
                    LightRaysCanvas(color: Theme.freshGreen, count: 3, reduceMotion: game.reduceMotion)
                    SparkleCanvas(count: 36, color: Theme.cleanWhite, reduceMotion: game.reduceMotion)

                    let moundCenter = CGPoint(x: size.width * 0.5, y: size.height * 0.6)
                    let targets: [CGPoint] = (0..<50).map { i in
                        let a = Double(rnd(i, 500)) * 2 * .pi
                        let r = rnd(i, 501) * 32
                        return CGPoint(x: moundCenter.x + CGFloat(cos(a)) * r, y: moundCenter.y + CGFloat(sin(a)) * r * 0.5)
                    }
                    FlakeField(
                        count: 50, scatterCenter: moundCenter, scatterRadius: 90,
                        target: targets, mix: 1, color: Theme.freshGreen.opacity(0.9), opacity: 0.9
                    )
                }
            },
            onFinish: { game.advanceFromPelletReveal() }
        )
    }
}

// MARK: - 8. Truck delivery (carrying the reclaimed material out)

struct TruckDeliveryScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "เส้นทางนี้จะทำให้มันเปลี่ยนไป",
            accessibilityText: "A recycling truck drives down a night road, carrying the reclaimed material out into the city.",
            showBottle: false,
            // The road sits low and the truck low with it, so the caption
            // moves up near the skyline instead of competing with either.
            textPosition: UnitPoint(x: 0.5, y: 0.15),
            content: { size in
                // The truck's own wheel geometry (see RecyclingTruckShape)
                // puts their bottom edge 54pt below the shape's center, so
                // the truck is placed relative to the road's top edge —
                // not a separately-guessed fraction — to guarantee contact
                // instead of floating above or sinking into the road.
                let roadTopY = size.height * 0.86
                return ZStack {
                    LinearGradient(colors: [Theme.deepNavy, Theme.nearBlack], startPoint: .top, endPoint: .bottom)
                    SkylineCanvas().opacity(0.3)
                    NeonStreakField(colors: [Theme.neonCyan, Theme.neonAmber], reduceMotion: game.reduceMotion)

                    RoadsideTreesCanvas(roadTopY: roadTopY)

                    Rectangle()
                        .fill(Color(red: 0.06, green: 0.06, blue: 0.08))
                        .frame(height: size.height - roadTopY)
                        .position(x: size.width * 0.5, y: roadTopY + (size.height - roadTopY) / 2)
                    RoadLinesCanvas(roadTopY: roadTopY, reduceMotion: game.reduceMotion)
                        .frame(height: size.height)

                    StreetLampRow(roadTopY: roadTopY, direction: 1)
                        .frame(height: size.height)

                    TimelineView(.animation(minimumInterval: game.reduceMotion ? 1 : 1.0 / 30)) { context in
                        let t = game.reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
                        let bounce = game.reduceMotion ? 0 : sin(t * 9) * 1.6
                        RecyclingTruckShape()
                            .position(x: size.width * 0.5, y: roadTopY - 54 + bounce)
                    }
                }
            },
            onFinish: { game.advanceFromTruckDelivery() }
        )
    }
}

/// A side-profile recycling truck: a cargo container carrying the
/// recycling glyph, a cab with a windshield, two wheels, and a headlight —
/// built from plain shapes so it reads as a specific vehicle instead of an
/// ambiguous glowing rectangle.
private struct RecyclingTruckShape: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: [Theme.cleanCyan, Theme.cleanCyan.opacity(0.55)], startPoint: .top, endPoint: .bottom))
                .frame(width: 108, height: 76)
                .overlay(
                    Image(systemName: "arrow.3.trianglepath")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white.opacity(0.92))
                )
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.25), lineWidth: 1.5))
                .offset(x: -28, y: -6)

            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: [Color(white: 0.8), Color(white: 0.5)], startPoint: .top, endPoint: .bottom))
                .frame(width: 54, height: 52)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.cleanCyan.opacity(0.55))
                        .frame(width: 30, height: 22)
                        .offset(y: -11)
                )
                .offset(x: 52, y: 4)

            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black.opacity(0.55))
                .frame(width: 168, height: 8)
                .offset(y: 33)

            wheel.offset(x: -34, y: 40)
            wheel.offset(x: 44, y: 40)

            Circle().fill(Theme.neonAmber.opacity(0.9)).frame(width: 8, height: 8)
                .glow(Theme.neonAmber, radius: 6, opacity: 0.6)
                .offset(x: 78, y: 10)
        }
    }

    private var wheel: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Color(white: 0.3), .black], center: .center, startRadius: 0, endRadius: 15))
                .frame(width: 28, height: 28)
            Circle().fill(Color(white: 0.6)).frame(width: 9, height: 9)
        }
    }
}

/// Scrolling dashed lane markings so the truck reads as driving down a
/// road rather than floating in place.
struct RoadLinesCanvas: View {
    var roadTopY: CGFloat
    var reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1.0 / 20)) { context in
            Canvas { ctx, size in
                let dash: CGFloat = 40
                let gap: CGFloat = 34
                let cycle = dash + gap
                let y = roadTopY + 16
                // The truck's cab faces right (its front), so the road
                // needs to scroll left underneath it to read as driving
                // forward — the ground recedes behind a moving vehicle,
                // it doesn't slide the same direction the vehicle faces.
                let offset = reduceMotion ? 0 : CGFloat((context.date.timeIntervalSinceReferenceDate * 260).truncatingRemainder(dividingBy: Double(cycle)))
                var x = -offset
                while x < size.width {
                    ctx.fill(Path(roundedRect: CGRect(x: x, y: y, width: dash, height: 5), cornerRadius: 2),
                             with: .color(.white.opacity(0.4)))
                    x += cycle
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - 9. Community cleanup (after the montage, before the park)

struct CommunityCleanupScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "มีมือบางคู่ เลือกที่จะหยุดไม่ให้มันต้องมาเริ่มเส้นทางนี้อีก",
            accessibilityText: "Volunteers clean a riverbank, picking up litter before it starts this same journey.",
            showBottle: false,
            content: { size in
                ZStack {
                    LinearGradient(colors: [Color(red: 0.55, green: 0.8, blue: 0.95), Color(red: 0.78, green: 0.92, blue: 0.72)],
                                   startPoint: .top, endPoint: .bottom)
                    CloudDriftCanvas(reduceMotion: game.reduceMotion)
                    TreeLineCanvas()
                    SparkleCanvas(count: 14, color: .white, reduceMotion: game.reduceMotion).opacity(0.3)

                    // PersonFigure is 68pt tall; offsetting by half that
                    // from TreeLineCanvas's own ground line (baseY = 0.78)
                    // plants their feet on the grass instead of hovering.
                    HStack(alignment: .bottom, spacing: size.width * 0.13) {
                        PersonFigure(shirt: Theme.neonPink, bending: false)
                        PersonFigure(shirt: Theme.cleanCyan, bending: false)
                        PersonFigure(shirt: Theme.neonAmber, bending: false)
                    }
                    .position(x: size.width * 0.5, y: size.height * 0.78 - 34)
                }
            },
            onFinish: { game.advanceFromCommunityCleanup() }
        )
    }
}

// MARK: - 10. Delivery truck (factory → city distribution)

/// ~5s auto-advancing scene. A delivery truck drives across the city at
/// night carrying bottles from the factory to retail. Uses the same road
/// treatment as TruckDeliveryScene but with a distinct cargo-truck shape
/// (white box truck with bottle icon instead of recycling arrows).
struct DeliveryTruckScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "กำลังเดินทางไปที่ไหนสักแห่ง",
            accessibilityText: "A delivery truck drives through the city at night, carrying bottles from the factory.",
            showBottle: false,
            textPosition: UnitPoint(x: 0.5, y: 0.15),
            content: { size in
                let roadTopY = size.height * 0.86
                return ZStack {
                    LinearGradient(colors: [Theme.deepNavy, Theme.nearBlack], startPoint: .top, endPoint: .bottom)
                    SkylineCanvas().opacity(0.3)
                    NeonStreakField(colors: [Theme.neonAmber, Theme.neonPink, Theme.neonCyan], reduceMotion: game.reduceMotion)

                    RoadsideTreesCanvas(roadTopY: roadTopY)

                    Rectangle()
                        .fill(Color(red: 0.06, green: 0.06, blue: 0.08))
                        .frame(height: size.height - roadTopY)
                        .position(x: size.width * 0.5, y: roadTopY + (size.height - roadTopY) / 2)
                    RoadLinesCanvas(roadTopY: roadTopY, reduceMotion: game.reduceMotion)
                        .frame(height: size.height)

                    StreetLampRow(roadTopY: roadTopY, direction: 1)
                        .frame(height: size.height)

                    TimelineView(.animation(minimumInterval: game.reduceMotion ? 1 : 1.0 / 30)) { context in
                        let t = game.reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
                        let bounce = game.reduceMotion ? 0 : sin(t * 9) * 1.6
                        DeliveryTruckShape()
                            .position(x: size.width * 0.5, y: roadTopY - 54 + bounce)
                    }

                    SparkleCanvas(count: 12, color: .white, reduceMotion: game.reduceMotion).opacity(0.25)
                }
            },
            onFinish: { game.advanceFromDeliveryTruck() }
        )
    }
}

/// A side-profile delivery/cargo truck: a tall white box trailer with a
/// water-bottle icon on the side, a cab, two wheel sets, and headlights.
/// Distinct from RecyclingTruckShape — this is a commercial delivery
/// vehicle, not a recycling collection truck.
private struct DeliveryTruckShape: View {
    var body: some View {
        ZStack {
            // Cargo box — tall white container with bottle icon
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: [Color(white: 0.92), Color(white: 0.7)], startPoint: .top, endPoint: .bottom))
                .frame(width: 120, height: 82)
                .overlay(
                    Image(systemName: "waterbottle.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(Theme.bottleBlue.opacity(0.7))
                )
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.3), lineWidth: 1.5))
                .offset(x: -22, y: -8)

            // Cab — darker than the cargo, with a windshield
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: [Color(white: 0.65), Color(white: 0.4)], startPoint: .top, endPoint: .bottom))
                .frame(width: 50, height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.neonCyan.opacity(0.4))
                        .frame(width: 28, height: 20)
                        .offset(y: -13)
                )
                .offset(x: 58, y: 2)

            // Chassis
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black.opacity(0.55))
                .frame(width: 178, height: 8)
                .offset(y: 35)

            // Wheels
            truckWheel.offset(x: -40, y: 42)
            truckWheel.offset(x: -10, y: 42)
            truckWheel.offset(x: 48, y: 42)

            // Headlights
            Circle().fill(Theme.neonAmber.opacity(0.9)).frame(width: 7, height: 7)
                .glow(Theme.neonAmber, radius: 8, opacity: 0.7)
                .offset(x: 82, y: 12)
            Circle().fill(Color.red.opacity(0.7)).frame(width: 5, height: 5)
                .glow(.red, radius: 4, opacity: 0.4)
                .offset(x: -82, y: 12)
        }
    }

    private var truckWheel: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [Color(white: 0.3), .black], center: .center, startRadius: 0, endRadius: 15))
                .frame(width: 26, height: 26)
            Circle().fill(Color(white: 0.55)).frame(width: 8, height: 8)
        }
    }
}

// MARK: - 11. Vending and discard (unified scene — person buys, drinks, player discards)

/// A unified interactive scene. A vending machine glows on the right side
/// of a rainy city street. A person walks up, presses a button, picks up the
/// bottle from the dispensing hatch, drinks it (auto-animated), and then
/// holds the empty bottle out to the left for the player to drag-and-discard.
struct VendingAndDiscardScene: View {
    @EnvironmentObject var game: GameState

    /// Timeline stages of the scene
    private enum Stage: Int, Comparable {
        case personEnters = 0      // person walks in from left
        case buyBottle = 1         // person presses button, bottle drops
        case takeBottle = 2        // person reaches down to pick up bottle
        case personDrinks = 3      // stands up, drinks (auto-animated)
        case bottleEmpty = 4       // holds out empty bottle, waiting for flick
        case discarded = 5         // player flicked bottle → falls to ground
        case exiting = 6           // person walks away, text shows up

        static func < (lhs: Stage, rhs: Stage) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    @State private var stage: Stage = .personEnters
    @State private var personX: CGFloat = 0.1
    @State private var personOpacity: Double = 1
    @State private var drinkProgress: Double = 0    // 0...1
    @State private var showText = false
    @State private var impactBurst = false
    @State private var arrowOffset: CGFloat = 0

    // Bottle visibility toggles inside the vending machine
    @State private var heroInGridVisible = true
    @State private var heroInHatchVisible = false
    @State private var heroInHandVisible = false

    @State private var bottlePos = CGPoint.zero
    
    // Joystick and Interaction States
    @State private var joystickOffset: CGSize = .zero
    @State private var isMoving = false
    @State private var legTimer: Double = 0
    @State private var canBuy = false
    @State private var sequenceStarted = false

    let timer = Timer.publish(every: 0.02, on: .main, in: .common).autoconnect()

    private let groundFrac: CGFloat = 0.82
    private let groundHeight: CGFloat = 160

    private var reduceMotion: Bool { game.reduceMotion }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let footY = size.height - groundHeight
            let px = personX * size.width
            let machineX = size.width * 0.72

            // Shoulder anchor point in global coordinates:
            // The person's frame is 160x260 positioned at (px, footY - 130).
            // Left shoulder is at local (51, 56), so global (px - 80 + 51, footY - 260 + 56) = (px - 29, footY - 204)
            let shoulderX = px - 29.0
            let shoulderY = footY - 204.0

            ZStack {
                // Background: rainy city street at night
                cityBackground

                // Roadside scenery, sized taller than the vending machine
                // (300pt) so they read as background landmarks rather than
                // street clutter, planted on the same ground line the
                // machine and person stand on.
                RoadsideTreesCanvas(roadTopY: footY, count: 1, height: 460, positions: [size.width * 0.40])
                StreetLampRow(roadTopY: footY, count: 1, height: 340, positions: [size.width * 0.16])

                // Vending Machine (height: 300, width: 200)
                // Positioned on the right side on top of the pavement
                VendingMachineCanvas(
                    heroCol: 2, heroRow: 1,
                    vibrancy: game.vibrancy, dirt: game.grime,
                    heroVisible: heroInGridVisible,
                    hatchVisible: heroInHatchVisible,
                    reduceMotion: game.reduceMotion
                )
                .position(x: machineX, y: footY - 150)

                // Ground plane
                streetGround

                // Person (walks in, buys, takes, drinks, exits)
                personView(size: size)

                // Bottle held in hand during drinking animation
                if heroInHandVisible && stage == .personDrinks {
                    let armAngleDeg = 40.0 + drinkProgress * 40.0 // swings left-up towards face
                    let armRad = armAngleDeg * .pi / 180.0
                    let handX = shoulderX - 60.0 * sin(armRad)
                    let handY = shoulderY + 60.0 * cos(armRad)

                    let bottleTiltDeg = 30.0 + drinkProgress * 30.0
                    let tiltRad = bottleTiltDeg * .pi / 180.0
                    let cdx = 40.0 * sin(tiltRad)
                    let cdy = -40.0 * cos(tiltRad)

                    BottleView(
                        vibrancy: game.vibrancy, dirt: game.grime,
                        showEyes: false, glow: 0,
                        width: 32, height: 80,
                        tilt: .degrees(bottleTiltDeg) // mouth points right (towards face), bottom points left
                    )
                    .position(x: handX + cdx, y: handY + cdy)
                    .transition(.opacity)
                }

                // Discarded bottle state
                if stage >= .bottleEmpty {
                    BottleView(
                        vibrancy: game.vibrancy, dirt: game.grime,
                        showEyes: stage == .bottleEmpty,
                        glow: stage == .bottleEmpty ? 0.2 : 0,
                        width: 52, height: 130,
                        tilt: stage >= .discarded ? .degrees(78) : .zero
                    )
                    .position(bottlePos)
                }

                // Tutorial Arrow
                if !sequenceStarted {
                    Image(systemName: "triangle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(Theme.neonAmber)
                        .rotationEffect(.degrees(180))
                        .offset(y: arrowOffset)
                        .position(x: machineX, y: footY - 350)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                                arrowOffset = -12
                            }
                        }
                }

                // Impact burst when bottle hits ground
                if impactBurst {
                    Circle()
                        .fill(RadialGradient(colors: [.white.opacity(0.5), .clear], center: .center, startRadius: 0, endRadius: 50))
                        .frame(width: 110, height: 35)
                        .position(x: bottlePos.x, y: footY + 10)
                        .transition(.opacity)
                }

                // Narrative text after discard
                if showText {
                    Text("มันถูกใช้ครั้งเดียว แล้วก็โดนทิ้ง")
                        .font(Theme.line(24))
                        .foregroundStyle(.white.opacity(0.95))
                        .padding(.horizontal, 26)
                        .padding(.vertical, 13)
                        .background(.ultraThinMaterial, in: Capsule())
                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                        .position(x: size.width * 0.5, y: size.height * 0.42)
                }

                Vignette(strength: 0.5)
            }
            .contentShape(Rectangle())
            .onReceive(timer) { _ in
                guard !sequenceStarted else { return }
                
                if joystickOffset.width != 0 {
                    isMoving = true
                    legTimer += 0.02
                    let speed: CGFloat = 0.005 // screen fraction per tick
                    let direction = joystickOffset.width > 0 ? 1.0 : -1.0
                    
                    personX += direction * speed
                    personX = max(0.05, min(0.65, personX))
                    
                    if personX > 0.52 {
                        withAnimation { canBuy = true }
                    } else {
                        withAnimation { canBuy = false }
                    }
                } else {
                    isMoving = false
                }
            }
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        if !sequenceStarted {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 140, height: 140)
                                Circle()
                                    .fill(Color.white.opacity(0.4))
                                    .frame(width: 60, height: 60)
                                    .offset(joystickOffset)
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { value in
                                                let maxDist: CGFloat = 50
                                                let dx = value.translation.width
                                                let dist = min(abs(dx), maxDist)
                                                let sign = dx > 0 ? 1.0 : -1.0
                                                joystickOffset = CGSize(width: sign * dist, height: 0)
                                            }
                                            .onEnded { _ in
                                                withAnimation(.interactiveSpring) {
                                                    joystickOffset = .zero
                                                }
                                            }
                                    )
                            }
                            .padding(.leading, 60)
                            .padding(.bottom, 80)
                            .transition(.opacity)
                            
                            Spacer()
                            
                            if canBuy {
                                Button(action: {
                                    buySequence(size: size)
                                }) {
                                    BuyButtonLabel()
                                }
                                .padding(.trailing, 60)
                                .padding(.bottom, 80)
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                }
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Vending machine on a rainy street. A person buys a bottle of water, drinks it, and leaves the empty bottle for you to discard.")
    }

    private var cityBackground: some View {
        ZStack {
            LinearGradient(colors: [Theme.deepNavy, Theme.nearBlack], startPoint: .top, endPoint: .bottom)
            NeonStreakField(colors: [Theme.neonPink, Theme.neonCyan, Theme.neonPurple], reduceMotion: reduceMotion)
            SkylineCanvas()
            SparkleCanvas(count: 20, color: .white, reduceMotion: reduceMotion).opacity(0.35)
            RainCanvas(intensity: 0.4, reduceMotion: reduceMotion)
        }
    }

    private var streetGround: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.06, blue: 0.08), Color(red: 0.02, green: 0.02, blue: 0.03)],
                startPoint: .top, endPoint: .bottom
            )
            Rectangle().fill(Color.white.opacity(0.12)).frame(height: 2)
        }
        .frame(height: groundHeight)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }

    private func personView(size: CGSize) -> some View {
        let skin = Color(red: 0.55, green: 0.4, blue: 0.3)
        let shirt = Theme.neonCyan.opacity(0.7)
        let pants = Color(red: 0.2, green: 0.16, blue: 0.14)
        let legAngle = (stage == .personEnters && isMoving) || stage == .exiting
            ? sin(legTimer * 15) * 22 : 0.0
        
        let frontArmAngle: Double
        let backArmAngle: Double

        if stage == .buyBottle {
            frontArmAngle = -45.0 // reaching forward to press machine button
            backArmAngle = 0.0
        } else if stage == .takeBottle {
            frontArmAngle = 135.0 // reaching down to dispensing hatch
            backArmAngle = -10.0
        } else if stage == .personDrinks {
            frontArmAngle = 40.0 + drinkProgress * 40.0 // swings left-up towards face
            backArmAngle = 10.0
        } else if stage == .bottleEmpty {
            frontArmAngle = -90.0 // outstretched holding the bottle to discard
            backArmAngle = 0.0
        } else if stage == .personEnters || stage == .exiting {
            frontArmAngle = -legAngle * 0.8
            backArmAngle = legAngle * 0.8
        } else {
            frontArmAngle = 0.0
            backArmAngle = 0.0
        }

        return ZStack(alignment: .topLeading) {
            // 1. Back arm (right arm, drawn behind torso) - Shoulder at (109, 56)
            Capsule().fill(skin).frame(width: 14, height: 60)
                .rotationEffect(.degrees(backArmAngle), anchor: .top)
                .position(x: 109, y: 86)

            // 2. Contact shadow
            Ellipse()
                .fill(Color.black.opacity(0.35))
                .frame(width: 90, height: 20)
                .position(x: 80, y: 250)

            // 3. Legs
            Capsule().fill(pants).frame(width: 20, height: 110)
                .rotationEffect(.degrees(legAngle), anchor: .top)
                .position(x: 64, y: 195)
            Capsule().fill(pants).frame(width: 20, height: 110)
                .rotationEffect(.degrees(-legAngle), anchor: .top)
                .position(x: 96, y: 195)

            // 4. Torso + Head (Head at y=0..50, Torso at y=56..142)
            Circle().fill(skin).frame(width: 50, height: 50)
                .position(x: 80, y: 25)
            RoundedRectangle(cornerRadius: 10).fill(shirt)
                .frame(width: 58, height: 86)
                .position(x: 80, y: 99)

            // 5. Front arm (left arm, drawn in front of torso) - Shoulder at (51, 56)
            Capsule().fill(skin).frame(width: 14, height: 60)
                .rotationEffect(.degrees(frontArmAngle), anchor: .top)
                .position(x: 51, y: 86)
        }
        .frame(width: 160, height: 260)
        .position(x: personX * size.width, y: size.height - groundHeight - 130)
        .opacity(personOpacity)
    }

    private func buySequence(size: CGSize) {
        sequenceStarted = true
        canBuy = false
        isMoving = false
        
        let scale = reduceMotion ? 0.65 : 1.0
        Task { @MainActor in
            withAnimation(.easeInOut(duration: 0.3)) { stage = .buyBottle }
            
            try? await Task.sleep(for: .seconds(0.4 * scale))
            game.sound.impactThud()
            Haptics.collision()
            
            try? await Task.sleep(for: .seconds(0.2 * scale))
            withAnimation(.easeInOut(duration: 0.3)) { heroInGridVisible = false }
            game.sound.splash()
            withAnimation(.easeInOut(duration: 0.2)) { heroInHatchVisible = true }
            
            try? await Task.sleep(for: .seconds(0.6 * scale))
            withAnimation(.easeInOut(duration: 0.4)) { stage = .takeBottle }
            
            try? await Task.sleep(for: .seconds(0.5 * scale))
            withAnimation(.easeInOut(duration: 0.2)) {
                heroInHatchVisible = false
                heroInHandVisible = true
            }
            
            try? await Task.sleep(for: .seconds(0.3 * scale))
            withAnimation(.easeInOut(duration: 0.4)) { stage = .personDrinks }
            
            try? await Task.sleep(for: .seconds(0.5 * scale))
            withAnimation(.easeInOut(duration: 2.0 * scale)) { drinkProgress = 1 }
            
            try? await Task.sleep(for: .seconds(1.0 * scale))
            
            let footY = size.height - groundHeight
            let px = personX * size.width
            withAnimation(.easeInOut(duration: 0.4)) {
                stage = .bottleEmpty
                heroInHandVisible = false
                // Positioned so the hand holds the base of the bottle
                bottlePos = CGPoint(x: px - 85, y: footY - 248)
            }
            
            try? await Task.sleep(for: .seconds(0.4 * scale))
            withAnimation(.easeIn(duration: reduceMotion ? 0.3 : 0.5)) {
                stage = .discarded
                bottlePos = CGPoint(x: bottlePos.x - 20, y: footY + 10)
            }

            try? await Task.sleep(for: .seconds(reduceMotion ? 0.35 : 0.55))
            game.sound.impactThud()
            Haptics.collision()
            withAnimation(.easeOut(duration: 0.2)) { impactBurst = true }
            try? await Task.sleep(for: .seconds(0.2))
            withAnimation(.easeOut(duration: 0.3)) { impactBurst = false }

            try? await Task.sleep(for: .seconds(0.4))
            withAnimation(.easeInOut(duration: 0.3)) { stage = .exiting }
            withAnimation(.easeIn(duration: reduceMotion ? 0.7 : 1.2)) {
                personX = -0.2
                personOpacity = 0
            }

            try? await Task.sleep(for: .seconds(0.6))
            withAnimation(.easeIn(duration: 0.5)) { showText = true }

            try? await Task.sleep(for: .seconds(reduceMotion ? 1.5 : 2.8))
            game.advanceFromVendingAndDiscard()
        }
    }
}

/// The vending machine's call-to-action — restyled to match the game's own
/// glass-and-neon language (translucent material, thin cyan stroke, soft
/// glow) instead of a plain solid-fill button, with the same slow pulse
/// `TitleScene` uses for "Tap to begin" so it reads as an invitation rather
/// than a generic UI control.
private struct BuyButtonLabel: View {
    var body: some View {
        Text("ซื้อ")
            .font(Theme.title(22))
            .foregroundStyle(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 15)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
    }
}

private struct VendingMachineCanvas: View {
    var heroCol: Int
    var heroRow: Int
    var vibrancy: Double
    var dirt: Double
    var heroVisible: Bool
    var hatchVisible: Bool
    var reduceMotion: Bool

    private let cols = 5
    private let rows = 4
    private let machineWidth: CGFloat = 200
    private let machineHeight: CGFloat = 300

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(
                    colors: [Color(red: 0.7, green: 0.15, blue: 0.2), Color(red: 0.4, green: 0.05, blue: 0.1)],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: machineWidth, height: machineHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.12), lineWidth: 2)
                )

            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.04))
                .frame(width: machineWidth - 24, height: machineHeight * 0.60)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Theme.neonCyan.opacity(0.15), lineWidth: 1.2)
                )
                .offset(y: -30)

            bottleGrid
                .offset(y: -30)

            RoundedRectangle(cornerRadius: 2)
                .fill(LinearGradient(colors: [Theme.neonCyan.opacity(0.5), Theme.neonPurple.opacity(0.4)], startPoint: .leading, endPoint: .trailing))
                .frame(width: machineWidth - 32, height: 5)
                .blur(radius: 2)
                .offset(y: -(machineHeight / 2 - 18))

            RoundedRectangle(cornerRadius: 6)
                .fill(Color.black.opacity(0.6))
                .frame(width: 80, height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .overlay(
                    Group {
                        if hatchVisible {
                            BottleView(vibrancy: vibrancy, dirt: dirt, showEyes: false, width: 12, height: 30, tilt: .degrees(90))
                                .opacity(0.8)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                )
                .offset(y: machineHeight / 2 - 32)

            RoundedRectangle(cornerRadius: 1)
                .fill(Color(white: 0.3))
                .frame(width: 14, height: 4)
                .offset(x: machineWidth / 2 - 24, y: -15)

            VStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill([Theme.neonCyan, Theme.neonPink, Theme.neonAmber, Theme.neonPurple][i].opacity(0.5))
                        .frame(width: 7, height: 7)
                }
            }
            .offset(x: machineWidth / 2 - 23, y: 10)
        }
    }

    private var bottleGrid: some View {
        let cellW: CGFloat = (machineWidth - 40) / CGFloat(cols)
        let cellH: CGFloat = (machineHeight * 0.56) / CGFloat(rows)

        return VStack(spacing: 3) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 3) {
                    ForEach(0..<cols, id: \.self) { col in
                        let isHero = col == heroCol && row == heroRow
                        ZStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 1)
                                .offset(y: cellH / 2 - 2)

                            if !isHero || heroVisible {
                                BottleView(
                                    vibrancy: isHero ? vibrancy : 0.35,
                                    dirt: isHero ? dirt : 0,
                                    showEyes: isHero,
                                    glow: isHero ? 0.45 : 0,
                                    width: isHero ? 18 : 14,
                                    height: isHero ? 42 : 36
                                )
                                .saturation(isHero ? 1 : 0.3)
                                .opacity(isHero ? 1 : 0.4)
                            }
                        }
                        .frame(width: cellW, height: cellH)
                    }
                }
            }
        }
    }
}
