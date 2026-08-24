import Charts
import MeterCore
import SwiftUI
import UniformTypeIdentifiers

struct DashboardView: View {
    @EnvironmentObject private var meter: MeterController
    @State private var showSettings = false
    @State private var importError: String?

    private let primaryPeriods: [PeriodKind] = [.today, .thisWeek, .thisMonth, .allTime]
    private let morePeriods: [PeriodKind] = [.yesterday, .lastWeek, .lastMonth, .last30Days, .thisYear]

    var body: some View {
        Group {
            if showSettings {
                SettingsView { showSettings = false }
                    .environmentObject(meter)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        header
                        periodPicker
                        hero
                        chart
                        networks
                        days
                        footer
                    }
                    .padding(16)
                }
            }
        }
        .frame(width: 420, height: 640)
        .background(Theme.background)
        .foregroundStyle(Theme.ink)
        .preferredColorScheme(.dark)
        .alert("Import failed", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("OK", role: .cancel) { importError = nil }
        } message: {
            Text(importError ?? "")
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("METER")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(3.2)
                    .foregroundStyle(Theme.muted)
                Text(meter.status)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.muted)
            }
            Spacer()
            networkMenu
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.muted)
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
    }

    private var networkMenu: some View {
        let items = ["All"] + meter.availableNetworks
        let current = meter.selectedNetwork ?? "All"
        return Button {
            if let index = items.firstIndex(of: current) {
                let next = items[(index + 1) % items.count]
                meter.selectedNetwork = next == "All" ? nil : next
            } else {
                meter.selectedNetwork = nil
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "wifi")
                Text(current)
                    .lineLimit(1)
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Theme.ink.opacity(0.85))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Theme.chip, in: Capsule())
        }
        .buttonStyle(.plain)
        .help("Click to cycle networks")
        .frame(maxWidth: 180)
    }

    private var periodPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                ForEach(primaryPeriods) { kind in
                    chip(kind)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(morePeriods) { kind in
                        chip(kind)
                    }
                }
            }
        }
    }

    private func chip(_ kind: PeriodKind) -> some View {
        let selected = meter.selectedPeriod == kind
        return Button {
            meter.selectedPeriod = kind
        } label: {
            Text(kind.title)
                .font(.system(size: 11, weight: selected ? .semibold : .medium, design: .rounded))
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(selected ? Theme.ink : Theme.chip, in: Capsule())
                .foregroundStyle(selected ? Theme.background : Theme.ink.opacity(0.8))
        }
        .buttonStyle(.plain)
    }

    private var hero: some View {
        let totals = meter.report.totals
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .lastTextBaseline) {
                Text(Bytes.format(totals.totalBytes))
                    .font(.meter(36))
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Spacer()
                speedBadge
            }
            HStack(spacing: 16) {
                labeled(arrow: "↓", color: Theme.down, text: Bytes.format(totals.downBytes))
                labeled(arrow: "↑", color: Theme.up, text: Bytes.format(totals.upBytes))
                if let since = meter.trackingSince {
                    Text("since \(pretty(since))")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.muted)
                }
            }
            if meter.selectedPeriod == .thisMonth, let quota = meter.settings.monthlyQuotaGB, quota > 0 {
                quotaBar(used: totals.totalBytes, quotaGB: quota)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.elevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.line, lineWidth: 1)
        )
    }

    private var speedBadge: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(rate(meter.downBps, "↓"))
                .foregroundStyle(Theme.down)
            Text(rate(meter.upBps, "↑"))
                .foregroundStyle(Theme.up)
        }
        .font(.system(size: 10, weight: .medium, design: .monospaced))
    }

    private var chart: some View {
        let days = meter.report.days
        let maxValue = days.map(\.totals.totalBytes).max() ?? 0
        return VStack(alignment: .leading, spacing: 8) {
            Text(meter.selectedPeriod.title.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(Theme.muted)
            if days.isEmpty {
                Text("No days in this period yet.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.muted)
                    .frame(height: 86)
            } else {
                Chart(days) { day in
                    BarMark(
                        x: .value("Day", day.date),
                        y: .value("Total", Bytes.gigabytes(day.totals.totalBytes))
                    )
                    .foregroundStyle(Theme.down.gradient)
                    .cornerRadius(2)
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartLegend(.hidden)
                .frame(height: 86)
                .opacity(maxValue == 0 ? 0.35 : 1)
            }
        }
    }

    private var networks: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("NETWORKS")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(Theme.muted)
            if meter.report.networks.isEmpty {
                Text("Nothing recorded for this period.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.muted)
            } else {
                let peak = meter.report.networks.first?.totals.totalBytes ?? 1
                ForEach(meter.report.networks.prefix(6)) { row in
                    HStack(spacing: 8) {
                        Text(row.network)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                        GeometryReader { geo in
                            let fraction = peak == 0 ? 0 : Double(row.totals.totalBytes) / Double(peak)
                            Capsule()
                                .fill(Theme.down.opacity(0.7))
                                .frame(width: max(4, geo.size.width * fraction), height: 6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 6)
                        }
                        .frame(height: 16)
                        Text(Bytes.format(row.totals.totalBytes))
                            .font(.system(size: 12, design: .monospaced))
                            .monospacedDigit()
                    }
                }
            }
        }
    }

    private var days: some View {
        let rows = meter.report.days.filter { !$0.totals.isEmpty }
        return VStack(alignment: .leading, spacing: 6) {
            Text("DAYS")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(Theme.muted)
            if rows.isEmpty {
                Text("Bandwidth+ only stores complete days in History. Today is counted live.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(rows.suffix(8).reversed()) { day in
                    HStack {
                        Text(pretty(day.date))
                            .font(.system(size: 12))
                        Spacer()
                        Text("↓ " + Bytes.format(day.totals.downBytes))
                            .foregroundStyle(Theme.down)
                        Text("↑ " + Bytes.format(day.totals.upBytes))
                            .foregroundStyle(Theme.up)
                        Text(Bytes.format(day.totals.totalBytes))
                            .monospacedDigit()
                    }
                    .font(.system(size: 11, design: .monospaced))
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            Button("Import CSV") { pickCSV() }
            Button("Export") { saveCSV() }
            Spacer()
            Button("Quit") { meter.quit() }
        }
        .font(.system(size: 12, weight: .medium))
        .buttonStyle(.plain)
        .foregroundStyle(Theme.muted)
        .padding(.top, 4)
    }

    private func labeled(arrow: String, color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Text(arrow).foregroundStyle(color)
            Text(text).monospacedDigit()
        }
        .font(.system(size: 12, weight: .medium, design: .rounded))
    }

    private func quotaBar(used: UInt64, quotaGB: Double) -> some View {
        let quota = Bytes.gigabyte * quotaGB
        let fraction = quota == 0 ? 0 : min(1, Double(used) / quota)
        return VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.chip)
                    Capsule()
                        .fill(fraction > 0.9 ? Color.red.opacity(0.85) : Theme.up)
                        .frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 6)
            Text("\(Int((fraction * 100).rounded()))% of \(String(format: "%.0f", quotaGB)) GB quota")
                .font(.system(size: 10))
                .foregroundStyle(Theme.muted)
        }
    }

    private func rate(_ bps: Double, _ arrow: String) -> String {
        let bytes = UInt64(max(0, bps))
        return "\(arrow) \(Bytes.compact(bytes))/s"
    }

    private func pretty(_ date: String) -> String {
        guard let parsed = DailyRecord.dayFormatter.date(from: date) else { return date }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d MMM"
        return formatter.string(from: parsed)
    }

    private func pickCSV() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.commaSeparatedText, .plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Choose a Bandwidth+ History.csv export"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try meter.importCSV(at: url)
        } catch {
            importError = error.localizedDescription
        }
    }

    private func saveCSV() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "bandwidth-\(meter.selectedPeriod.rawValue).csv"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? meter.exportSelectedPeriodCSV().write(to: url, atomically: true, encoding: .utf8)
    }
}
