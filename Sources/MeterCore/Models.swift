import Foundation

public struct DailyRecord: Codable, Hashable, Sendable, Identifiable {
    public var date: String
    public var network: String
    public var downBytes: UInt64
    public var upBytes: UInt64
    public var source: String

    public var id: String { "\(date)|\(network)" }
    public var totalBytes: UInt64 { downBytes &+ upBytes }

    public init(date: String, network: String, downBytes: UInt64, upBytes: UInt64, source: String = "manual") {
        self.date = date
        self.network = network
        self.downBytes = downBytes
        self.upBytes = upBytes
        self.source = source
    }

    public var day: Date? {
        Self.dayFormatter.date(from: date)
    }

    public static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

public struct Totals: Hashable, Sendable {
    public var downBytes: UInt64
    public var upBytes: UInt64

    public static let zero = Totals(downBytes: 0, upBytes: 0)

    public var totalBytes: UInt64 { downBytes &+ upBytes }
    public var isEmpty: Bool { totalBytes == 0 }

    public init(downBytes: UInt64 = 0, upBytes: UInt64 = 0) {
        self.downBytes = downBytes
        self.upBytes = upBytes
    }

    public mutating func add(_ other: Totals) {
        downBytes &+= other.downBytes
        upBytes &+= other.upBytes
    }

    public mutating func add(down: UInt64, up: UInt64) {
        downBytes &+= down
        upBytes &+= up
    }

    public func adding(_ other: Totals) -> Totals {
        var copy = self
        copy.add(other)
        return copy
    }

    public static func + (lhs: Totals, rhs: Totals) -> Totals {
        lhs.adding(rhs)
    }
}

public struct NetworkTotal: Identifiable, Hashable, Sendable {
    public var network: String
    public var totals: Totals
    public var id: String { network }
}

public struct DayTotal: Identifiable, Hashable, Sendable {
    public var date: String
    public var totals: Totals
    public var id: String { date }

    public var day: Date? { DailyRecord.dayFormatter.date(from: date) }
}

public enum PeriodKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case today
    case yesterday
    case thisWeek
    case lastWeek
    case thisMonth
    case lastMonth
    case last30Days
    case thisYear
    case allTime

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .today: "Today"
        case .yesterday: "Yesterday"
        case .thisWeek: "This week"
        case .lastWeek: "Last week"
        case .thisMonth: "This month"
        case .lastMonth: "Last month"
        case .last30Days: "Last 30 days"
        case .thisYear: "This year"
        case .allTime: "All time"
        }
    }

    public var shortTitle: String {
        switch self {
        case .today: "Today"
        case .yesterday: "Yday"
        case .thisWeek: "Week"
        case .lastWeek: "Last wk"
        case .thisMonth: "Month"
        case .lastMonth: "Last mo"
        case .last30Days: "30d"
        case .thisYear: "Year"
        case .allTime: "All"
        }
    }

    public var menuBarSymbol: String {
        switch self {
        case .today, .yesterday: "D"
        case .thisWeek, .lastWeek: "W"
        case .thisMonth, .lastMonth, .last30Days: "M"
        case .thisYear, .allTime: "Y"
        }
    }

    public var cliToken: String {
        switch self {
        case .today: "today"
        case .yesterday: "yesterday"
        case .thisWeek: "week"
        case .lastWeek: "last-week"
        case .thisMonth: "month"
        case .lastMonth: "last-month"
        case .last30Days: "30d"
        case .thisYear: "year"
        case .allTime: "all"
        }
    }

    public static func parseCLI(_ raw: String) -> PeriodKind? {
        switch raw.lowercased() {
        case "today", "d": .today
        case "yesterday", "yday": .yesterday
        case "week", "this-week", "thisweek", "w": .thisWeek
        case "last-week", "lastweek": .lastWeek
        case "month", "this-month", "thismonth", "m": .thisMonth
        case "last-month", "lastmonth": .lastMonth
        case "30d", "30-days", "last-30-days", "last30": .last30Days
        case "year", "this-year", "thisyear", "y": .thisYear
        case "all", "all-time", "alltime", "total": .allTime
        default: nil
        }
    }
}

public struct MeterSettings: Codable, Hashable, Sendable {
    public var weekStartsOnMonday: Bool
    public var billingDay: Int
    public var menuBarPeriod: PeriodKind
    public var monthlyQuotaGB: Double?
    public var launchAtLogin: Bool
    public var showSpeedInMenuBar: Bool

    public static let `default` = MeterSettings()

    public init(
        weekStartsOnMonday: Bool = true,
        billingDay: Int = 1,
        menuBarPeriod: PeriodKind = .thisMonth,
        monthlyQuotaGB: Double? = nil,
        launchAtLogin: Bool = false,
        showSpeedInMenuBar: Bool = false
    ) {
        self.weekStartsOnMonday = weekStartsOnMonday
        self.billingDay = min(28, max(1, billingDay))
        self.menuBarPeriod = menuBarPeriod
        self.monthlyQuotaGB = monthlyQuotaGB
        self.launchAtLogin = launchAtLogin
        self.showSpeedInMenuBar = showSpeedInMenuBar
    }
}

public struct PersistedStore: Codable, Sendable {
    public var version: Int
    public var records: [DailyRecord]
    public var settings: MeterSettings

    public init(version: Int = 1, records: [DailyRecord] = [], settings: MeterSettings = .default) {
        self.version = version
        self.records = records
        self.settings = settings
    }
}
