import SwiftUI

struct StreetToDrainScene: View {
    @EnvironmentObject var game: GameState

    private enum Stage { case intro, fork, resolving }

    private struct Kick {
        let time: Double
        let distance: CGFloat
    }

    private let bottleRowFrac: CGFloat = 0.80
    private let kickStartX: CGFloat = 0.15
    private let kicks: [Kick] = [
        Kick(time: 0.26, distance: 0.18),
        Kick(time: 2.26, distance: -0.08),
        Kick(time: 4.26, distance: 0.20),
        Kick(time: 6.26, distance: -0.07),
        Kick(time: 8.26, distance: 0.35)
    ]
    private var kickEndX: CGFloat { kicks.reduce(kickStartX) { $0 + $1.distance } }

    private let pounceStart: Double = 9.39
    private let biteAt: Double = 9.99
    private let shakeEnd: Double = 10.39
    private let carryEnd: Double = 12.39
    private let dogExitEnd: Double = 12.79
    private let sequenceDuration: Double = 12.99

    @State private var stage: Stage = .intro
    @State private var sceneStart = Date()
    @State private var triggeredEvents: Set<String> = []
    @State private var flashOpacity: Double = 0
    @State private var choiceMade = false
    @State private var introCaptionOpacity: Double = 0

    @State private var forkBottlePos = CGPoint(x: 0.5, y: 0.22)
    @State private var forkDragBase = CGPoint(x: 0.5, y: 0.22)
    @State private var forkWrongFeedback = false
    private let landfillForkRect = CGRect(x: 0.08, y: 0.55, width: 0.30, height: 0.3)
    private let drainForkRect = CGRect(x: 0.62, y: 0.55, width: 0.30, height: 0.3)

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                background(size: size)

                RainCanvas(intensity: 1)
                GutterFlowCanvas(bottleRowFrac: bottleRowFrac)
                TrafficStreakCanvas()

                if stage == .intro {
                    TimelineView(.animation(minimumInterval: 1.0 / 45)) { context in
                        let elapsed = context.date.timeIntervalSince(sceneStart)
                        let s = introState(at: elapsed, size: size)

                        ZStack {
                            ForEach(Array(kicks.enumerated()), id: \.offset) { _, kick in
                                KickerFigure(
                                    localTime: elapsed - kick.time,
                                    footX: kickedXFrac(at: kick.time) * size.width,
                                    groundY: size.height * bottleRowFrac,
                                    direction: kick.distance >= 0 ? 1 : -1
                                )
                            }

                            StrayDogView(legPhase: s.legPhase)
                                .frame(width: 184 * s.dogScale, height: 140 * s.dogScale)
                                .scaleEffect(x: -1, y: 1)
                                .opacity(s.dogOpacity)
                                .position(x: s.dogPos.x * size.width, y: s.dogPos.y * size.height - 0.26 * 140 * s.dogScale)

                            BottleView(
                                vibrancy: game.vibrancy, dirt: game.grime, showEyes: false, glow: 0,
                                width: 62, height: 152, tilt: s.bottleTilt
                            )
                            .blur(radius: s.bottleBlur)
                            .position(x: s.bottlePos.x * size.width, y: s.bottlePos.y * size.height)
                        }
                        .onChange(of: elapsed) { _, newValue in
                            handleEvents(at: newValue)
                            if newValue > sequenceDuration {
                                enterFork()
                            }
                        }
                    }
                    .transition(.opacity)
                }

                if stage == .fork || stage == .resolving {
                    forkView(size: size)
                        .transition(.opacity.combined(with: .scale(scale: 0.94)))
                }

                Vignette(strength: 0.5)

                Color.white
                    .opacity(flashOpacity)
                    .blendMode(.plusLighter)
                    .allowsHitTesting(false)

                if stage == .intro {
                    Text("มันไร้ค่า เกะกะขวางทางทุกคน แม้กระทั่งหมา")
                        .font(Theme.line(26))
                        .foregroundStyle(.white.opacity(0.95))
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .opacity(introCaptionOpacity)
                        .position(x: size.width / 2, y: size.height * 0.35)
                }
            }
            .contentShape(Rectangle())
        }
        .onAppear(perform: setup)
    }

    private func background(size: CGSize) -> some View {
        let groundY = size.height * bottleRowFrac
        return ZStack {
            LinearGradient(colors: [Theme.deepNavy, Theme.nearBlack], startPoint: .top, endPoint: .bottom)
            SkylineCanvas()
                .opacity(0.55)
            NeonStreakField(colors: [Theme.neonCyan, Theme.neonPurple, Theme.neonPink])
                .opacity(0.85)

            RoadsideTreesCanvas(roadTopY: groundY)
            groundPlane
            StreetLampRow(roadTopY: groundY, direction: 1)

            LinearGradient(colors: [.clear, Color.white.opacity(0.05), Color.white.opacity(0.02)],
                           startPoint: .top, endPoint: .bottom)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .frame(height: 260)
                .blendMode(.plusLighter)
        }
    }

    private var groundPlane: some View {
        GeometryReader { geo in
            let size = geo.size
            let groundY = size.height * bottleRowFrac
            ZStack(alignment: .top) {
                LinearGradient(
                    colors: [Color(red: 0.05, green: 0.06, blue: 0.08), Color(red: 0.02, green: 0.02, blue: 0.03)],
                    startPoint: .top, endPoint: .bottom
                )
                Rectangle().fill(Color.white.opacity(0.1)).frame(height: 2)
            }
            .frame(width: size.width, height: size.height - groundY)
            .position(x: size.width / 2, y: groundY + (size.height - groundY) / 2)
        }
    }

    private func forkView(size: CGSize) -> some View {
        let landfillBlocked = game.mustRouteToDrain
        let hoveringLandfill = !choiceMade && !landfillBlocked && landfillForkRect.contains(forkBottlePos)
        let hoveringDrain = !choiceMade && drainForkRect.contains(forkBottlePos)

        return ZStack {
            PathChoiceIndicator(
                kind: .landfill,
                bright: hoveringLandfill,
                dim: landfillBlocked,
                containerSize: size
            )
            .position(x: landfillForkRect.midX * size.width, y: landfillForkRect.midY * size.height)

            PathChoiceIndicator(
                kind: .stormDrain,
                bright: hoveringDrain,
                containerSize: size
            )
            .position(x: drainForkRect.midX * size.width, y: drainForkRect.midY * size.height)

            if forkWrongFeedback {
                Label("ไม่มีเสียมให้ขุดแล้ว ลองไปดูที่ท่อระบายน้ำสิ", systemImage: "exclamationmark.triangle.fill")
                    .font(Theme.line(16))
                    .foregroundStyle(Theme.neonAmber)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Theme.nearBlack.opacity(0.78), in: Capsule())
                    .position(x: size.width * 0.5, y: size.height * 0.36)
                    .transition(.opacity)
            }

            BottleView(vibrancy: game.vibrancy, dirt: game.grime, showEyes: false, width: 62, height: 152)
                .position(x: forkBottlePos.x * size.width, y: forkBottlePos.y * size.height)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard !choiceMade else { return }
                    forkBottlePos = CGPoint(
                        x: min(0.95, max(0.05, forkDragBase.x + value.translation.width / size.width)),
                        y: min(0.95, max(0.05, forkDragBase.y + value.translation.height / size.height))
                    )
                }
                .onEnded { _ in
                    guard !choiceMade else { return }
                    evaluateForkDrop(landfillBlocked: landfillBlocked)
                }
        )
    }

    private func evaluateForkDrop(landfillBlocked: Bool) {
        forkDragBase = forkBottlePos
        if drainForkRect.contains(forkBottlePos) {
            resolveFork(towardDrain: true)
        } else if landfillForkRect.contains(forkBottlePos) {
            if landfillBlocked {
                withAnimation(.easeOut(duration: 0.35)) {
                    forkBottlePos = CGPoint(x: 0.5, y: 0.22)
                    forkWrongFeedback = true
                }
                forkDragBase = forkBottlePos
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1.6))
                    guard stage == .fork else { return }
                    withAnimation(.easeOut(duration: 0.25)) { forkWrongFeedback = false }
                }
            } else {
                resolveFork(towardDrain: false)
            }
        }
    }

    private func setup() {
        sceneStart = Date()
        choiceMade = false
        forkBottlePos = CGPoint(x: 0.5, y: 0.22)
        forkDragBase = forkBottlePos
        forkWrongFeedback = false
        triggeredEvents = []
        flashOpacity = 0
        if game.mustRouteToDrain {
            stage = .fork
        } else {
            stage = .intro
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.5))
                guard stage == .intro else { return }
                withAnimation(.easeIn(duration: 1.5)) { introCaptionOpacity = 1 }

                try? await Task.sleep(for: .seconds(4.0))
                guard stage == .intro else { return }
                withAnimation(.easeOut(duration: 1.5)) { introCaptionOpacity = 0 }
            }
        }
    }

    private func enterFork() {
        guard stage == .intro else { return }
        withAnimation(.easeInOut(duration: 0.6)) {
            stage = .fork
        }
    }

    private func kickedXFrac(at t: Double) -> CGFloat {
        var x = kickStartX
        for kick in kicks {
            guard t >= kick.time else { break }
            let localT = min(1, (t - kick.time) / 0.55)
            let eased = 1 - pow(1 - localT, 3)
            x += kick.distance * eased
        }
        return x
    }

    private func kickHopOffset(at t: Double) -> CGFloat {
        var offset: CGFloat = 0
        for kick in kicks {
            guard t >= kick.time else { break }
            let localT = (t - kick.time) / 0.35
            guard localT < 1 else { continue }
            let hopHeight = min(0.045, abs(kick.distance) * 0.11)
            offset = -sin(.pi * localT) * hopHeight
        }
        return offset
    }

    private func kickWobble(at t: Double) -> Double {
        var wobble = 0.0
        for kick in kicks {
            guard t >= kick.time else { break }
            let localT = t - kick.time
            guard localT < 0.8 else { continue }
            let decay = exp(-localT * 5)
            let dir = kick.distance >= 0 ? 1.0 : -1.0
            wobble = sin(localT * 26) * decay * 18 * dir
        }
        return wobble
    }

    private func handleEvents(at elapsed: Double) {
        for (i, kick) in kicks.enumerated() {
            let kickId = "kick_\(i)"
            if elapsed >= kick.time && !triggeredEvents.contains(kickId) {
                triggeredEvents.insert(kickId)
                game.sound.impactThud()
                Haptics.collision()
            }
        }

        if elapsed >= biteAt && !triggeredEvents.contains("bite") {
            triggeredEvents.insert("bite")
            game.registerObstacleHit()
            game.sound.chomp()
            withAnimation(.easeOut(duration: 0.06)) { flashOpacity = 0.55 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.easeIn(duration: 0.5)) { flashOpacity = 0 }
            }
        }
    }

    private func introState(at elapsed: Double, size: CGSize) -> SnatchState {
        let groundY = Double(bottleRowFrac)
        let dogStartX = 1.15
        let exitX = -0.25
        let bottleLift = 55.0 / max(1.0, Double(size.height))

        var dogX = dogStartX
        var dogScale = 0.6
        var dogOpacity = 0.0
        var bottleX = Double(kickedXFrac(at: elapsed))
        var bottleY = groundY + Double(kickHopOffset(at: elapsed))
        var tiltDeg = (bottleX - Double(kickStartX)) * 220 + kickWobble(at: elapsed)
        var blur = 0.0

        switch elapsed {
        case ..<pounceStart:
            break

        case pounceStart..<biteAt:
            let frac = min(1, max(0, (elapsed - pounceStart) / (biteAt - pounceStart)))
            let eased = frac * frac
            dogX = lerp(dogStartX, Double(kickEndX), eased)
            dogScale = lerp(0.6, 1.0, eased)
            dogOpacity = min(1, frac * 3)

        case biteAt..<shakeEnd:
            let shakeT = elapsed - biteAt
            dogX = Double(kickEndX) + sin(shakeT * 40) * 0.01
            dogScale = 1.0
            dogOpacity = 1
            let mx = dogX - 0.07 * dogScale
            bottleX = mx + sin(shakeT * 30) * 0.025
            bottleY = groundY - bottleLift * dogScale + cos(shakeT * 22) * 0.02
            tiltDeg = 90 + 25 * sin(shakeT * 34)
            blur = max(0, min(7, shakeT / 0.15 * 5) + 2 * sin(shakeT * 10))

        case shakeEnd..<carryEnd:
            let frac = min(1, max(0, (elapsed - shakeEnd) / (carryEnd - shakeEnd)))
            dogX = lerp(Double(kickEndX), exitX, frac)
            dogScale = lerp(1.0, 0.8, frac)
            dogOpacity = 1
            bottleX = dogX - 0.07 * dogScale
            bottleY = groundY - bottleLift * dogScale
            tiltDeg = 90 + 6 * sin(elapsed * 20)
            let settleT = min(1, (elapsed - shakeEnd) / 0.3)
            blur = max(0.8, 4 * (1 - settleT))

        case carryEnd..<dogExitEnd:
            let frac = min(1, max(0, (elapsed - carryEnd) / (dogExitEnd - carryEnd)))
            dogX = exitX
            dogScale = 0.8
            dogOpacity = 1 - frac
            bottleX = exitX - 0.07 * dogScale
            bottleY = groundY - bottleLift * dogScale
            tiltDeg = 90
            blur = 0.8 * (1 - frac)

        default:
            dogOpacity = 0
        }

        let legPhase = elapsed * (elapsed < biteAt ? 20 : 18)

        return SnatchState(
            dogPos: CGPoint(x: dogX, y: groundY),
            dogScale: CGFloat(dogScale),
            dogOpacity: dogOpacity,
            legPhase: legPhase,
            bottlePos: CGPoint(x: bottleX, y: bottleY),
            bottleTilt: .degrees(tiltDeg),
            bottleBlur: CGFloat(blur)
        )
    }

    private func resolveFork(towardDrain: Bool) {
        guard !choiceMade else { return }
        choiceMade = true
        stage = .resolving

        let target = towardDrain ? drainForkRect : landfillForkRect
        withAnimation(.easeInOut(duration: 0.6)) {
            forkBottlePos = CGPoint(x: target.midX, y: target.midY)
        }
        game.sound.impactThud()
        Haptics.collision()

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.85))
            if towardDrain {
                game.chooseDrain()
            } else {
                game.chooseLandfill()
            }
        }
    }
}

private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }

private struct SnatchState {
    var dogPos: CGPoint
    var dogScale: CGFloat
    var dogOpacity: Double
    var legPhase: Double
    var bottlePos: CGPoint
    var bottleTilt: Angle
    var bottleBlur: CGFloat
}

private struct KickerFigure: View {
    var localTime: Double
    var footX: CGFloat
    var groundY: CGFloat
    var direction: CGFloat = 1

    private let walkSpeed: CGFloat = 150
    private let skin = Color(red: 0.34, green: 0.37, blue: 0.44)

    var body: some View {
        if localTime > -1.15 && localTime < 0.85 {
            let bodyX = footX + direction * (walkSpeed * CGFloat(localTime) - 13)
            let fadeIn = min(1, max(0, (localTime + 1.15) / 0.3))
            let fadeOut = min(1, max(0, (0.85 - localTime) / 0.3))
            ZStack {
                Ellipse()
                    .fill(Color.black.opacity(0.35))
                    .frame(width: 86, height: 20)
                    .offset(y: 9)

                ZStack(alignment: .bottom) {
                    Capsule().fill(skin).frame(width: 14, height: 52)
                        .overlay(Capsule().stroke(Theme.neonCyan.opacity(0.18), lineWidth: 1.2))
                        .rotationEffect(.degrees(backArmAngle), anchor: .top)
                        .offset(x: -2, y: -99)

                    Capsule().fill(skin).frame(width: 18, height: 83)
                        .overlay(Capsule().stroke(Theme.neonCyan.opacity(0.18), lineWidth: 1.5))
                        .rotationEffect(.degrees(backLegAngle), anchor: .top)
                        .offset(x: -2)

                    VStack(spacing: 7) {
                        Circle().fill(skin).frame(width: 36, height: 36)
                            .offset(x: 4)
                        RoundedRectangle(cornerRadius: 10).fill(skin.opacity(0.92)).frame(width: 28, height: 68)
                    }
                    .overlay(
                        VStack(spacing: 7) {
                            Circle().stroke(Theme.neonCyan.opacity(0.2), lineWidth: 1.5).frame(width: 36, height: 36)
                                .offset(x: 4)
                            RoundedRectangle(cornerRadius: 10).stroke(Theme.neonCyan.opacity(0.2), lineWidth: 1.5).frame(width: 28, height: 68)
                        }
                    )
                    .offset(y: -83)

                    Capsule().fill(skin).frame(width: 18, height: 83)
                        .overlay(Capsule().stroke(Theme.neonCyan.opacity(0.18), lineWidth: 1.5))
                        .rotationEffect(.degrees(frontLegAngle), anchor: .top)
                        .offset(x: 2)

                    Capsule().fill(skin).frame(width: 14, height: 52)
                        .overlay(Capsule().stroke(Theme.neonCyan.opacity(0.18), lineWidth: 1.2))
                        .rotationEffect(.degrees(frontArmAngle), anchor: .top)
                        .offset(x: 2, y: -99)
                }
            }
            .scaleEffect(CGSize(width: direction * 1.4, height: 1.4), anchor: .bottom)
            .opacity(min(fadeIn, fadeOut))
            .position(x: bodyX, y: groundY - 22)
        }
    }

    private var kickPhase: Double? {
        guard localTime > -0.12 && localTime < 0.26 else { return nil }
        return min(1, max(0, (localTime + 0.12) / 0.38))
    }

    private var backLegAngle: Double {
        if kickPhase != nil { return -18 }
        return sin(localTime * 9) * 24
    }

    private var frontLegAngle: Double {
        if let k = kickPhase {
            let eased = sin(k * .pi / 2)
            return -55 + eased * 100
        }
        return -sin(localTime * 9) * 24
    }

    private var backArmAngle: Double {
        if let k = kickPhase {
            let eased = sin(k * .pi / 2)
            return -20 + eased * 45
        }
        return -sin(localTime * 9) * 18
    }

    private var frontArmAngle: Double {
        if let k = kickPhase {
            let eased = sin(k * .pi / 2)
            return 20 - eased * 55
        }
        return sin(localTime * 9) * 18
    }
}

private struct StrayDogView: View {
    var legPhase: Double

    private let fur = Color(red: 0.48, green: 0.36, blue: 0.23)
    private let furDark = Color(red: 0.3, green: 0.21, blue: 0.13)
    private let rim = Theme.neonAmber.opacity(0.4)

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Ellipse()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: w * 0.75, height: h * 0.14)
                    .position(x: w * 0.52, y: h * 0.76)
                    .blur(radius: 2)

                leg(originX: w * 0.24, phase: legPhase, w: w, h: h)
                leg(originX: w * 0.19, phase: legPhase + .pi, w: w, h: h)

                TailShape()
                    .fill(furDark)
                    .frame(width: w * 0.24, height: h * 0.16)
                    .rotationEffect(.degrees(-18 + 10 * sin(legPhase)), anchor: .trailing)
                    .position(x: w * 0.02, y: h * 0.35)

                leg(originX: w * 0.58, phase: legPhase + .pi, w: w, h: h)
                leg(originX: w * 0.63, phase: legPhase, w: w, h: h)

                DogBodyShape()
                    .fill(
                        LinearGradient(colors: [fur, furDark], startPoint: .top, endPoint: .bottom)
                    )
                    .overlay(DogBodyShape().stroke(rim, lineWidth: 1.6))
                    .frame(width: w, height: h * 0.85)
                    .position(x: w * 0.5, y: h * 0.45)

                Ellipse()
                    .fill(furDark)
                    .frame(width: w * 0.07, height: h * 0.13)
                    .rotationEffect(.degrees(20))
                    .position(x: w * 0.74, y: h * 0.1)

                Circle()
                    .fill(Theme.neonAmber)
                    .frame(width: w * 0.018, height: w * 0.018)
                    .position(x: w * 0.8, y: h * 0.12)
            }
        }
    }

    private func leg(originX: CGFloat, phase: Double, w: CGFloat, h: CGFloat) -> some View {
        Capsule()
            .fill(fur)
            .frame(width: w * 0.042, height: h * 0.42)
            .rotationEffect(.degrees(28 * sin(phase)), anchor: .top)
            .position(x: originX, y: h * 0.53)
    }
}

private struct DogBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * w, y: rect.minY + y * h) }

        var p = Path()
        p.move(to: pt(0.08, 0.40))
        p.addQuadCurve(to: pt(0.30, 0.20), control: pt(0.14, 0.16))
        p.addQuadCurve(to: pt(0.54, 0.15), control: pt(0.42, 0.14))
        p.addQuadCurve(to: pt(0.68, 0.08), control: pt(0.60, 0.09))
        p.addQuadCurve(to: pt(0.80, 0.04), control: pt(0.74, 0.02))
        p.addQuadCurve(to: pt(1.0, 0.20), control: pt(0.96, 0.06))
        p.addQuadCurve(to: pt(0.88, 0.31), control: pt(0.96, 0.30))
        p.addLine(to: pt(0.77, 0.33))
        p.addQuadCurve(to: pt(0.64, 0.42), control: pt(0.70, 0.36))
        p.addQuadCurve(to: pt(0.58, 0.60), control: pt(0.60, 0.52))
        p.addQuadCurve(to: pt(0.36, 0.55), control: pt(0.46, 0.60))
        p.addQuadCurve(to: pt(0.22, 0.61), control: pt(0.28, 0.56))
        p.addQuadCurve(to: pt(0.06, 0.56), control: pt(0.12, 0.63))
        p.addQuadCurve(to: pt(0.08, 0.40), control: pt(0.0, 0.48))
        p.closeSubpath()
        return p
    }
}

private struct TailShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * w, y: rect.minY + y * h) }

        var p = Path()
        p.move(to: pt(1.0, 0.35))
        p.addQuadCurve(to: pt(0.55, 0.0), control: pt(0.85, 0.0))
        p.addQuadCurve(to: pt(0.0, 0.45), control: pt(0.2, 0.05))
        p.addQuadCurve(to: pt(0.42, 0.7), control: pt(0.15, 0.75))
        p.addQuadCurve(to: pt(1.0, 0.55), control: pt(0.75, 0.85))
        p.closeSubpath()
        return p
    }
}

private struct GutterFlowCanvas: View {
    var bottleRowFrac: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
            Canvas { ctx, size in
                let t = context.date.timeIntervalSinceReferenceDate
                let floorY = size.height * bottleRowFrac
                let span = size.height - floorY + 60
                let count = 24
                for i in 0..<count {
                    let seed = rnd(i, 210)
                    let baseX = rnd(i, 211) * size.width
                    let speed = 260.0 + Double(rnd(i, 212)) * 190
                    let travel = CGFloat((t * speed).truncatingRemainder(dividingBy: Double(span)))
                    let y = floorY + travel - 40
                    let converge = max(0, min(1, (y - floorY) / span))
                    let x = baseX + (size.width / 2 - baseX) * converge * 0.35
                    let length: CGFloat = 22 + seed * 18
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: y))
                    path.addLine(to: CGPoint(x: x, y: y + length))
                    ctx.stroke(path, with: .color(Theme.neonCyan.opacity(0.08 + seed * 0.09)), lineWidth: 1.3)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct TrafficStreakCanvas: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20)) { context in
            Canvas { ctx, size in
                let t = context.date.timeIntervalSinceReferenceDate
                let bandY = size.height * 0.935
                for i in 0..<3 {
                    let speed = 90.0 + Double(i) * 40
                    let direction: CGFloat = i.isMultiple(of: 2) ? 1 : -1
                    let span = size.width + 220
                    let raw = CGFloat((t * speed).truncatingRemainder(dividingBy: Double(span)))
                    let x = direction > 0 ? raw - 110 : size.width - raw + 110
                    let y = bandY + CGFloat(i) * 10
                    let color = i.isMultiple(of: 2) ? Color.white : Theme.neonPink
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: y))
                    path.addLine(to: CGPoint(x: x + 46 * direction, y: y))
                    ctx.stroke(path, with: .color(color.opacity(0.35)), lineWidth: 2.5)
                }
            }
            .blur(radius: 1.5)
        }
        .allowsHitTesting(false)
    }
}

struct LandfillFailureScene: View {
    @EnvironmentObject var game: GameState
    @State private var showText = false

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let groundY = size.height * 0.46

            ZStack {
                LinearGradient(colors: [Theme.nearBlack, Color(red: 0.09, green: 0.07, blue: 0.05)],
                               startPoint: .top, endPoint: .bottom)

                SmokeCanvas(intensity: 0.5, color: Theme.smokeOrange)
                    .opacity(0.5)
                    .frame(height: groundY)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .clipped()

                BottleView(
                    vibrancy: 0.3, dirt: min(1, game.grime + 0.3), showEyes: false,
                    width: 54, height: 132, tilt: .degrees(16)
                )
                .saturation(0.25)
                .position(x: size.width * 0.52, y: groundY + 30)

                LandfillGroundCanvas(groundY: groundY)

                if showText {
                    Text("การฝังไม่ได้ทำให้หายไปไหน")
                        .font(Theme.line(24))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 26)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: Capsule())
                        .transition(.opacity)
                        .position(x: size.width * 0.5, y: size.height * 0.22)
                }

                Vignette(strength: 0.75)
            }
        }
        .onAppear(perform: runSequence)
    }

    private func runSequence() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.4))
            withAnimation(.easeIn(duration: 0.6)) { showText = true }
            try? await Task.sleep(for: .seconds(3.4))
            withAnimation(.easeOut(duration: 0.4)) { showText = false }
            try? await Task.sleep(for: .seconds(0.4))
            game.returnToForkFromLandfill()
        }
    }
}

private struct LandfillGroundCanvas: View {
    let groundY: CGFloat

    var body: some View {
        Canvas { ctx, size in
            let dirtRect = CGRect(x: 0, y: groundY, width: size.width, height: size.height - groundY)
            ctx.fill(Path(dirtRect), with: .color(Color(red: 0.22, green: 0.16, blue: 0.1)))

            let bandColors: [Color] = [
                Color(red: 0.3, green: 0.22, blue: 0.13),
                Color(red: 0.24, green: 0.17, blue: 0.1),
                Color(red: 0.17, green: 0.12, blue: 0.07),
                Color(red: 0.12, green: 0.08, blue: 0.05)
            ]
            for (i, color) in bandColors.enumerated() {
                let bandT = CGFloat(i + 1) / CGFloat(bandColors.count + 1)
                let y = groundY + (size.height - groundY) * bandT
                var band = Path()
                let steps = 10
                for j in 0...steps {
                    let t = CGFloat(j) / CGFloat(steps)
                    let x = size.width * t
                    let jitter = (rnd(i * 20 + j, 720) - 0.5) * 14
                    let pt = CGPoint(x: x, y: y + jitter)
                    if j == 0 { band.move(to: pt) } else { band.addLine(to: pt) }
                }
                ctx.stroke(band, with: .color(color.opacity(0.85)), lineWidth: 10)
            }

            for i in 0..<20 {
                let x = rnd(i, 730) * size.width
                let y = groundY + rnd(i, 731) * (size.height - groundY)
                let r: CGFloat = 2 + rnd(i, 732) * 3
                ctx.fill(Path(ellipseIn: CGRect(x: x - r / 2, y: y - r / 2, width: r, height: r)),
                         with: .color(.black.opacity(0.3)))
            }

            var edge = Path()
            let edgeSteps = 14
            for j in 0...edgeSteps {
                let t = CGFloat(j) / CGFloat(edgeSteps)
                let x = size.width * t
                let jitter = (rnd(j, 740) - 0.5) * 10
                let pt = CGPoint(x: x, y: groundY + jitter)
                if j == 0 { edge.move(to: pt) } else { edge.addLine(to: pt) }
            }
            ctx.stroke(edge, with: .color(Color(red: 0.35, green: 0.25, blue: 0.15).opacity(0.9)), lineWidth: 3)

            for i in 0..<6 {
                let x = size.width * (0.4 + rnd(i, 750) * 0.24)
                let y = groundY - rnd(i, 751) * 22
                let r: CGFloat = 5 + rnd(i, 752) * 6
                ctx.fill(Path(ellipseIn: CGRect(x: x - r / 2, y: y - r / 2, width: r, height: r)),
                         with: .color(Color(red: 0.26, green: 0.19, blue: 0.11).opacity(0.8)))
            }
        }
        .allowsHitTesting(false)
    }
}
