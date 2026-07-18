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

    var body: some View {
        VignetteScene(
            line: "Made to be used once.",
            accessibilityText: "A factory line. The bottle is filled and sealed, brand new.",
            bottlePosition: UnitPoint(x: 0.5, y: 0.82),
            bottleGlow: 0.35,
            textPosition: UnitPoint(x: 0.5, y: 0.65),
            content: { _ in
                ZStack {
                    LinearGradient(colors: [Theme.deepNavy, Theme.nearBlack], startPoint: .top, endPoint: .bottom)
                    FactorySilhouetteCanvas().opacity(0.6)
                    ConveyorBeltCanvas(reduceMotion: game.reduceMotion)
                    LightRaysCanvas(color: Theme.cleanCyan, count: 3, reduceMotion: game.reduceMotion)
                    SparkleCanvas(count: 18, color: .white, reduceMotion: game.reduceMotion).opacity(0.4)
                }
            },
            onFinish: { game.advanceFromFactoryOrigin() }
        )
    }
}

// MARK: - 2. Sidewalk drift (after the opening, before the dodge)

struct SidewalkDriftScene: View {
    @EnvironmentObject var game: GameState
    @State private var start = Date()

    /// Each kick is (time it lands, how far it sends the bottle as a
    /// fraction of screen width). Between kicks the bottle sits still —
    /// it only moves because something just struck it, not on its own —
    /// which is what actually sells "every step moves it somewhere." A
    /// full walking figure (see `KickerFigure`) times its stride to reach
    /// the bottle at exactly this moment, so the cause is a visible person,
    /// not an abstract leg shape.
    private let kicks: [(time: Double, distance: CGFloat)] = [
        (0.9, 0.16), (2.3, 0.14), (3.7, 0.13),
        (5.1, 0.14), (6.5, 0.14), (7.9, 0.15)
    ]
    private let groundYFrac: CGFloat = 0.8

    var body: some View {
        VignetteScene(
            line: "Every step moves it somewhere.",
            accessibilityText: "A sidewalk at night. A passerby's foot kicks the bottle along with each stride.",
            hold: 9.0,
            showBottle: false,
            content: { size in
                let groundY = size.height * groundYFrac
                return ZStack {
                    LinearGradient(colors: [Theme.deepNavy, Theme.nearBlack], startPoint: .top, endPoint: .bottom)
                    SkylineCanvas().opacity(0.3)
                    NeonStreakField(colors: [Theme.neonPink, Theme.neonCyan], reduceMotion: game.reduceMotion)
                    RainCanvas(intensity: 0.4, reduceMotion: game.reduceMotion)

                    sidewalkGround(groundY: groundY, size: size)

                    TimelineView(.animation(minimumInterval: game.reduceMotion ? 1 : 1.0 / 30)) { context in
                        let elapsed = game.reduceMotion ? 4.5 : context.date.timeIntervalSince(start)
                        let xFrac = bottleXFrac(at: elapsed)
                        let traveled = (xFrac - 0.14) * size.width

                        ZStack {
                            ForEach(Array(kicks.enumerated()), id: \.offset) { _, kick in
                                KickerFigure(
                                    localTime: elapsed - kick.time,
                                    footX: bottleXFrac(at: kick.time) * size.width,
                                    groundY: groundY
                                )
                            }

                            BottleView(vibrancy: game.vibrancy, dirt: game.grime, showEyes: false, width: 56, height: 138,
                                       tilt: .degrees(Double(traveled) * 2.1))
                                .position(x: xFrac * size.width, y: groundY - 12)
                        }
                    }
                }
            },
            onFinish: { game.advanceFromSidewalkDrift() }
        )
        .onAppear { start = Date() }
    }

    /// Accumulates every kick that's already landed in full, then animates
    /// the one currently in flight with an ease-out settle.
    private func bottleXFrac(at t: Double) -> CGFloat {
        var x: CGFloat = 0.14
        for kick in kicks {
            guard t >= kick.time else { break }
            let localT = min(1, (t - kick.time) / 0.3)
            let eased = 1 - pow(1 - localT, 3)
            x += kick.distance * eased
        }
        return x
    }

    /// A concrete sidewalk slab: a flat paved band with a curb-edge
    /// highlight and a few expansion-joint lines, so there's an actual
    /// ground plane for the bottle and the walker to stand on instead of
    /// them floating over a bare gradient.
    private func sidewalkGround(groundY: CGFloat, size: CGSize) -> some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(Color(red: 0.07, green: 0.08, blue: 0.1))
                .frame(height: size.height - groundY)
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 2)
            HStack(spacing: size.width * 0.11) {
                ForEach(0..<10, id: \.self) { _ in
                    Rectangle().fill(Color.white.opacity(0.05)).frame(width: 1.5)
                }
            }
            .frame(height: size.height - groundY, alignment: .top)
        }
        .frame(width: size.width, height: size.height - groundY)
        .position(x: size.width / 2, y: groundY + (size.height - groundY) / 2)
    }
}

/// A full walking figure timed to plant its kicking foot on the bottle at
/// `localTime == 0`. Outside the kick window it just walks (a simple
/// two-leg scissor cycle); through the kick window the lead leg swings
/// from a cocked-back windup into a forward follow-through, so the impact
/// reads as something a person did, not a disembodied leg popping in.
private struct KickerFigure: View {
    var localTime: Double
    var footX: CGFloat
    var groundY: CGFloat

    private let walkSpeed: CGFloat = 150
    // A cool blue-gray rather than flat black — reads as a figure caught
    // in the street's neon and rain rather than a silhouette cutout that
    // blends into the near-black background.
    private let skin = Color(red: 0.34, green: 0.37, blue: 0.44)

    var body: some View {
        if localTime > -1.15 && localTime < 0.85 {
            let bodyX = footX + walkSpeed * CGFloat(localTime) - 13
            let fadeIn = min(1, max(0, (localTime + 1.15) / 0.3))
            let fadeOut = min(1, max(0, (0.85 - localTime) / 0.3))
            ZStack {
                Ellipse()
                    .fill(Color.black.opacity(0.35))
                    .frame(width: 86, height: 20)
                    .offset(y: 9)

                ZStack(alignment: .bottom) {
                    Capsule().fill(skin).frame(width: 18, height: 83)
                        .overlay(Capsule().stroke(Theme.neonCyan.opacity(0.18), lineWidth: 1.5))
                        .rotationEffect(.degrees(backLegAngle), anchor: .top)
                        .offset(x: -13)
                    Capsule().fill(skin).frame(width: 18, height: 83)
                        .overlay(Capsule().stroke(Theme.neonCyan.opacity(0.18), lineWidth: 1.5))
                        .rotationEffect(.degrees(frontLegAngle), anchor: .top)
                        .offset(x: 13)
                    VStack(spacing: 7) {
                        Circle().fill(skin).frame(width: 41, height: 41)
                        RoundedRectangle(cornerRadius: 10).fill(skin.opacity(0.92)).frame(width: 49, height: 68)
                    }
                    .overlay(
                        VStack(spacing: 7) {
                            Circle().stroke(Theme.neonCyan.opacity(0.2), lineWidth: 1.5).frame(width: 41, height: 41)
                            RoundedRectangle(cornerRadius: 10).stroke(Theme.neonCyan.opacity(0.2), lineWidth: 1.5).frame(width: 49, height: 68)
                        }
                    )
                    .offset(y: -83)
                }
            }
            .opacity(min(fadeIn, fadeOut))
            .position(x: bodyX, y: groundY - 22)
        }
    }

    /// Mid-kick (roughly -0.12...0.26s of local time) overrides the normal
    /// walk cycle for the front leg with a windup-to-follow-through swing;
    /// otherwise both legs just scissor back and forth for an ordinary gait.
    private var kickPhase: Double? {
        guard localTime > -0.12 && localTime < 0.26 else { return nil }
        return min(1, max(0, (localTime + 0.12) / 0.38))
    }

    private var backLegAngle: Double {
        if kickPhase != nil { return -18 }
        return sin(localTime * 9) * 24
    }

    private var frontLegAngle: Double {
        if let k = kickPhase { return -55 + k * 100 }
        return -sin(localTime * 9) * 24
    }
}

// MARK: - 3. Storm drain tunnel (after choosing the drain)

struct StormDrainTunnelScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "Into the dark, out of sight.",
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

// MARK: - 4. Second bottle mirror (right before the canal)

struct SecondBottleMirrorScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "Not every piece gets free.",
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

// MARK: - 5. Night into day (after the canal fork resolves toward recycling)

struct NightIntoDayScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "Time keeps moving forward.",
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

// MARK: - 6. Fishing net rescue (before the recycling facility)

struct FishingNetRescueScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "Someone chose to reach in.",
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

                    Canvas { ctx, canvasSize in
                        let net = CGRect(x: canvasSize.width * 0.5, y: 0, width: canvasSize.width * 0.5, height: canvasSize.height * 0.55)
                        for i in 0...6 {
                            let x = net.minX + net.width * CGFloat(i) / 6
                            var p = Path()
                            p.move(to: CGPoint(x: x, y: net.minY))
                            p.addLine(to: CGPoint(x: x - net.width * 0.35, y: net.maxY))
                            ctx.stroke(p, with: .color(.white.opacity(0.22)), lineWidth: 1.2)
                        }
                        for i in 0...4 {
                            let y = net.minY + net.height * CGFloat(i) / 4
                            var p = Path()
                            p.move(to: CGPoint(x: net.minX, y: y))
                            p.addLine(to: CGPoint(x: net.maxX, y: y - net.height * 0.15))
                            ctx.stroke(p, with: .color(.white.opacity(0.22)), lineWidth: 1.2)
                        }
                    }
                }
            },
            onFinish: { game.advanceFromFishingNetRescue() }
        )
    }
}

// MARK: - 7. Sorting line (facility approach, before cleaning/shredding)

struct SortingLineScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "Sorted from everything it wasn't.",
            accessibilityText: "A sorting line. Optical scanners separate plastic from glass and metal.",
            bottlePosition: UnitPoint(x: 0.5, y: 0.8),
            content: { size in
                ZStack {
                    LinearGradient(colors: [Theme.deepNavy, Theme.nearBlack], startPoint: .top, endPoint: .bottom)
                    FactorySilhouetteCanvas().opacity(0.6)
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

// MARK: - 8. Pellet reveal (right after finishing recycling)

struct PelletRevealScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "Not the same. Not gone, either.",
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

// MARK: - 9. Truck delivery (carrying the reclaimed material out)

struct TruckDeliveryScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "On its way to becoming something new.",
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

                    Rectangle()
                        .fill(Color(red: 0.06, green: 0.06, blue: 0.08))
                        .frame(height: size.height - roadTopY)
                        .position(x: size.width * 0.5, y: roadTopY + (size.height - roadTopY) / 2)
                    RoadLinesCanvas(roadTopY: roadTopY, reduceMotion: game.reduceMotion)
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
private struct RoadLinesCanvas: View {
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

// MARK: - 10. Community cleanup (after the montage, before the park)

struct CommunityCleanupScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "Some hands make sure less of it starts this journey.",
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
