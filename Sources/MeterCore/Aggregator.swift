import Foundation

public struct PeriodReport: Sendable, Hashable {
    public var kind: PeriodKind
    public var totals: Totals
    public var networks: [NetworkTotal]
    public var days: [DayTotal]
    public var range: DateIntervalRange?
    public var firstRecordedDate: String?
    public var lastRecordedDate: String?

    public var networkFilter: String?
}

public enum Aggregator {
    public static func records(
        _ records: [DailyRecord],
        matching kind: PeriodKind,
        network: String? = nil,
        now: Date = Date(),
        settings: MeterSettings = .default,
        timeZone: TimeZone = .current
    ) -> [DailyRecord] {
        let calendar = Period.calendar(from: settings, timeZone: timeZone)
        let range = Period.range(kind, now: now, settings: settings, timeZone: timeZone)
        return records.filter { record in
            if let network, record.network != network { return false }
            guard let day = parseDay(record.date, calendar: calendar) else { return false }
            if let range {
                return range.contains(day)
            }
            return true
        }.sorted { lhs, rhs in
            if lhs.date == rhs.date { return lhs.network < rhs.network }
            return lhs.date < rhs.date
        }
    }

    public static func totals(_ records: [DailyRecord]) -> Totals {
        records.reduce(into: .zero) { result, record in
            result.add(down: record.downBytes, up: record.upBytes)
        }
    }

    public static func byNetwork(_ records: [DailyRecord]) -> [NetworkTotal] {
        var map: [String: Totals] = [:]
        for record in records {
            var value = map[record.network] ?? .zero
            value.add(down: record.downBytes, up: record.upBytes)
            map[record.network] = value
        }
        return map
            .map { NetworkTotal(network: $0.key, totals: $0.value) }
            .filter { !$0.totals.isEmpty }
            .sorted { $0.totals.totalBytes > $1.totals.totalBytes }
    }

    public static func byDay(_ records: [DailyRecord]) -> [DayTotal] {
        var map: [String: Totals] = [:]
        for record in records {
            var value = map[record.date] ?? .zero
            value.add(down: record.downBytes, up: record.upBytes)
            map[record.date] = value
        }
        return map
            .map { DayTotal(date: $0.key, totals: $0.value) }
            .sorted { $0.date < $1.date }
    }

    public static func filledDays(
        _ records: [DailyRecord],
        kind: PeriodKind,
        now: Date = Date(),
        settings: MeterSettings = .default,
        timeZone: TimeZone = .current
    ) -> [DayTotal] {
        let calendar = Period.calendar(from: settings, timeZone: timeZone)
        let existing = Dictionary(uniqueKeysWithValues: byDay(records).map { ($0.date, $0.totals) })
        guard let range = Period.range(kind, now: now, settings: settings, timeZone: timeZone) else {
            return byDay(records)
        }
        return Period.dates(in: range, calendar: calendar).map { date in
            let key = Period.dayString(date, calendar: calendar)
            return DayTotal(date: key, totals: existing[key] ?? .zero)
        }
    }

    public static func report(
        _ allRecords: [DailyRecord],
        kind: PeriodKind,
        network: String? = nil,
        now: Date = Date(),
        settings: MeterSettings = .default,
        timeZone: TimeZone = .current
    ) -> PeriodReport {
        let filtered = records(allRecords, matching: kind, network: network, now: now, settings: settings, timeZone: timeZone)
        let recorded = allRecords.compactMap(\.date).sorted()
        return PeriodReport(
            kind: kind,
            totals: totals(filtered),
            networks: byNetwork(filtered),
            days: filledDays(filtered, kind: kind, now: now, settings: settings, timeZone: timeZone),
            range: Period.range(kind, now: now, settings: settings, timeZone: timeZone),
            firstRecordedDate: recorded.first,
            lastRecordedDate: recorded.last,
            networkFilter: network
        )
    }

    public static func merge(_ existing: [DailyRecord], with incoming: [DailyRecord]) -> [DailyRecord] {
        var map: [String: DailyRecord] = [:]
        for record in existing {
            map[record.id] = record
        }
        for record in incoming {
            if let current = map[record.id] {
                map[record.id] = pick(current, record)
            } else {
                map[record.id] = record
            }
        }
        return map.values.sorted { lhs, rhs in
            if lhs.date == rhs.date { return lhs.network < rhs.network }
            return lhs.date < rhs.date
        }
    }

    public static func networks(in records: [DailyRecord]) -> [String] {
        Array(Set(records.filter { $0.totalBytes > 0 }.map(\.network))).sorted()
    }

    private static func pick(_ current: DailyRecord, _ incoming: DailyRecord) -> DailyRecord {
        let currentRank = sourceRank(current.source)
        let incomingRank = sourceRank(incoming.source)
        if incomingRank > currentRank {
            return incoming
        }
        if incomingRank < currentRank {
            return current
        }
        let currentTotal = current.downBytes &+ current.upBytes
        let incomingTotal = incoming.downBytes &+ incoming.upBytes
        return DailyRecord(
            date: incoming.date,
            network: incoming.network,
            downBytes: max(current.downBytes, incoming.downBytes),
            upBytes: max(current.upBytes, incoming.upBytes),
            source: incomingTotal > currentTotal ? incoming.source : current.source
        )
    }

    private static func sourceRank(_ source: String) -> Int {
        if source.hasPrefix("bandwidth-plus") { return 2 }
        if source == "sampler" { return 1 }
        return 0
    }

    private static func parseDay(_ value: String, calendar: Calendar) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
    }
}
