import SwiftUI

struct TitleScene: View {
    @EnvironmentObject var game: GameState

    @State private var appear = false
    @State private var tapped = false
    @State private var burstToken = 0

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                // The whole scene is a tap target via a real Button (not .onTapGesture).
                // A bare .onTapGesture on this background raced with the back-text Button
                // below: both could fire on the same tap, so "back" would land on
                // languageSelect and then beginTapped()'s queued advanceFromTitle() would
                // stomp it 0.22s later. Two sibling Buttons hit-test exclusively against
                // each other in SwiftUI, so this removes the race instead of papering over it.
                Button {
                    beginTapped()
                } label: {
                    ZStack {
                        LinearGradient(colors: [Theme.deepNavy, Theme.nearBlack], startPoint: .top, endPoint: .bottom)
                        SkylineCanvas().opacity(0.35)
                        NeonStreakField(colors: [Theme.neonCyan, Theme.neonPurple])
                            .opacity(0.45)

                        spotlightGlow(size: size)

                        SparkleCanvas(count: 30, color: .white)
                            .opacity(0.6)
                            .mask(spotlightMask(size: size))

                        BottleView(vibrancy: 1, dirt: 0, showEyes: true, width: 46, height: 112)
                            .position(x: size.width / 2, y: size.height * 0.66)
                            .opacity(appear ? 1 : 0)
                            .offset(y: appear ? 0 : 16)

                        VStack(spacing: 8) {
                            Text(game.t(Loc.titleName))
                                .font(.system(size: 52, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .glow(Theme.cleanCyan, radius: 16, opacity: 0.5)
                            Text(game.t(Loc.titleSubtitle))
                                .font(Theme.line(17))
                                .foregroundStyle(.white.opacity(0.65))
                        }
                        .position(x: size.width / 2, y: size.height * 0.26)
                        .opacity(appear ? 1 : 0)

                        tapToBeginLabel(size: size)

                        Vignette(strength: 0.62)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(tapped)

                backToLanguageButton(size: size)
            }
        }
        .onAppear(perform: runSequence)
    }

    private func backToLanguageButton(size: CGSize) -> some View {
        Button {
            guard !tapped else { return }
            game.goTo(.languageSelect)
        } label: {
            Text(game.t(Loc.titleBackToLanguage))
                .font(Theme.line(14))
                .foregroundStyle(.white.opacity(0.55))
        }
        .buttonStyle(.plain)
        .position(x: size.width / 2, y: size.height * 0.945)
        .opacity(appear && !tapped ? 1 : 0)
        .disabled(!appear || tapped)
        .animation(.easeOut(duration: 0.25), value: tapped)
    }

    private func tapToBeginLabel(size: CGSize) -> some View {
        ZStack {
            beaconRing

            TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                let glow = 0.4 + 0.55 * (0.5 + 0.5 * sin(t * 1.7))
                let breathe = 1 + 0.045 * (0.5 + 0.5 * sin(t * 1.7))

                Text(game.t(Loc.titleTapToBegin))
                    .font(Theme.line(16))
                    .foregroundStyle(.white.opacity(glow))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(Theme.cleanCyan.opacity(0.4), lineWidth: 1.2))
                    .scaleEffect(breathe)
            }

            BurstRingView(shape: Capsule(), trigger: burstToken)
                .frame(width: 132, height: 44)
            SparkleBurstView(trigger: burstToken, count: 14)
                .frame(width: 132, height: 44)
        }
        .scaleEffect(tapped ? 0.9 : 1)
        .position(x: size.width / 2, y: size.height * 0.88)
        .opacity(appear ? 1 : 0)
        .animation(.spring(response: 0.2, dampingFraction: 0.4), value: tapped)
    }

    private var beaconRing: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let period = 1.8
            let phase = (t.truncatingRemainder(dividingBy: period)) / period

            Capsule()
                .stroke(Theme.cleanCyan, lineWidth: 1.5)
                .frame(width: 132, height: 44)
                .scaleEffect(1 + phase * 0.5)
                .opacity((1 - phase) * 0.45)
        }
    }

    private func spotlightGlow(size: CGSize) -> some View {
        RadialGradient(
            colors: [Color.white.opacity(0.16), .clear],
            center: UnitPoint(x: 0.5, y: 0.62), startRadius: 10, endRadius: size.width * 0.42
        )
    }

    private func spotlightMask(size: CGSize) -> some View {
        RadialGradient(
            colors: [.white, .clear],
            center: UnitPoint(x: 0.5, y: 0.62), startRadius: 10, endRadius: size.width * 0.42
        )
    }

    private func runSequence() {
        withAnimation(.easeIn(duration: 1.0).delay(0.3)) { appear = true }
    }

    private func beginTapped() {
        guard !tapped else { return }
        tapped = true
        burstToken += 1
        game.sound.success()
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.22))
            game.advanceFromTitle()
        }
    }
}
