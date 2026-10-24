import MeterCore
import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject private var meter: MeterController
    var onClose: () -> Void

    public init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Settings")
                        .font(.meter(20))
                    Spacer()
                    Button(action: onClose) {
                        Text("Done")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.background)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.down, in: Capsule())
                    }
                    .buttonStyle(PressFadeStyle())
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
                    .tint(Theme.down)

                field("Billing cycle start day") {
                    Stepper(value: billingBinding, in: 1...28) {
                        Text(meter.settings.billingDay == 1 ? "1 (calendar month)" : "Day \(meter.settings.billingDay)")
                            .font(.system(size: 13, design: .rounded))
                    }
                }

                field("Monthly quota") {
                    Stepper(value: quotaBinding, in: 0...10_000, step: 50) {
                        Text(meter.settings.monthlyQuotaGB == nil ? "Off" : "\(Int(meter.settings.monthlyQuotaGB ?? 0)) GB")
                            .font(.system(size: 13, design: .rounded))
                    }
                }

                Toggle("Open at login", isOn: loginBinding)
                    .toggleStyle(.switch)
                    .tint(Theme.down)

                Toggle("Show live speed in menu bar", isOn: speedBinding)
                    .toggleStyle(.switch)
                    .tint(Theme.down)

                Text("Weekly and monthly totals come from Bandwidth+ daily history.")
                    .font(.system(size: 12))
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
            Text(title)
                .font(.system(size: 12, weight: .medium))
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
                        MeterChip(title: title(item), selected: item == selection) {
                            onSelect(item)
                        }
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

