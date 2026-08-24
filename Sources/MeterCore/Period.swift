import Foundation

public struct DateIntervalRange: Hashable, Sendable {
    public var start: Date
    public var end: Date

    public init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }

    public func contains(_ date: Date) -> Bool {
        date >= start && date < end
    }
}

public enum Period {
    public static func calendar(from settings: MeterSettings, timeZone: TimeZone = .current) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.firstWeekday = settings.weekStartsOnMonday ? 2 : 1
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }

    public static func range(
        _ kind: PeriodKind,
        now: Date = Date(),
        settings: MeterSettings = .default,
        timeZone: TimeZone = .current
    ) -> DateIntervalRange? {
        let calendar = calendar(from: settings, timeZone: timeZone)
        let startOfToday = calendar.startOfDay(for: now)

        switch kind {
        case .today:
            guard let end = calendar.date(byAdding: .day, value: 1, to: startOfToday) else { return nil }
            return DateIntervalRange(start: startOfToday, end: end)
        case .yesterday:
            guard let start = calendar.date(byAdding: .day, value: -1, to: startOfToday) else { return nil }
            return DateIntervalRange(start: start, end: startOfToday)
        case .thisWeek:
            return weekRange(containing: startOfToday, calendar: calendar)
        case .lastWeek:
            guard let previous = calendar.date(byAdding: .day, value: -7, to: startOfToday) else { return nil }
            return weekRange(containing: previous, calendar: calendar)
        case .thisMonth:
            return billingMonth(containing: startOfToday, billingDay: settings.billingDay, calendar: calendar)
        case .lastMonth:
            guard
                let thisMonth = billingMonth(containing: startOfToday, billingDay: settings.billingDay, calendar: calendar),
                let previousDay = calendar.date(byAdding: .day, value: -1, to: thisMonth.start)
            else { return nil }
            return billingMonth(containing: previousDay, billingDay: settings.billingDay, calendar: calendar)
        case .last30Days:
            guard let start = calendar.date(byAdding: .day, value: -29, to: startOfToday),
                  let end = calendar.date(byAdding: .day, value: 1, to: startOfToday)
            else { return nil }
            return DateIntervalRange(start: start, end: end)
        case .thisYear:
            guard let interval = calendar.dateInterval(of: .year, for: startOfToday) else { return nil }
            return DateIntervalRange(start: interval.start, end: interval.end)
        case .allTime:
            return nil
        }
    }

    public static func dates(
        in range: DateIntervalRange,
        calendar: Calendar
    ) -> [Date] {
        var dates: [Date] = []
        var cursor = calendar.startOfDay(for: range.start)
        while cursor < range.end {
            dates.append(cursor)
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return dates
    }

    public static func dayString(_ date: Date, calendar: Calendar? = nil) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar ?? Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar?.timeZone ?? .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func weekRange(containing date: Date, calendar: Calendar) -> DateIntervalRange? {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: date) else { return nil }
        return DateIntervalRange(start: interval.start, end: interval.end)
    }

    /// Billing month starting on `billingDay`. Day 1 is a normal calendar month.
    public static func billingMonth(containing date: Date, billingDay: Int, calendar: Calendar) -> DateIntervalRange? {
        let day = min(28, max(1, billingDay))
        if day == 1 {
            guard let interval = calendar.dateInterval(of: .month, for: date) else { return nil }
            return DateIntervalRange(start: interval.start, end: interval.end)
        }

        var components = calendar.dateComponents([.year, .month, .day], from: date)
        let currentDay = components.day ?? 1
        if currentDay >= day {
            components.day = day
            guard let start = calendar.date(from: components),
                  let end = calendar.date(byAdding: .month, value: 1, to: start)
            else { return nil }
            return DateIntervalRange(start: start, end: end)
        } else {
            components.day = day
            guard let thisMonthStart = calendar.date(from: components),
                  let start = calendar.date(byAdding: .month, value: -1, to: thisMonthStart)
            else { return nil }
            return DateIntervalRange(start: start, end: thisMonthStart)
        }
    }
}
