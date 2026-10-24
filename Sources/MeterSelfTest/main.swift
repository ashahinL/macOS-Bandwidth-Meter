import Foundation
import MeterCore

enum Expect: Error {
    case failed(String)
}

func assertLiveRows(_ rows: [DailyRecord], _ label: String) throws {
    for record in rows {
        let dateOK = record.date.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil
        if !dateOK { throw Expect.failed("\(label) date \(record.date)") }
        if record.network.isEmpty { throw Expect.failed("\(label) blank network") }
        if record.totalBytes == 0 { throw Expect.failed("\(label) zero row \(record.date)") }
    }
}

func run() -> Int {
    func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        if !condition() { throw Expect.failed(message) }
    }

    func almostEqual(_ bytes: UInt64, _ expected: UInt64) -> Bool {
        let delta = bytes > expected ? bytes - expected : expected - bytes
        return delta < 2_000
    }

    let settings = MeterSettings(weekStartsOnMonday: true, billingDay: 1)
    let timeZone = TimeZone(secondsFromGMT: 3 * 3600)!
    let records = [
        DailyRecord(date: "2026-08-23", network: "stoneAndSteel_Up", downBytes: Bytes.fromMegabytes(1500.1), upBytes: Bytes.fromMegabytes(264.6)),
        DailyRecord(date: "2026-08-23", network: "stoneAndSteel_UpR5G", downBytes: Bytes.fromMegabytes(6490.6), upBytes: Bytes.fromMegabytes(428.1)),
        DailyRecord(date: "2026-08-24", network: "stoneAndSteel_UpR5G", downBytes: Bytes.fromMegabytes(2324.0), upBytes: Bytes.fromMegabytes(246.2)),
    ]

    func day(_ value: String) -> Date {
        let calendar = Period.calendar(from: settings, timeZone: timeZone)
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)!
    }

    let monday = day("2026-08-24")
    var failures: [String] = []

    func check(_ name: String, _ body: () throws -> Void) {
        do {
            try body()
            print("ok   \(name)")
        } catch Expect.failed(let message) {
            print("FAIL \(name): \(message)")
            failures.append(name)
        } catch {
            print("FAIL \(name): \(error)")
            failures.append(name)
        }
    }

    check("this month includes both days") {
        let report = Aggregator.report(records, kind: .thisMonth, now: monday, settings: settings, timeZone: timeZone)
        try expect(almostEqual(report.totals.totalBytes, Bytes.fromMegabytes(11_253.6)), "month total \(report.totals.totalBytes)")
        try expect(report.networks.count == 2, "network count \(report.networks.count)")
        try expect(report.days.filter { !$0.totals.isEmpty }.count == 2, "recorded days")
    }

    check("this week is Monday-only") {
        let report = Aggregator.report(records, kind: .thisWeek, now: monday, settings: settings, timeZone: timeZone)
        try expect(almostEqual(report.totals.totalBytes, Bytes.fromMegabytes(2_570.2)), "week total")
        try expect(report.days.count == 7, "week length \(report.days.count)")
        try expect(report.days.first?.date == "2026-08-24", "week start \(report.days.first?.date ?? "?")")
    }

    check("last week includes Saturday") {
        let report = Aggregator.report(records, kind: .lastWeek, now: monday, settings: settings, timeZone: timeZone)
        try expect(almostEqual(report.totals.totalBytes, Bytes.fromMegabytes(8_683.4)), "last week total")
        try expect(report.days.first?.date == "2026-08-17", "last week start")
        try expect(report.days.last?.date == "2026-08-23", "last week end")
    }

    check("today is Monday only") {
        let report = Aggregator.report(records, kind: .today, now: monday, settings: settings, timeZone: timeZone)
        try expect(almostEqual(report.totals.totalBytes, Bytes.fromMegabytes(2_570.2)), "today total")
        try expect(report.networks.map(\.network) == ["stoneAndSteel_UpR5G"], "today networks")
    }

    check("last month is empty") {
        let report = Aggregator.report(records, kind: .lastMonth, now: monday, settings: settings, timeZone: timeZone)
        try expect(report.totals.totalBytes == 0, "last month should be 0")
    }

    check("network filter") {
        let report = Aggregator.report(records, kind: .thisMonth, network: "stoneAndSteel_Up", now: monday, settings: settings, timeZone: timeZone)
        try expect(almostEqual(report.totals.totalBytes, Bytes.fromMegabytes(1_764.7)), "filtered total")
    }

    check("merge keeps higher counters") {
        let merged = Aggregator.merge(
            [DailyRecord(date: "2026-08-24", network: "Wi-Fi", downBytes: 100, upBytes: 10)],
            with: [DailyRecord(date: "2026-08-24", network: "Wi-Fi", downBytes: 250, upBytes: 5, source: "later")]
        )
        try expect(merged.count == 1, "merge count")
        try expect(merged[0].downBytes == 250, "down")
        try expect(merged[0].upBytes == 10, "up")
    }

    check("bandwidth-plus source wins over rounded CSV") {
        let merged = Aggregator.merge(
            [DailyRecord(date: "2026-08-23", network: "Home", downBytes: 1_500_100_000, upBytes: 264_600_000, source: "csv")],
            with: [DailyRecord(date: "2026-08-23", network: "Home", downBytes: 1_500_071_936, upBytes: 264_582_144, source: "bandwidth-plus-history")]
        )
        try expect(merged[0].downBytes == 1_500_071_936, "plus down")
        try expect(merged[0].upBytes == 264_582_144, "plus up")
        try expect(merged[0].source == "bandwidth-plus-history", "plus source")

        let reversed = Aggregator.merge(
            [DailyRecord(date: "2026-08-23", network: "Home", downBytes: 1_500_071_936, upBytes: 264_582_144, source: "bandwidth-plus-history")],
            with: [DailyRecord(date: "2026-08-23", network: "Home", downBytes: 1_500_100_000, upBytes: 264_600_000, source: "csv")]
        )
        try expect(reversed[0].downBytes == 1_500_071_936, "reversed down")
        try expect(reversed[0].upBytes == 264_582_144, "reversed up")
        try expect(reversed[0].source == "bandwidth-plus-history", "reversed source")
    }

    check("a later Bandwidth+ read does not shrink the day") {
        let merged = Aggregator.merge(
            [DailyRecord(date: "2026-08-23", network: "Home", downBytes: 5_000, upBytes: 1_000, source: "bandwidth-plus-history")],
            with: [DailyRecord(date: "2026-08-23", network: "Home", downBytes: 100, upBytes: 2_000, source: "bandwidth-plus-today")]
        )
        try expect(merged.count == 1, "count")
        try expect(merged[0].downBytes == 5_000, "down")
        try expect(merged[0].upBytes == 2_000, "up")
        try expect(merged[0].source == "bandwidth-plus-history", "source")
    }

    check("billing cycle from the 15th") {
        let billed = MeterSettings(weekStartsOnMonday: true, billingDay: 15)
        let range = Period.range(.thisMonth, now: monday, settings: billed, timeZone: timeZone)
        let calendar = Period.calendar(from: billed, timeZone: timeZone)
        try expect(Period.dayString(range!.start, calendar: calendar) == "2026-08-15", "cycle start")
        try expect(Period.dayString(range!.end, calendar: calendar) == "2026-09-15", "cycle end")
    }

    check("CSV parse of Bandwidth+ export") {
        let text = """
        Date,Network,Down (MB),Up (MB),Total (MB)
        2026-08-23,stoneAndSteel_Up,1500.1,264.6,1764.7
        2026-08-23,stoneAndSteel_UpR5G,6490.6,428.1,6918.7
        2026-08-24,stoneAndSteel_UpR5G,2324.0,246.2,2570.2
        """
        let parsed = try CSV.parse(text)
        try expect(parsed.count == 3, "row count")
        try expect(abs(Bytes.megabytes(Aggregator.totals(parsed).totalBytes) - 11_253.6) < 0.2, "csv total")
    }

    check("default summary respects the network filter") {
        let rows = [
            DailyRecord(date: "2026-08-24", network: "Home", downBytes: 2_000_000, upBytes: 0),
            DailyRecord(date: "2026-08-24", network: "Work", downBytes: 9_000_000, upBytes: 0),
        ]
        let filtered = try Report.render(
            records: rows,
            period: nil,
            network: "Home",
            now: monday,
            settings: settings,
            timeZone: timeZone
        )
        try expect(filtered.contains("Network: Home"), filtered)
        try expect(filtered.contains("2.0 MB"), filtered)
        try expect(!filtered.contains("Work"), filtered)
        try expect(!filtered.contains("9.0 MB"), filtered)

        let all = try Report.render(
            records: rows,
            period: nil,
            now: monday,
            settings: settings,
            timeZone: timeZone
        )
        try expect(all.contains("Work"), all)
        try expect(all.contains("9.0 MB"), all)
    }

    check("CLI period tokens") {
        try expect(PeriodKind.parseCLI("week") == .thisWeek, "week")
        try expect(PeriodKind.parseCLI("last-month") == .lastMonth, "last-month")
        try expect(PeriodKind.parseCLI("30d") == .last30Days, "30d")
        try expect(PeriodKind.parseCLI("nope") == nil, "unknown")
    }

    check("compact format") {
        try expect(Bytes.compact(11_253_600_000) == "11.3G", Bytes.compact(11_253_600_000))
        try expect(Bytes.format(2_570_200_000).contains("GB"), Bytes.format(2_570_200_000))
    }

    if BandwidthPlus.isInstalled {
        check("live Bandwidth+ files decode") {
            if FileManager.default.fileExists(atPath: BandwidthPlus.historyURL.path) {
                try assertLiveRows(BandwidthPlus.loadHistory(at: BandwidthPlus.historyURL), "history")
            }
            if FileManager.default.fileExists(atPath: BandwidthPlus.dataURL.path) {
                try assertLiveRows(BandwidthPlus.loadToday(at: BandwidthPlus.dataURL), "today")
            }
            let live = BandwidthPlus.loadRecords()
            try assertLiveRows(live, "combined")
            if !live.isEmpty {
                try expect(Aggregator.totals(live).totalBytes > 0, "combined total")
            }
        }
    } else {
        print("skip live Bandwidth+ history")
    }

    if failures.isEmpty {
        print("\nAll checks passed.")
        return 0
    } else {
        print("\n\(failures.count) check(s) failed.")
        return 1
    }
}

exit(Int32(run()))
