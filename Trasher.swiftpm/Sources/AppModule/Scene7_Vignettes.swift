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

// MARK: - 10. Delivery truck (factory → city distribution)

/// ~5s auto-advancing scene. A delivery truck drives across the city at
/// night carrying bottles from the factory to retail. Uses the same road
/// treatment as TruckDeliveryScene but with a distinct cargo-truck shape
/// (white box truck with bottle icon instead of recycling arrows).
struct DeliveryTruckScene: View {
    @EnvironmentObject var game: GameState

    var body: some View {
        VignetteScene(
            line: "Shipped across the city.",
            accessibilityText: "A delivery truck drives through the city at night, carrying bottles from the factory.",
            showBottle: false,
            textPosition: UnitPoint(x: 0.5, y: 0.15),
            content: { size in
                let roadTopY = size.height * 0.86
                return ZStack {
                    LinearGradient(colors: [Theme.deepNavy, Theme.nearBlack], startPoint: .top, endPoint: .bottom)
                    SkylineCanvas().opacity(0.3)
                    NeonStreakField(colors: [Theme.neonAmber, Theme.neonPink, Theme.neonCyan], reduceMotion: game.reduceMotion)

                    Rectangle()
                        .fill(Color(red: 0.06, green: 0.06, blue: 0.08))
                        .frame(height: size.height - roadTopY)
                        .position(x: size.width * 0.5, y: roadTopY + (size.height - roadTopY) / 2)
                    RoadLinesCanvas(roadTopY: roadTopY, reduceMotion: game.reduceMotion)
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
                    Text("Used once. Left behind.")
                        .font(Theme.line(24))
                        .foregroundStyle(.white.opacity(0.95))
                        .padding(.horizontal, 26)
                        .padding(.vertical, 13)
                        .background(.ultraThinMaterial, in: Capsule())
                        .glow(Theme.neonCyan, radius: 10, opacity: 0.2)
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
                                    Text("BUY")
                                        .font(Theme.title(22))
                                        .padding(.horizontal, 30)
                                        .padding(.vertical, 15)
                                        .background(Theme.neonCyan)
                                        .foregroundColor(.black)
                                        .clipShape(Capsule())
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
            HStack(spacing: 70) {
                ForEach(0..<5, id: \.self) { i in
                    Capsule()
                        .fill([Theme.neonCyan, Theme.neonPink, Theme.neonPurple][i % 3].opacity(0.16))
                        .frame(width: 46, height: 120)
                        .blur(radius: 10)
                }
            }
            .offset(y: 6)
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
