import SwiftUI

struct PressFadeStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

struct MeterChip: View {
    let title: String
    var selected: Bool = false
    let action: () -> Void

    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: selected ? .semibold : .medium, design: .rounded))
                .lineLimit(1)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .foregroundStyle(selected ? Theme.background : Theme.ink)
                .background(fill, in: Capsule())
        }
        .buttonStyle(PressFadeStyle())
        .onHover { hovered = $0 }
        .accessibilityAddTraits(selected ? AccessibilityTraits.isSelected : [])
    }

    private var fill: Color {
        if selected { return Theme.ink }
        if hovered { return Theme.chipHover }
        return Theme.chip
    }
}

struct QuietButton: View {
    let title: String
    let action: () -> Void

    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(hovered ? Theme.ink : Theme.muted)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(hovered ? Theme.chip : Color.clear, in: Capsule())
        }
        .buttonStyle(PressFadeStyle())
        .onHover { hovered = $0 }
    }
}
