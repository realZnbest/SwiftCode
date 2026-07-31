import SwiftUI

struct LanguageSelectScene: View {
    @EnvironmentObject var game: GameState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var appear = false
    @State private var pressedLanguage: AppLanguage?
    @State private var burstTokens: [AppLanguage: Int] = [:]

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                LinearGradient(colors: [Theme.deepNavy, Theme.nearBlack], startPoint: .top, endPoint: .bottom)
                SkylineCanvas().opacity(0.3)
                NeonStreakField(colors: [Theme.neonCyan, Theme.neonPurple])
                    .opacity(0.35)
                SparkleCanvas(count: 24, color: .white)
                    .opacity(0.5)

                header
                    .position(x: size.width / 2, y: size.height * 0.16)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : -12)

                VStack(spacing: 30) {
                    ForEach(Array(AppLanguage.allCases.enumerated()), id: \.element) { i, language in
                        languageButton(language, index: i)
                    }
                }
                .position(x: size.width / 2, y: size.height * 0.62)

                Vignette(strength: 0.6)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: reduceMotion ? 0.25 : 0.9).delay(reduceMotion ? 0 : 0.25)) {
                appear = true
            }
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("เลือกภาษา")
                .font(Theme.title(30))
                .foregroundStyle(.white.opacity(0.92))
            Text("Select Language")
                .font(Theme.line(22))
                .foregroundStyle(.white.opacity(0.6))
            Text("选择语言")
                .font(Theme.line(22))
                .foregroundStyle(.white.opacity(0.6))
        }
        .glow(Theme.cleanCyan, radius: 10, opacity: 0.3)
    }

    private func languageButton(_ language: AppLanguage, index: Int) -> some View {
        let isPressed = pressedLanguage == language
        let shape = RibbonShape()
        let fan: CGFloat = index == 0 ? -16 : (index == 2 ? 16 : 0)

        return Button {
            tap(language)
        } label: {
            ZStack {
                shape
                    .fill(plateColor(for: language))
                    .overlay(
                        flag(for: language)
                            .opacity(0.3)
                            .clipShape(shape)
                    )
                    .overlay(
                        LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .center, endPoint: .bottom)
                            .clipShape(shape)
                    )
                    .overlay(
                        shape.stroke(Theme.cleanCyan.opacity(isPressed ? 1 : 0.5), lineWidth: isPressed ? 3 : 1.5)
                    )
                    .glow(Theme.cleanCyan, radius: isPressed ? 22 : 7, opacity: isPressed ? 0.55 : 0.16)

                Text(language.nativeName)
                    .font(Theme.title(36))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 6)
                    .glow(Theme.cleanCyan, radius: 14, opacity: isPressed ? 0.6 : 0)

                BurstRingView(shape: shape, trigger: burstTokens[language] ?? 0, reduceMotion: reduceMotion)
                if !reduceMotion {
                    SparkleBurstView(trigger: burstTokens[language] ?? 0)
                }
            }
            .frame(width: 340, height: 104)
            .scaleEffect(isPressed ? 0.95 : 1)
            .offset(x: appear ? 0 : fan, y: appear ? 0 : 24)
            .opacity(appear ? 1 : 0)
            .animation(
                reduceMotion
                    ? .easeOut(duration: 0.2)
                    : .spring(response: 0.65, dampingFraction: 0.78).delay(0.08 * Double(index)),
                value: appear
            )
        }
        .buttonStyle(.plain)
    }

    private func tap(_ language: AppLanguage) {
        game.sound.success()
        burstTokens[language, default: 0] += 1
        withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) {
            pressedLanguage = language
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.16))
            withAnimation(.easeOut(duration: 0.2)) { pressedLanguage = nil }
            try? await Task.sleep(for: .seconds(0.2))
            game.selectLanguage(language)
        }
    }

    private func plateColor(for language: AppLanguage) -> Color {
        switch language {
        case .thai: return Theme.nearBlack.mix(with: Color(red: 0.65, green: 0.13, blue: 0.20), amount: 0.22)
        case .english: return Theme.nearBlack.mix(with: Color(red: 0.05, green: 0.13, blue: 0.36), amount: 0.3)
        case .chinese: return Theme.nearBlack.mix(with: Color(red: 0.72, green: 0.05, blue: 0.06), amount: 0.22)
        }
    }

    @ViewBuilder
    private func flag(for language: AppLanguage) -> some View {
        switch language {
        case .thai: ThaiFlagView()
        case .english: UnionJackFlagView()
        case .chinese: ChinaFlagView()
        }
    }
}

private struct RibbonShape: Shape {
    var notch: CGFloat = 22

    func path(in rect: CGRect) -> Path {
        let notch = min(notch, rect.height / 2)
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - notch, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + notch, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

private struct BurstRingView<S: Shape>: View {
    var shape: S
    var trigger: Int
    var reduceMotion: Bool

    @State private var scale: CGFloat = 0.92
    @State private var opacity: Double = 0

    var body: some View {
        shape
            .stroke(Theme.cleanCyan, lineWidth: 3)
            .scaleEffect(scale)
            .opacity(opacity)
            .onChange(of: trigger) { _, _ in fire() }
    }

    private func fire() {
        guard !reduceMotion else { return }
        scale = 0.92
        opacity = 0.9
        withAnimation(.easeOut(duration: 0.5)) {
            scale = 1.4
            opacity = 0
        }
    }
}

private struct SparkleBurstView: View {
    var trigger: Int

    @State private var progress: CGFloat = 0
    @State private var visible = false

    private let count = 10

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                ForEach(0..<count, id: \.self) { i in
                    let angle = Double(i) / Double(count) * 2 * .pi
                    let radius = min(size.width, size.height) * 0.7 * progress
                    Circle()
                        .fill(Theme.cleanCyan)
                        .frame(width: 5, height: 5)
                        .position(
                            x: size.width / 2 + cos(angle) * radius,
                            y: size.height / 2 + sin(angle) * radius
                        )
                        .opacity(visible ? Double(1 - progress) : 0)
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in fire() }
    }

    private func fire() {
        progress = 0
        visible = true
        withAnimation(.easeOut(duration: 0.5)) {
            progress = 1
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.5))
            visible = false
        }
    }
}

private struct ThaiFlagView: View {
    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let stripe = size.height / 6
            VStack(spacing: 0) {
                Rectangle().fill(Color(red: 0.65, green: 0.13, blue: 0.20)).frame(height: stripe)
                Rectangle().fill(Color.white).frame(height: stripe)
                Rectangle().fill(Color(red: 0.06, green: 0.14, blue: 0.35)).frame(height: stripe * 2)
                Rectangle().fill(Color.white).frame(height: stripe)
                Rectangle().fill(Color(red: 0.65, green: 0.13, blue: 0.20)).frame(height: stripe)
            }
            .frame(width: size.width, height: size.height)
        }
    }
}

private struct UnionJackFlagView: View {
    private let navy = Color(red: 0.0, green: 0.13, blue: 0.36)
    private let red = Color(red: 0.77, green: 0.09, blue: 0.16)

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            Canvas { ctx, s in
                let w = s.width, h = s.height
                ctx.fill(Path(CGRect(x: 0, y: 0, width: w, height: h)), with: .color(navy))

                // Fill the whole ribbon edge to edge. Band thicknesses below are sized off the
                // *height* (h), not the width — sizing off width made bands balloon over the
                // short, wide ribbon and swallow the navy background.
                let fw = w
                let fh = h
                let fx: CGFloat = 0
                let fy: CGFloat = 0

                func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: fx + x, y: fy + y) }

                func diagonalBand(from a: CGPoint, to b: CGPoint, width: CGFloat, color: Color, in context: inout GraphicsContext) {
                    let dx = b.x - a.x, dy = b.y - a.y
                    let len = max(1, (dx * dx + dy * dy).squareRoot())
                    let nx = -dy / len * width / 2
                    let ny = dx / len * width / 2
                    var p = Path()
                    p.move(to: CGPoint(x: a.x + nx, y: a.y + ny))
                    p.addLine(to: CGPoint(x: b.x + nx, y: b.y + ny))
                    p.addLine(to: CGPoint(x: b.x - nx, y: b.y - ny))
                    p.addLine(to: CGPoint(x: a.x - nx, y: a.y - ny))
                    p.closeSubpath()
                    context.fill(p, with: .color(color))
                }

                ctx.fill(Path(CGRect(x: fx, y: fy, width: fw, height: fh)), with: .color(navy))

                // White St Andrew's saltire (both diagonals), sized against the flag box.
                let whiteWidth = fh * 0.34
                diagonalBand(from: pt(0, 0), to: pt(fw, fh), width: whiteWidth, color: .white, in: &ctx)
                diagonalBand(from: pt(fw, 0), to: pt(0, fh), width: whiteWidth, color: .white, in: &ctx)

                // Red St Patrick's saltire, counter-changed: offset to opposite sides of the
                // diagonal in alternating quadrants, the way the real Union Jack is drawn.
                let redWidth = fh * 0.13
                let offset = fh * 0.09

                var topLeftTri = Path()
                topLeftTri.addLines([pt(0, 0), pt(fw, 0), pt(0, fh)])
                topLeftTri.closeSubpath()
                ctx.drawLayer { layer in
                    layer.clip(to: topLeftTri)
                    diagonalBand(from: pt(-offset, -offset), to: pt(fw - offset, fh - offset), width: redWidth, color: red, in: &layer)
                }

                var bottomRightTri = Path()
                bottomRightTri.addLines([pt(fw, 0), pt(fw, fh), pt(0, fh)])
                bottomRightTri.closeSubpath()
                ctx.drawLayer { layer in
                    layer.clip(to: bottomRightTri)
                    diagonalBand(from: pt(offset, offset), to: pt(fw + offset, fh + offset), width: redWidth, color: red, in: &layer)
                }

                var topRightTri = Path()
                topRightTri.addLines([pt(0, 0), pt(fw, 0), pt(fw, fh)])
                topRightTri.closeSubpath()
                ctx.drawLayer { layer in
                    layer.clip(to: topRightTri)
                    diagonalBand(from: pt(fw + offset, -offset), to: pt(-offset, fh - offset), width: redWidth, color: red, in: &layer)
                }

                var bottomLeftTri = Path()
                bottomLeftTri.addLines([pt(0, 0), pt(fw, fh), pt(0, fh)])
                bottomLeftTri.closeSubpath()
                ctx.drawLayer { layer in
                    layer.clip(to: bottomLeftTri)
                    diagonalBand(from: pt(fw - offset, offset), to: pt(offset, fh + offset), width: redWidth, color: red, in: &layer)
                }

                // White St George's cross base, then the red cross on top.
                let crossW = fw * 0.14
                let crossH = fh * 0.32
                ctx.fill(Path(CGRect(x: fx + fw / 2 - crossW / 2, y: fy, width: crossW, height: fh)), with: .color(.white))
                ctx.fill(Path(CGRect(x: fx, y: fy + fh / 2 - crossH / 2, width: fw, height: crossH)), with: .color(.white))

                let redCrossW = fw * 0.08
                let redCrossH = fh * 0.19
                ctx.fill(Path(CGRect(x: fx + fw / 2 - redCrossW / 2, y: fy, width: redCrossW, height: fh)), with: .color(red))
                ctx.fill(Path(CGRect(x: fx, y: fy + fh / 2 - redCrossH / 2, width: fw, height: redCrossH)), with: .color(red))
            }
            .frame(width: size.width, height: size.height)
        }
    }
}

private struct ChinaFlagView: View {
    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                Color(red: 0.72, green: 0.05, blue: 0.06)

                star(size: size.width * 0.1)
                    .position(x: size.width * 0.16, y: size.height * 0.32)

                ForEach(0..<4, id: \.self) { i in
                    let positions: [(CGFloat, CGFloat)] = [
                        (0.30, 0.12), (0.37, 0.24), (0.37, 0.42), (0.30, 0.54)
                    ]
                    star(size: size.width * 0.038)
                        .rotationEffect(.degrees(rotation(for: i)))
                        .position(x: size.width * positions[i].0, y: size.height * positions[i].1)
                }
            }
            .frame(width: size.width, height: size.height)
        }
    }

    private func rotation(for i: Int) -> Double {
        [23, 45, -20, 5][i]
    }

    private func star(size: CGFloat) -> some View {
        Image(systemName: "star.fill")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(Color(red: 1.0, green: 0.85, blue: 0.15))
    }
}
