import SwiftUI

struct LanguageSelectScene: View {
    @EnvironmentObject var game: GameState

    @State private var appear = false

    var body: some View {
        GeometryReader { geo in
            let size = geo.size

            ZStack {
                LinearGradient(colors: [Theme.deepNavy, Theme.nearBlack], startPoint: .top, endPoint: .bottom)
                SkylineCanvas().opacity(0.35)
                NeonStreakField(colors: [Theme.neonCyan, Theme.neonPurple])
                    .opacity(0.45)

                VStack(spacing: 10) {
                    Text("เลือกภาษา")
                        .font(Theme.line(20))
                        .foregroundStyle(.white.opacity(0.7))
                    Text("Select Language")
                        .font(Theme.line(20))
                        .foregroundStyle(.white.opacity(0.7))
                    Text("选择语言")
                        .font(Theme.line(20))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .position(x: size.width / 2, y: size.height * 0.28)
                .opacity(appear ? 1 : 0)

                VStack(spacing: 18) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        languageButton(language)
                    }
                }
                .position(x: size.width / 2, y: size.height * 0.58)
                .opacity(appear ? 1 : 0)

                Vignette(strength: 0.62)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.6)) { appear = true }
        }
    }

    private func languageButton(_ language: AppLanguage) -> some View {
        Button {
            game.selectLanguage(language)
        } label: {
            Text(language.nativeName)
                .font(Theme.line(22))
                .foregroundStyle(.white)
                .frame(width: 220)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(Theme.cleanCyan.opacity(0.6), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}
