import Foundation

public enum Report {
    public static func text(
        records: [DailyRecord],
        now: Date = Date(),
        settings: MeterSettings = .default,
        timeZone: TimeZone = .current,
        sourceNote: String? = nil
    ) -> String {
        let kinds: [PeriodKind] = [
            .today, .yesterday, .thisWeek, .lastWeek, .thisMonth, .lastMonth, .last30Days, .thisYear, .allTime,
        ]
        var lines: [String] = []
        let stamp = DateFormatter.localizedString(from: now, dateStyle: .medium, timeStyle: .none)
        lines.append("Bandwidth Meter")
        lines.append(stamp)
        if let sourceNote {
            lines.append(sourceNote)
        }
        lines.append("")

        for kind in kinds {
            let report = Aggregator.report(records, kind: kind, now: now, settings: settings, timeZone: timeZone)
            lines.append(summaryLine(kind.title, report.totals))
        }

        let month = Aggregator.report(records, kind: .thisMonth, now: now, settings: settings, timeZone: timeZone)
        appendBreakdown(&lines, title: "This month by network", networks: month.networks)
        appendDays(&lines, title: "This month by day", days: month.days)

        if let first = records.map(\.date).min() {
            lines.append("")
            lines.append("First recorded day: \(first)")
        }
        return lines.joined(separator: "\n") + "\n"
    }

    public static func detail(
        _ kind: PeriodKind,
        records: [DailyRecord],
        network: String? = nil,
        now: Date = Date(),
        settings: MeterSettings = .default,
        timeZone: TimeZone = .current,
        sourceNote: String? = nil
    ) -> String {
        let report = Aggregator.report(
            records,
            kind: kind,
            network: network,
            now: now,
            settings: settings,
            timeZone: timeZone
        )
        var lines: [String] = []
        lines.append(kind.title)
        if let sourceNote { lines.append(sourceNote) }
        if let network { lines.append("Network: \(network)") }
        lines.append("")
        lines.append(Bytes.format(report.totals.totalBytes))
        lines.append("↓ " + Bytes.format(report.totals.downBytes) + "    ↑ " + Bytes.format(report.totals.upBytes))
        appendBreakdown(&lines, title: "Networks", networks: report.networks)
        appendDays(&lines, title: "Days", days: report.days)
        return lines.joined(separator: "\n") + "\n"
    }

    public static func json(
        records: [DailyRecord],
        kind: PeriodKind? = nil,
        network: String? = nil,
        now: Date = Date(),
        settings: MeterSettings = .default,
        timeZone: TimeZone = .current,
        sourceNote: String? = nil
    ) throws -> String {
        let kinds = kind.map { [$0] } ?? PeriodKind.allCases
        var periods: [String: Any] = [:]
        for item in kinds {
            let report = Aggregator.report(records, kind: item, network: network, now: now, settings: settings, timeZone: timeZone)
            periods[item.cliToken] = encode(report)
        }
        var payload: [String: Any] = [
            "generated": ISO8601DateFormatter().string(from: now),
            "periods": periods,
        ]
        if let sourceNote { payload["source"] = sourceNote }
        if let network { payload["network"] = network }
        let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
        return (String(data: data, encoding: .utf8) ?? "{}") + "\n"
    }

    public static let helpText = """
    bandwidth-meter — weekly / monthly usage from Bandwidth+ daily history

    Usage:
      bandwidth-meter                 Full summary
      bandwidth-meter today
      bandwidth-meter week
      bandwidth-meter last-week
      bandwidth-meter month
      bandwidth-meter last-month
      bandwidth-meter 30d
      bandwidth-meter year
      bandwidth-meter all
      bandwidth-meter json

    Options:
      --import FILE.csv     Merge a Bandwidth+ History.csv export
      --network NAME        Filter one Wi-Fi / interface name
      --json                Machine-readable output
      --help

    Bandwidth+ keeps running and records each day. Run this whenever you
    want to check week / month / all-time totals. It does not need to stay open.

    """

    private static func summaryLine(_ title: String, _ totals: Totals) -> String {
        pad(title, 16) + Bytes.format(totals.totalBytes)
            + "   ↓ " + Bytes.format(totals.downBytes)
            + "   ↑ " + Bytes.format(totals.upBytes)
    }

    private static func appendBreakdown(_ lines: inout [String], title: String, networks: [NetworkTotal]) {
        guard !networks.isEmpty else { return }
        lines.append("")
        lines.append(title)
        for row in networks {
            lines.append("  " + pad(row.network, 28) + Bytes.format(row.totals.totalBytes))
        }
    }

    private static func appendDays(_ lines: inout [String], title: String, days: [DayTotal]) {
        let recorded = days.filter { !$0.totals.isEmpty }
        guard !recorded.isEmpty else { return }
        lines.append("")
        lines.append(title)
        for day in recorded {
            lines.append("  " + pad(day.date, 14) + Bytes.format(day.totals.totalBytes))
        }
    }

    private static func encode(_ report: PeriodReport) -> [String: Any] {
        [
            "down_bytes": NSNumber(value: report.totals.downBytes),
            "up_bytes": NSNumber(value: report.totals.upBytes),
            "total_bytes": NSNumber(value: report.totals.totalBytes),
            "down": Bytes.format(report.totals.downBytes),
            "up": Bytes.format(report.totals.upBytes),
            "total": Bytes.format(report.totals.totalBytes),
            "networks": report.networks.map { row in
                [
                    "name": row.network,
                    "down_bytes": NSNumber(value: row.totals.downBytes),
                    "up_bytes": NSNumber(value: row.totals.upBytes),
                    "total_bytes": NSNumber(value: row.totals.totalBytes),
                    "total": Bytes.format(row.totals.totalBytes),
                ] as [String: Any]
            },
            "days": report.days.filter { !$0.totals.isEmpty }.map { day in
                [
                    "date": day.date,
                    "down_bytes": NSNumber(value: day.totals.downBytes),
                    "up_bytes": NSNumber(value: day.totals.upBytes),
                    "total_bytes": NSNumber(value: day.totals.totalBytes),
                    "total": Bytes.format(day.totals.totalBytes),
                ] as [String: Any]
            },
        ]
    }

    private static func pad(_ value: String, _ width: Int) -> String {
        if value.count >= width { return value + " " }
        return value + String(repeating: " ", count: width - value.count)
    }
}
