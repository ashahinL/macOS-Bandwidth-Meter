import Charts
import MeterCore
import SwiftUI
import UniformTypeIdentifiers

public struct DashboardView: View {
    @EnvironmentObject private var meter: MeterController
    @State private var showSettings = false
    @State private var actionError: String?
    @State private var gearHover = false
    @State private var networkHover = false

    private let primaryPeriods: [PeriodKind] = [.today, .thisWeek, .thisMonth, .allTime]
    private let morePeriods: [PeriodKind] = [.yesterday, .lastWeek, .lastMonth, .last30Days, .thisYear]

    public init() {}

    public var body: some View {
        Group {
            if showSettings {
                SettingsView { showSettings = false }
                    .environmentObject(meter)
            } else {
                dashboard
            }
        }
        .frame(width: 420, height: 640)
        .background(Theme.background)
        .foregroundStyle(Theme.ink)
        .preferredColorScheme(.dark)
    }

    private var dashboard: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    periodPicker
                    hero
                    chart
                    networks
                        .padding(.top, 8)
                    days
                        .padding(.top, 8)
                }
                .padding(16)
            }
            bottomBar
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(meter.status)
                .font(.system(size: 12, weight: meter.statusIsProblem ? .semibold : .medium))
                .foregroundStyle(meter.statusIsProblem ? Theme.danger : Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            networkMenu
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(gearHover ? Theme.ink : Theme.muted)
                    .frame(width: 28, height: 28)
                    .background(gearHover ? Theme.chip : Color.clear, in: Circle())
            }
            .buttonStyle(PressFadeStyle())
            .onHover { gearHover = $0 }
            .accessibilityLabel("Settings")
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
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(networkHover ? Theme.chipHover : Theme.chip, in: Capsule())
        }
        .buttonStyle(PressFadeStyle())
        .onHover { networkHover = $0 }
        .help("Show the next network")
        .accessibilityLabel("Network")
        .accessibilityValue(current)
        .frame(maxWidth: 180)
    }

    private var periodPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                ForEach(primaryPeriods) { kind in
                    periodChip(kind)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(morePeriods) { kind in
                        periodChip(kind)
                    }
                }
            }
        }
    }

    private func periodChip(_ kind: PeriodKind) -> some View {
        MeterChip(title: kind.title, selected: meter.selectedPeriod == kind) {
            meter.selectedPeriod = kind
        }
    }

    private var hero: some View {
        let totals = meter.report.totals
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .lastTextBaseline, spacing: 12) {
                Text(Bytes.format(totals.totalBytes))
                    .font(.meter(36))
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .accessibilityLabel("Total \(Bytes.format(totals.totalBytes))")
                Spacer(minLength: 8)
                speedBadge
            }
            HStack(spacing: 14) {
                flowLabel(systemName: "arrow.down", color: Theme.down, text: Bytes.format(totals.downBytes), name: "Download")
                flowLabel(systemName: "arrow.up", color: Theme.up, text: Bytes.format(totals.upBytes), name: "Upload")
                if let since = meter.trackingSince {
                    Text("since \(pretty(since))")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.muted)
                        .lineLimit(1)
                }
            }
            if meter.selectedPeriod == .thisMonth, let quota = meter.settings.monthlyQuotaGB, quota > 0 {
                quotaBar(used: totals.totalBytes, quotaGB: quota)
            }
        }
    }

    private var speedBadge: some View {
        VStack(alignment: .trailing, spacing: 2) {
            speedLine(systemName: "arrow.down", bps: meter.downBps, color: Theme.down, name: "Download")
            speedLine(systemName: "arrow.up", bps: meter.upBps, color: Theme.up, name: "Upload")
        }
    }

    private var chart: some View {
        let days = meter.report.days
        let maxValue = days.map(\.totals.totalBytes).max() ?? 0
        return VStack(alignment: .leading, spacing: 8) {
            if days.isEmpty {
                Text("No days in this period yet.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity, minHeight: 86, alignment: .leading)
            } else {
                Text("Peak \(Bytes.format(maxValue))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.muted)
                Chart(days) { day in
                    BarMark(
                        x: .value("Day", day.date),
                        y: .value("Total", Bytes.gigabytes(day.totals.totalBytes))
                    )
                    .foregroundStyle(Theme.down)
                    .cornerRadius(2)
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartLegend(.hidden)
                .frame(height: 86)
                .opacity(maxValue == 0 ? 0.35 : 1)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Daily totals. Peak \(Bytes.format(maxValue)).")
            }
        }
    }

    private var networks: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Networks")
            if meter.report.networks.isEmpty {
                Text("Nothing recorded for this period.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.muted)
            } else {
                let peak = meter.report.networks.first?.totals.totalBytes ?? 1
                ForEach(meter.report.networks.prefix(6)) { row in
                    HStack(alignment: .center, spacing: 8) {
                        Text(row.network)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: 168, alignment: .leading)
                        networkBar(value: row.totals.totalBytes, peak: peak)
                            .frame(minWidth: 48)
                        Text(Bytes.format(row.totals.totalBytes))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .layoutPriority(1)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private func networkBar(value: UInt64, peak: UInt64) -> some View {
        GeometryReader { geo in
            let fraction = peak == 0 ? 0 : Double(value) / Double(peak)
            Capsule()
                .fill(Theme.down.opacity(0.85))
                .frame(width: max(4, geo.size.width * fraction), height: 5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(height: 12)
        .accessibilityHidden(true)
    }

    private var days: some View {
        let rows = meter.report.days.filter { !$0.totals.isEmpty }
        return VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Days")
            if rows.isEmpty {
                Text("Bandwidth+ only stores complete days in History. Today is counted live.")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(rows.suffix(8).reversed()) { day in
                    HStack(spacing: 8) {
                        Text(pretty(day.date))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .frame(width: 92, alignment: .leading)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        flowLabel(
                            systemName: "arrow.down",
                            color: Theme.down,
                            text: Bytes.format(day.totals.downBytes),
                            name: "Download"
                        )
                        .frame(width: 86, alignment: .leading)
                        flowLabel(
                            systemName: "arrow.up",
                            color: Theme.up,
                            text: Bytes.format(day.totals.upBytes),
                            name: "Upload"
                        )
                        .frame(width: 86, alignment: .leading)
                        Text(Bytes.format(day.totals.totalBytes))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .frame(width: 72, alignment: .trailing)
                            .lineLimit(1)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private var bottomBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let actionError {
                Text(actionError)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.danger)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 4) {
                QuietButton(title: "Import CSV") { pickCSV() }
                QuietButton(title: "Export") { saveCSV() }
                Spacer(minLength: 8)
                QuietButton(title: "Quit") { meter.quit() }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.background)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Theme.line)
                .frame(height: 1)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Theme.muted)
    }

    private func flowLabel(systemName: String, color: Color, text: String, name: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: systemName)
                .font(.system(size: 9, weight: .bold))
            Text(text)
                .monospacedDigit()
                .lineLimit(1)
        }
        .font(.system(size: 12, weight: .medium, design: .rounded))
        .foregroundStyle(color)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name) \(text)")
    }

    private func speedLine(systemName: String, bps: Double, color: Color, name: String) -> some View {
        let text = "\(Bytes.compact(UInt64(max(0, bps))))/s"
        return HStack(spacing: 3) {
            Image(systemName: systemName)
                .font(.system(size: 9, weight: .bold))
            Text(text)
                .monospacedDigit()
                .lineLimit(1)
        }
        .font(.system(size: 11, weight: .medium, design: .rounded))
        .foregroundStyle(color)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(name) \(text)")
    }

    private func quotaBar(used: UInt64, quotaGB: Double) -> some View {
        let quota = Bytes.gigabyte * quotaGB
        let fraction = quota == 0 ? 0 : min(1, Double(used) / quota)
        let percent = Int((fraction * 100).rounded())
        return VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.chip)
                    Capsule()
                        .fill(fraction > 0.9 ? Theme.danger : Theme.down)
                        .frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 6)
            .accessibilityHidden(true)
            Text("\(percent)% of \(String(format: "%.0f", quotaGB)) GB quota")
                .font(.system(size: 12))
                .foregroundStyle(fraction > 0.9 ? Theme.danger : Theme.muted)
        }
        .accessibilityElement(children: .combine)
    }

    private func pretty(_ date: String) -> String {
        guard let parsed = DailyRecord.dayFormatter.date(from: date) else { return date }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d MMM"
        return formatter.string(from: parsed)
    }

    private func pickCSV() {
        actionError = nil
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.commaSeparatedText, .plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Choose a Bandwidth+ History.csv export"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try meter.importCSV(at: url)
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func saveCSV() {
        actionError = nil
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "bandwidth-\(meter.selectedPeriod.rawValue).csv"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try meter.exportSelectedPeriodCSV().write(to: url, atomically: true, encoding: .utf8)
        } catch {
            actionError = error.localizedDescription
        }
    }
}
