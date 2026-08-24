import MeterCore
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var meter: MeterController
    var onClose: () -> Void

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Settings")
                        .font(.meter(20))
                    Spacer()
                    Button("Done", action: onClose)
                        .font(.system(size: 13, weight: .semibold))
                        .buttonStyle(.plain)
                        .foregroundStyle(Theme.down)
                }

                field("Menu bar shows") {
                    FlexibleChips(
                        items: PeriodKind.allCases,
                        selection: meter.settings.menuBarPeriod,
                        title: { $0.title }
                    ) { kind in
                        meter.updateSettings { $0.menuBarPeriod = kind }
                    }
                }

                Toggle("Week starts on Monday", isOn: weekBinding)
                    .toggleStyle(.switch)

                field("Billing cycle start day") {
                    Stepper(value: billingBinding, in: 1...28) {
                        Text(meter.settings.billingDay == 1 ? "1 (calendar month)" : "Day \(meter.settings.billingDay)")
                            .font(.system(size: 13, design: .rounded))
                    }
                }

                field("Monthly quota (GB, 0 = off)") {
                    Stepper(value: quotaBinding, in: 0...10_000, step: 50) {
                        Text(meter.settings.monthlyQuotaGB == nil ? "Off" : "\(Int(meter.settings.monthlyQuotaGB ?? 0)) GB")
                            .font(.system(size: 13, design: .rounded))
                    }
                }

                Toggle("Open at login", isOn: loginBinding)
                    .toggleStyle(.switch)

                Toggle("Show live speed in menu bar", isOn: speedBinding)
                    .toggleStyle(.switch)

                Text("Menu and dropdown controls close a menu-bar window on macOS, so settings use tappable chips and steppers instead. Weekly and monthly totals come from Bandwidth+ daily history.")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
        }
        .frame(width: 420, height: 640)
        .background(Theme.background)
        .foregroundStyle(Theme.ink)
        .preferredColorScheme(.dark)
    }

    private var weekBinding: Binding<Bool> {
        Binding(
            get: { meter.settings.weekStartsOnMonday },
            set: { value in meter.updateSettings { $0.weekStartsOnMonday = value } }
        )
    }

    private var billingBinding: Binding<Int> {
        Binding(
            get: { meter.settings.billingDay },
            set: { value in meter.updateSettings { $0.billingDay = value } }
        )
    }

    private var quotaBinding: Binding<Double> {
        Binding(
            get: { meter.settings.monthlyQuotaGB ?? 0 },
            set: { value in meter.updateSettings { $0.monthlyQuotaGB = value <= 0 ? nil : value } }
        )
    }

    private var loginBinding: Binding<Bool> {
        Binding(
            get: { meter.settings.launchAtLogin },
            set: { value in meter.updateSettings { $0.launchAtLogin = value } }
        )
    }

    private var speedBinding: Binding<Bool> {
        Binding(
            get: { meter.settings.showSpeedInMenuBar },
            set: { value in meter.updateSettings { $0.showSpeedInMenuBar = value } }
        )
    }

    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(1.1)
                .foregroundStyle(Theme.muted)
            content()
        }
    }
}

struct FlexibleChips<Item: Hashable>: View {
    let items: [Item]
    let selection: Item
    let title: (Item) -> String
    let onSelect: (Item) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { item in
                        let selected = item == selection
                        Button {
                            onSelect(item)
                        } label: {
                            Text(title(item))
                                .font(.system(size: 11, weight: selected ? .semibold : .medium, design: .rounded))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 6)
                                .background(selected ? Theme.ink : Theme.chip, in: Capsule())
                                .foregroundStyle(selected ? Theme.background : Theme.ink.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var rows: [[Item]] {
        var result: [[Item]] = []
        var current: [Item] = []
        var width = 0
        for item in items {
            let estimate = title(item).count + 4
            if !current.isEmpty && width + estimate > 36 {
                result.append(current)
                current = [item]
                width = estimate
            } else {
                current.append(item)
                width += estimate
            }
        }
        if !current.isEmpty { result.append(current) }
        return result
    }
}

