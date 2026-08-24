import SwiftUI

enum Theme {
    static let background = Color(red: 0.055, green: 0.067, blue: 0.086)
    static let elevated = Color(red: 0.09, green: 0.11, blue: 0.14)
    static let chip = Color(red: 0.13, green: 0.16, blue: 0.20)
    static let ink = Color(red: 0.96, green: 0.94, blue: 0.90)
    static let muted = Color.white.opacity(0.48)
    static let down = Color(red: 0.24, green: 0.86, blue: 0.85)
    static let up = Color(red: 0.96, green: 0.65, blue: 0.14)
    static let line = Color.white.opacity(0.08)

    static func bar(_ fraction: Double) -> Color {
        Color(red: 0.93, green: 0.78, blue: 0.42)
            .opacity(0.25 + 0.75 * min(1, max(0, fraction)))
    }
}

extension Font {
    static func meter(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
