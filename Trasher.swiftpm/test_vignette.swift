import SwiftUI

struct VignetteScene<Content: View>: View {
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

    var body: some View { Text("Test") }
}

struct FactoryOriginScene: View {
    var body: some View {
        VignetteScene(
            line: "Made to be used once.",
            accessibilityText: "A factory line. The bottle is filled and sealed, brand new.",
            bottlePosition: UnitPoint(x: 0.5, y: 0.82),
            bottleGlow: 0.35,
            textPosition: UnitPoint(x: 0.5, y: 0.65),
            content: { _ in
                Text("Test")
            },
            onFinish: { }
        )
    }
}
