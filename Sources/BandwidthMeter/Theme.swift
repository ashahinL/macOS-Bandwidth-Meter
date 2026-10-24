import SwiftUI

enum Theme {
    static let background = Color(red: 0.055, green: 0.067, blue: 0.086)
    static let chip = Color(red: 0.13, green: 0.16, blue: 0.20)
    static let chipHover = Color(red: 0.18, green: 0.22, blue: 0.27)
    static let ink = Color(red: 0.96, green: 0.94, blue: 0.90)
    static let muted = Color(red: 0.68, green: 0.65, blue: 0.59)
    static let down = Color(red: 0.24, green: 0.86, blue: 0.85)
    static let up = Color(red: 0.96, green: 0.65, blue: 0.14)
    static let danger = Color(red: 0.96, green: 0.55, blue: 0.48)
    static let line = Color.white.opacity(0.10)
}

extension Font {
    static func meter(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
