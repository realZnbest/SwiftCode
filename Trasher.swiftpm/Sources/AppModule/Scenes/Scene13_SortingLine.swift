import SwiftUI

struct SortingLineScene: View {
    @EnvironmentObject var game: GameState

    @State private var showText = false
    @State private var sliderValue: CGFloat = 0
    @State private var dragStartValue: CGFloat = 0
    @State private var delivered = false

    var body: some View {
        GeometryReader { geo in
            let size: CGSize = geo.size
            let beltY: CGFloat = size.height * 0.8
            let restX: CGFloat = size.width * 0.22
            let gatewayX: CGFloat = size.width * 0.94
            let bottleTravel: CGFloat = gatewayX - restX
            let bottleX: CGFloat = restX + bottleTravel * sliderValue
            let bottleY: CGFloat = beltY - 46
            let trackStartX: CGFloat = size.width * 0.14
            let trackEndX: CGFloat = gatewayX
            let trackWidth: CGFloat = trackEndX - trackStartX
            let trackY: CGFloat = beltY + 44

            let bottleOpacity: Double = {
                guard sliderValue > 0.85 else { return 1 }
                let fadeAmount: Double = (Double(sliderValue) - 0.85) / 0.15
                return max(0, 1 - fadeAmount)
            }()

            TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                let t: Double = context.date.timeIntervalSinceReferenceDate
                let scanWave: Double = 0.5 + 0.5 * sin(t * 1.3)
                let scanX: CGFloat = size.width * (0.2 + 0.6 * scanWave)
                let gatewayPulse: Double = 0.6 + 0.4 * sin(t * 2.4)

                ZStack {
                    LinearGradient(
                        colors: [Color(red: 0.03, green: 0.10, blue: 0.09), Color(red: 0.02, green: 0.05, blue: 0.05)],
                        startPoint: .top, endPoint: .bottom
                    )
                    RecyclingEmblemGlow(brighten: 0)
                    RecyclingGreenhouseRoof()
                    SortingBeltStructure(beltYFrac: 0.8)
                    SortingFloorGlow()
                    LightRaysCanvas(color: Theme.freshGreen, count: 3)

                    Rectangle()
                        .fill(LinearGradient(colors: [.clear, Theme.cleanCyan.opacity(0.55), .clear], startPoint: .top, endPoint: .bottom))
                        .frame(width: 4, height: size.height)
                        .position(x: scanX, y: size.height / 2)
                        .blur(radius: 2)

                    RecyclingGatewayView(height: size.height * 0.62, pulse: gatewayPulse)
                        .position(x: size.width, y: beltY - (size.height * 0.31))

                    BottleView(vibrancy: game.vibrancy, dirt: game.grime, showEyes: false, width: 44, height: 108)
                        .scaleEffect(delivered ? 0.4 : 1)
                        .opacity(bottleOpacity)
                        .position(x: bottleX, y: bottleY)

                    SortingSliderView(
                        value: sliderValue,
                        size: size,
                        trackStartX: trackStartX,
                        trackWidth: trackWidth,
                        trackY: trackY,
                        time: t
                    )
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard !delivered else { return }
                                let deltaFrac = value.translation.width / trackWidth
                                sliderValue = min(1, max(0, dragStartValue + deltaFrac))
                            }
                            .onEnded { _ in
                                dragStartValue = sliderValue
                            }
                    )

                    if showText {
                        Text(game.t(Loc.sortingLineLine))
                            .font(Theme.line(21))
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 26)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial, in: Capsule())
                            .transition(.opacity)
                            .position(x: size.width * 0.5, y: size.height * 0.18)
                    }

                    Vignette(strength: 0.55)
                }
                .onChange(of: sliderValue) { _, newValue in
                    if newValue >= 0.94 {
                        deliver()
                    }
                }
            }
        }
        .onAppear(perform: run)
    }

    private func deliver() {
        guard !delivered else { return }
        delivered = true
        game.sound.impactThud()
        withAnimation(.easeOut(duration: 0.25)) { sliderValue = 1 }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.5))
            game.advanceFromSortingLine()
        }
    }

    private func run() {
        sliderValue = 0
        dragStartValue = 0
        delivered = false
        withAnimation(.easeIn(duration: 0.5).delay(0.4)) { showText = true }
    }
}

private struct RecyclingGatewayView: View {
    var height: CGFloat
    var pulse: Double

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(colors: [Color(red: 0.3, green: 0.3, blue: 0.32), Color(red: 0.05, green: 0.05, blue: 0.06)], startPoint: .top, endPoint: .bottom))
                .frame(width: 62, height: height * 0.72)
                .offset(x: -34)
            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(colors: [Color(red: 0.24, green: 0.24, blue: 0.26), Color(red: 0.05, green: 0.05, blue: 0.06)], startPoint: .top, endPoint: .bottom))
                .frame(width: 88, height: height)

            Rectangle()
                .fill(Color.white.opacity(0.55))
                .frame(width: 3, height: height * 0.85)
                .blur(radius: 1)
                .opacity(pulse)

            Image(systemName: "arrow.3.trianglepath")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white.opacity(0.85))
                .offset(y: height * 0.32)
        }
    }
}

private struct SortingSliderView: View {
    var value: CGFloat
    var size: CGSize
    var trackStartX: CGFloat
    var trackWidth: CGFloat
    var trackY: CGFloat
    var time: Double

    private var thumbX: CGFloat { trackStartX + trackWidth * value }
    private var fillWidth: CGFloat { max(0, thumbX - trackStartX) }

    private func chevronPhase(_ index: Int) -> Double {
        let raw: Double = time * 0.22 + Double(index) / 3
        return raw.truncatingRemainder(dividingBy: 1)
    }

    var body: some View {
        ZStack {
            Capsule()
                .fill(LinearGradient(colors: [Color.white.opacity(0.12), Theme.cleanCyan.opacity(0.35)], startPoint: .leading, endPoint: .trailing))
                .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1.5))
                .frame(width: trackWidth, height: 30)
                .position(x: trackStartX + trackWidth / 2, y: trackY)

            Capsule()
                .fill(Theme.cleanCyan.opacity(0.7))
                .frame(width: fillWidth, height: 30)
                .position(x: trackStartX + fillWidth / 2, y: trackY)

            ForEach(0..<3, id: \.self) { i in
                let phase: Double = chevronPhase(i)
                let chevronOpacity: Double = 0.75 * (1 - phase)
                let chevronX: CGFloat = trackStartX + trackWidth * CGFloat(phase)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(chevronOpacity))
                    .position(x: chevronX, y: trackY)
            }

            Circle()
                .fill(Color.white)
                .overlay(Circle().stroke(Theme.cleanCyan, lineWidth: 3))
                .frame(width: 40, height: 40)
                .position(x: thumbX, y: trackY)
        }
        .frame(width: size.width, height: size.height)
    }
}
