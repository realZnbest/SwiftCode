import SwiftUI
import UIKit

enum Theme {

    static let deepNavy = Color(red: 0.02, green: 0.03, blue: 0.07)
    static let nearBlack = Color(red: 0.01, green: 0.01, blue: 0.02)

    static let bottleBlue = Color(red: 0.35, green: 0.72, blue: 0.95)
    static let bottleBlueDeep = Color(red: 0.10, green: 0.32, blue: 0.55)
    static let bottleHighlight = Color.white

    static let neonPink = Color(red: 1.0, green: 0.25, blue: 0.55)
    static let neonCyan = Color(red: 0.25, green: 0.95, blue: 1.0)
    static let neonPurple = Color(red: 0.55, green: 0.35, blue: 1.0)
    static let neonAmber = Color(red: 1.0, green: 0.7, blue: 0.25)

    static let murkGreen = Color(red: 0.18, green: 0.26, blue: 0.16)
    static let murkBrown = Color(red: 0.22, green: 0.17, blue: 0.10)
    static let smokeOrange = Color(red: 0.55, green: 0.32, blue: 0.14)
    static let mutedSeaTeal = Color(red: 0.4, green: 0.62, blue: 0.58)

    static let cleanCyan = Color(red: 0.35, green: 0.9, blue: 1.0)
    static let cleanWhite = Color(red: 0.92, green: 0.98, blue: 1.0)
    static let freshGreen = Color(red: 0.4, green: 0.95, blue: 0.55)

    static func title(_ size: CGFloat = 34) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func line(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }

    static func hash(_ i: Int) -> Double {
        let s = sin(Double(i) * 12.9898 + 78.233) * 43758.5453
        return s - floor(s)
    }

    static func hash(_ i: Int, _ salt: Int) -> Double {
        hash(i &* 92821 &+ salt)
    }
}

extension Color {
    func mix(with other: Color, amount: Double) -> Color {
        let a = min(max(amount, 0), 1)
        let c1 = UIColor(self)
        let c2 = UIColor(other)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        c1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        c2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return Color(
            red: Double(r1 + (r2 - r1) * a),
            green: Double(g1 + (g2 - g1) * a),
            blue: Double(b1 + (b2 - b1) * a)
        )
    }
}

extension View {
    func glow(_ color: Color, radius: CGFloat = 12, opacity: Double = 0.8) -> some View {
        self
            .shadow(color: color.opacity(opacity), radius: radius)
            .shadow(color: color.opacity(opacity * 0.6), radius: radius * 2)
    }
}
