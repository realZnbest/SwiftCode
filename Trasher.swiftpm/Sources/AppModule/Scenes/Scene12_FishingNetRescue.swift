import SwiftUI

struct FishingNetRescueScene: View {
    @EnvironmentObject var game: GameState

    @State private var boatX: CGFloat = -0.18
    @State private var joystickOffset: CGSize = .zero
    @State private var netProgress: CGFloat = 0
    @State private var boatDip: CGFloat = 0
    @State private var releaseAt: Double? = nil
    @State private var showControls = false
    @State private var collecting = false
    @State private var caught = false
    @State private var sceneStart = Date()
    @State private var timeoutTask: Task<Void, Never>? = nil

    private let targetX: CGFloat = 0.5
    private let lockTolerance: CGFloat = 0.05

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let surfaceY = size.height * 0.40
            let underwaterH = size.height - surfaceY
            let driftY = size.height * 0.72
            let inRange = abs(boatX - targetX) < lockTolerance

            ZStack {
                TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                    let t = context.date.timeIntervalSince(sceneStart)
                    let boatCenterX = size.width * boatX
                    let boatBob = CGFloat(sin(t * 1.4)) * 4
                    let netTopY = surfaceY - 58 + boatBob + boatDip
                    let catchY = netTopY + (driftY - netTopY) * netProgress
                    let swingRaw: CGFloat = {
                        guard let r = releaseAt else { return 0 }
                        let e = t - r
                        guard e >= 0 else { return 0 }
                        return CGFloat(sin(e * 6.5) * exp(-e * 2.0)) * 16
                    }()
                    let netCatchX = boatCenterX + (caught ? swingRaw * 0.15 : swingRaw)
                    let bottleSway = collecting ? 0 : CGFloat(sin(t * 0.9)) * 10
                    let bottlePos = caught
                        ? CGPoint(x: netCatchX, y: catchY + 16)
                        : CGPoint(x: size.width * targetX + bottleSway,
                                  y: driftY + (collecting ? 0 : CGFloat(sin(t * 1.6)) * 6))

                    ZStack {
                        Theme.deepNavy

                        LinearGradient(
                            colors: [
                                Color(red: 0.10, green: 0.42, blue: 0.48),
                                Color(red: 0.04, green: 0.20, blue: 0.28),
                                Color(red: 0.02, green: 0.08, blue: 0.14),
                                Theme.deepNavy
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                        .frame(height: underwaterH)
                        .frame(maxHeight: .infinity, alignment: .bottom)

                        ZStack {
                            LightRaysCanvas(color: Theme.cleanCyan, count: 6)
                            FishSilhouettesCanvas(darkness: 0.22)
                            OceanFloorCanvas()
                            BubbleCanvas(count: 22, color: .white)
                        }
                        .frame(width: size.width, height: underwaterH)
                        .position(x: size.width / 2, y: surfaceY + underwaterH / 2)
                        .clipped()

                        LinearGradient(
                            colors: [Color(red: 0.52, green: 0.77, blue: 0.92), Color(red: 0.82, green: 0.91, blue: 0.96)],
                            startPoint: .top, endPoint: .bottom
                        )
                        .frame(height: surfaceY)
                        .frame(maxHeight: .infinity, alignment: .top)

                        Circle()
                            .fill(RadialGradient(colors: [Color(red: 1, green: 0.96, blue: 0.82), .clear],
                                                 center: .center, startRadius: 4, endRadius: 70))
                            .frame(width: 150, height: 150)
                            .position(x: size.width * 0.82, y: surfaceY * 0.34)

                        CloudDriftCanvas()
                            .frame(width: size.width, height: surfaceY * 0.85)
                            .frame(maxHeight: .infinity, alignment: .top)
                            .opacity(0.75)

                        WaterlineCanvas(surfaceY: surfaceY, elapsed: t)

                        BottleView(
                            vibrancy: game.vibrancy, dirt: game.grime, showEyes: true,
                            width: 30, height: 74, tilt: caught ? .zero : .degrees(Double(sin(t * 0.7)) * 8)
                        )
                        .saturation(caught ? 1 : 0.6)
                        .position(bottlePos)

                        RescueNetCanvas(topX: boatCenterX, topY: netTopY, catchX: netCatchX, catchY: catchY,
                                        visible: collecting || caught)

                        CollectorBoatView()
                            .frame(width: 190, height: 150)
                            .position(x: boatCenterX, y: surfaceY - 30 + boatBob + boatDip)

                        Vignette(strength: 0.5)
                    }
                }

                if showControls && !collecting {
                    SteerArrow(active: inRange)
                        .position(x: size.width * targetX, y: surfaceY - 96)
                        .transition(.opacity)

                    Joystick(offset: $joystickOffset)
                        .position(x: size.width * 0.17, y: size.height * 0.84)
                        .transition(.opacity)

                    Button(action: { collect() }) {
                        Text(game.t(Loc.fishingNetCollectButton))
                            .font(Theme.line(22))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 34)
                            .padding(.vertical, 14)
                            .background((inRange ? Theme.freshGreen : Color(white: 0.4)).opacity(inRange ? 0.94 : 0.55),
                                        in: Capsule())
                            .overlay(Capsule().stroke(.white.opacity(inRange ? 0.6 : 0.25), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .disabled(!inRange)
                    .position(x: size.width * 0.83, y: size.height * 0.84)
                    .transition(.opacity)
                }
            }
        }
        .onAppear(perform: start)
        .onDisappear { timeoutTask?.cancel() }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(0.02))
                guard showControls, !collecting, !caught, joystickOffset.width != 0 else { continue }
                let dir: CGFloat = joystickOffset.width > 0 ? 1 : -1
                boatX = min(0.9, max(0.1, boatX + dir * 0.006))
            }
        }
    }

    private func start() {
        boatX = -0.18
        netProgress = 0
        boatDip = 0
        releaseAt = nil
        caught = false
        collecting = false
        showControls = false
        sceneStart = Date()
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.4))
            withAnimation(.easeInOut(duration: 1.3)) { boatX = 0.2 }
            try? await Task.sleep(for: .seconds(1.4))
            withAnimation(.easeIn(duration: 0.3)) { showControls = true }
            timeoutTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(18))
                guard !collecting else { return }
                collect(force: true)
            }
        }
    }

    private func collect(force: Bool = false) {
        guard !collecting else { return }
        guard force || abs(boatX - targetX) < lockTolerance else { return }
        collecting = true
        timeoutTask?.cancel()
        withAnimation(.easeOut(duration: 0.25)) { boatX = targetX }
        withAnimation(.easeIn(duration: 0.2)) { showControls = false }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.32))
            game.sound.impactThud()
            withAnimation(.easeOut(duration: 0.2)) { boatDip = 8 }
            withAnimation(.easeInOut(duration: 0.26)) { netProgress = -0.1 }
            try? await Task.sleep(for: .seconds(0.28))
            releaseAt = Date().timeIntervalSince(sceneStart)
            game.sound.splash()
            withAnimation(.spring(response: 0.95, dampingFraction: 0.7)) { netProgress = 1 }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) { boatDip = 0 }
            try? await Task.sleep(for: .seconds(1.2))
            withAnimation(.easeOut(duration: 0.2)) { caught = true }
            game.sound.success()
            withAnimation(.easeOut(duration: 0.1)) { boatDip = -5 }
            withAnimation(.interpolatingSpring(stiffness: 32, damping: 11)) { netProgress = 0 }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.55).delay(0.1)) { boatDip = 0 }
            try? await Task.sleep(for: .seconds(1.2))
            withAnimation(.easeInOut(duration: 2.0)) { boatX = 1.32 }
            try? await Task.sleep(for: .seconds(1.7))
            game.advanceFromFishingNetRescue()
        }
    }
}

private struct SteerArrow: View {
    let active: Bool
    @State private var bounce = false

    var body: some View {
        DownTriangle()
            .fill(active ? Theme.freshGreen : Color(red: 0.96, green: 0.6, blue: 0.15))
            .frame(width: 34, height: 26)
            .shadow(color: (active ? Theme.freshGreen : Color(red: 0.96, green: 0.6, blue: 0.15)).opacity(0.7), radius: 8)
            .offset(y: bounce ? 9 : -7)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { bounce = true }
            }
    }
}

private struct DownTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

private struct Joystick: View {
    @Binding var offset: CGSize

    private let radius: CGFloat = 54
    private let maxDist: CGFloat = 46
    private let knobSize: CGFloat = 48

    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(Circle().stroke(.white.opacity(0.3), lineWidth: 1.5))

            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white.opacity(0.5))
                .offset(x: -radius + 16)
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white.opacity(0.5))
                .offset(x: radius - 16)

            Circle()
                .fill(Theme.freshGreen.opacity(0.9))
                .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 2))
                .frame(width: knobSize, height: knobSize)
                .offset(offset)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let dx = value.translation.width
                            let dist = min(abs(dx), maxDist)
                            let sign: CGFloat = dx > 0 ? 1 : -1
                            offset = CGSize(width: sign * dist, height: 0)
                        }
                        .onEnded { _ in
                            withAnimation(.interactiveSpring) { offset = .zero }
                        }
                )
        }
        .frame(width: radius * 2, height: radius * 2)
    }
}

private struct WaterlineCanvas: View {
    let surfaceY: CGFloat
    let elapsed: Double

    var body: some View {
        Canvas { ctx, size in
            var wave = Path()
            let steps = 46
            for i in 0...steps {
                let x = size.width * CGFloat(i) / CGFloat(steps)
                let y = surfaceY + sin(CGFloat(i) * 0.55 + CGFloat(elapsed) * 1.6) * 3
                if i == 0 { wave.move(to: CGPoint(x: x, y: y)) } else { wave.addLine(to: CGPoint(x: x, y: y)) }
            }
            ctx.stroke(wave, with: .color(.white.opacity(0.55)), lineWidth: 2.5)
            ctx.stroke(wave, with: .color(Theme.cleanCyan.opacity(0.4)), lineWidth: 6)
        }
        .allowsHitTesting(false)
    }
}

private struct RescueNetCanvas: View {
    let topX: CGFloat
    let topY: CGFloat
    let catchX: CGFloat
    let catchY: CGFloat
    let visible: Bool

    var body: some View {
        Canvas { ctx, size in
            guard visible else { return }
            let hw: CGFloat = 30
            var ropes = Path()
            ropes.move(to: CGPoint(x: topX - 12, y: topY)); ropes.addLine(to: CGPoint(x: catchX - hw, y: catchY))
            ropes.move(to: CGPoint(x: topX + 12, y: topY)); ropes.addLine(to: CGPoint(x: catchX + hw, y: catchY))
            ctx.stroke(ropes, with: .color(.white.opacity(0.5)), lineWidth: 1.6)

            let hoopRect = CGRect(x: catchX - hw, y: catchY - 8, width: hw * 2, height: 16)
            let pouchTip = CGPoint(x: catchX, y: catchY + 46)
            let cols = 6
            for c in 0...cols {
                let f = CGFloat(c) / CGFloat(cols)
                let rimX = hoopRect.minX + hoopRect.width * f
                var strand = Path()
                strand.move(to: CGPoint(x: rimX, y: catchY))
                strand.addQuadCurve(to: pouchTip, control: CGPoint(x: rimX + (catchX - rimX) * 0.5, y: catchY + 40))
                ctx.stroke(strand, with: .color(.white.opacity(0.32)), lineWidth: 1.0)
            }
            for r in 1...3 {
                let ry = catchY + CGFloat(r) * 12
                let rw = hw * (1 - CGFloat(r) * 0.24)
                var arc = Path()
                arc.move(to: CGPoint(x: catchX - rw, y: ry))
                arc.addQuadCurve(to: CGPoint(x: catchX + rw, y: ry), control: CGPoint(x: catchX, y: ry + 6))
                ctx.stroke(arc, with: .color(.white.opacity(0.28)), lineWidth: 1.0)
            }
            ctx.stroke(Path(ellipseIn: hoopRect), with: .color(.white.opacity(0.75)), lineWidth: 2.5)
        }
        .allowsHitTesting(false)
    }
}

private struct CollectorBoatView: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let deckY: CGFloat = 96

            var hull = Path()
            hull.move(to: CGPoint(x: 14, y: deckY))
            hull.addLine(to: CGPoint(x: w - 14, y: deckY))
            hull.addLine(to: CGPoint(x: w - 30, y: 132))
            hull.addQuadCurve(to: CGPoint(x: 30, y: 132), control: CGPoint(x: w / 2, y: 150))
            hull.closeSubpath()
            ctx.fill(hull, with: .linearGradient(
                Gradient(colors: [Color(red: 0.16, green: 0.52, blue: 0.48), Color(red: 0.05, green: 0.26, blue: 0.28)]),
                startPoint: CGPoint(x: 0, y: deckY), endPoint: CGPoint(x: 0, y: 134)))

            var stripe = Path()
            stripe.move(to: CGPoint(x: 20, y: deckY + 11))
            stripe.addLine(to: CGPoint(x: w - 26, y: deckY + 11))
            ctx.stroke(stripe, with: .color(Theme.freshGreen.opacity(0.9)), lineWidth: 6)

            var deckLine = Path()
            deckLine.move(to: CGPoint(x: 14, y: deckY))
            deckLine.addLine(to: CGPoint(x: w - 14, y: deckY))
            ctx.stroke(deckLine, with: .color(.white.opacity(0.5)), lineWidth: 2)

            var bin = Path()
            bin.move(to: CGPoint(x: 34, y: deckY))
            bin.addLine(to: CGPoint(x: 78, y: deckY))
            bin.addLine(to: CGPoint(x: 72, y: deckY - 30))
            bin.addLine(to: CGPoint(x: 40, y: deckY - 30))
            bin.closeSubpath()
            ctx.fill(bin, with: .color(Color(red: 0.14, green: 0.38, blue: 0.3)))
            ctx.stroke(bin, with: .color(Theme.freshGreen.opacity(0.7)), lineWidth: 1.5)

            let cabin = CGRect(x: 118, y: deckY - 40, width: 46, height: 40)
            ctx.fill(Path(roundedRect: cabin, cornerRadius: 5), with: .color(Color(red: 0.86, green: 0.89, blue: 0.92)))
            ctx.fill(Path(roundedRect: CGRect(x: 126, y: deckY - 31, width: 20, height: 15), cornerRadius: 3),
                     with: .color(Color(red: 0.3, green: 0.56, blue: 0.72)))

            var gantry = Path()
            gantry.move(to: CGPoint(x: 80, y: deckY))
            gantry.addLine(to: CGPoint(x: 95, y: deckY - 60))
            gantry.move(to: CGPoint(x: 110, y: deckY))
            gantry.addLine(to: CGPoint(x: 95, y: deckY - 60))
            ctx.stroke(gantry, with: .color(Color(red: 0.92, green: 0.62, blue: 0.2)), lineWidth: 4)
            ctx.fill(Path(ellipseIn: CGRect(x: 90, y: deckY - 62, width: 10, height: 10)),
                     with: .color(.black.opacity(0.65)))
        }
        .allowsHitTesting(false)
    }
}

private struct OceanFloorCanvas: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24)) { context in
            Canvas { ctx, size in
                let t = context.date.timeIntervalSinceReferenceDate
                let floorY = size.height * 0.9

                var bed = Path()
                bed.move(to: CGPoint(x: 0, y: size.height))
                bed.addLine(to: CGPoint(x: 0, y: floorY))
                let humps = 7
                for i in 0...humps {
                    let x = size.width * CGFloat(i) / CGFloat(humps)
                    let y = floorY + sin(CGFloat(i) * 1.4) * 12 - rnd(i, 900) * 16
                    bed.addLine(to: CGPoint(x: x, y: y))
                }
                bed.addLine(to: CGPoint(x: size.width, y: size.height))
                bed.closeSubpath()
                ctx.fill(bed, with: .color(Color(red: 0.02, green: 0.05, blue: 0.09)))
                ctx.stroke(bed, with: .color(Theme.cleanCyan.opacity(0.18)), lineWidth: 1.5)

                let strands = 8
                for i in 0..<strands {
                    let rootX = size.width * (0.05 + 0.9 * CGFloat(i) / CGFloat(strands - 1)) + (rnd(i, 910) - 0.5) * 26
                    let rootY = floorY + 4
                    let height = size.height * (0.22 + rnd(i, 911) * 0.24)
                    let segs = 11
                    var strand = Path()
                    strand.move(to: CGPoint(x: rootX, y: rootY))
                    for s in 1...segs {
                        let f = CGFloat(s) / CGFloat(segs)
                        let sway = sin(t * 0.8 + Double(i) * 0.9 + Double(f) * 3.2) * Double(8 + f * 22)
                        let x = rootX + CGFloat(sway)
                        let y = rootY - height * f
                        strand.addLine(to: CGPoint(x: x, y: y))
                    }
                    let tint = Color(red: 0.05, green: 0.24 + rnd(i, 913) * 0.14, blue: 0.18)
                    ctx.stroke(strand, with: .color(tint.opacity(0.72)),
                               style: StrokeStyle(lineWidth: 5 + rnd(i, 912) * 4, lineCap: .round))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
