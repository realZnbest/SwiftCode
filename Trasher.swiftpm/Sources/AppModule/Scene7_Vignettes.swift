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
                    FactorySilhouetteCanvas(reduceMotion: game.reduceMotion).opacity(0.6)
                    ConveyorBeltCanvas(reduceMotion: game.reduceMotion)
                    LightRaysCanvas(color: Theme.cleanCyan, count: 3, reduceMotion: game.reduceMotion)
                    SparkleCanvas(count: 18, color: .white, reduceMotion: game.reduceMotion).opacity(0.4)
                }
            },
            onFinish: { game.advanceFromFactoryOrigin() }
        )
    }
}

// MARK: - 2. Storm drain tunnel (after choosing the drain)

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

// MARK: - 3. Second bottle mirror (right before the canal)

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

// MARK: - 4. Night into day (after the canal fork resolves toward recycling)

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

// MARK: - 5. Fishing net rescue (before the recycling facility)

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
            // Where the mesh actually has to converge — the bottle's own
            // position in FishingNetRescueScene (bottlePosition: 0.5, 0.46)
            // — not an arbitrary point off to the side. The hoop can sit
            // above and to the right (reaching in from an angle), but the
            // bottom of the pouch must land on the bottle, or the net reads
            // as scooping empty water next to it.
            let catchPoint = CGPoint(x: size.width * 0.5, y: size.height * 0.46)
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
                let spread = hoopRadius * 0.5 * (1 - rowFrac)
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
            line: "Sorted from everything it wasn't.",
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

// MARK: - 8. Truck delivery (carrying the reclaimed material out)

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

// MARK: - 9. Community cleanup (after the montage, before the park)

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
