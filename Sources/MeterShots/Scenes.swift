import MeterCore
import MeterUI
import SwiftUI

/// The real panel, framed the way macOS shows a menu bar window:
/// rounded corners, a hairline edge, and a soft shadow on a clear background.
struct PanelShot<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.28), radius: 16, y: 8)
            .padding(28)
    }
}

/// A plain macOS-style menu bar strip with the real `MenuBarLabel` in it.
/// The Wi-Fi, battery, and clock items are generic scenery.
struct MenuBarStrip: View {
    let meter: MeterController
    let dark: Bool
    var highlighted = false
    var clock = "Fri 9 Oct  18:24"

    var body: some View {
        HStack(spacing: 14) {
            Spacer(minLength: 0)
            MenuBarLabel(meter: meter)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(
                    highlighted ? Color.primary.opacity(0.16) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 5, style: .continuous)
                )
            Image(systemName: "wifi")
            Image(systemName: "battery.75percent")
            Image(systemName: "magnifyingglass")
            Text(clock)
        }
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(.primary)
        .padding(.horizontal, 12)
        .frame(height: 28)
        .background(dark ? Color(white: 0.11).opacity(0.92) : Color(white: 0.97).opacity(0.92))
        .environment(\.colorScheme, dark ? .dark : .light)
    }
}

struct Wallpaper: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.13, green: 0.30, blue: 0.42),
                Color(red: 0.18, green: 0.47, blue: 0.52),
                Color(red: 0.55, green: 0.62, blue: 0.58),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

/// Menu bar strip on a slice of wallpaper, for the light / dark label shots.
struct MenuBarShot: View {
    let meter: MeterController
    let dark: Bool

    var body: some View {
        VStack(spacing: 0) {
            MenuBarStrip(meter: meter, dark: dark)
            Wallpaper().frame(height: 14)
        }
        .frame(width: 460)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(16)
    }
}

/// The header picture: the menu bar with the label selected and the real
/// panel open below it.
struct HeroShot: View {
    let meter: MeterController

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            MenuBarStrip(meter: meter, dark: false, highlighted: true)
            DashboardView()
                .environmentObject(meter)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.35), radius: 20, y: 10)
                .padding(.trailing, 112)
                .padding(.bottom, 36)
        }
        .frame(width: 760)
        .background(Wallpaper())
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(20)
    }
}

/// The real `bandwidth-meter` summary text in a terminal window.
struct TerminalShot: View {
    let command: String
    let output: String

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack(spacing: 8) {
                    Circle().fill(Color(red: 1.0, green: 0.37, blue: 0.34))
                    Circle().fill(Color(red: 1.0, green: 0.74, blue: 0.18))
                    Circle().fill(Color(red: 0.16, green: 0.78, blue: 0.25))
                    Spacer()
                }
                .frame(height: 12)
                Text("bandwidth-meter")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(white: 0.62))
            }
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(Color(white: 0.16))

            VStack(alignment: .leading, spacing: 0) {
                (Text("$ ").foregroundColor(Color(red: 0.24, green: 0.86, blue: 0.85))
                    + Text(command).foregroundColor(Color(white: 0.96)))
                    .padding(.bottom, 4)
                Text(output)
                    .foregroundColor(Color(white: 0.86))
            }
            .font(.system(size: 12.5, weight: .regular, design: .monospaced))
            .lineSpacing(2.5)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.055, green: 0.067, blue: 0.086))
        }
        .frame(width: 600)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.28), radius: 16, y: 8)
        .padding(28)
    }
}
