import Foundation

public enum BandwidthPlus {
    public static let containerID = "au.id.haroldchu.mac.Bandwidth"

    public static var supportDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Containers/\(containerID)/Data/Library/Application Support/\(containerID)", isDirectory: true)
    }

    public static var historyURL: URL {
        supportDirectory.appendingPathComponent("History")
    }

    public static var dataURL: URL {
        supportDirectory.appendingPathComponent("Data")
    }

    public static var isInstalled: Bool {
        FileManager.default.fileExists(atPath: historyURL.path) || FileManager.default.fileExists(atPath: dataURL.path)
    }

    public static func loadRecords(now: Date = Date(), timeZone: TimeZone = .current) -> [DailyRecord] {
        var records: [DailyRecord] = []
        if let history = try? loadHistory(at: historyURL) {
            records.append(contentsOf: history)
        }
        if let today = try? loadToday(at: dataURL, now: now, timeZone: timeZone) {
            records.append(contentsOf: today)
        }
        return records.filter { $0.totalBytes > 0 }
    }

    public static func loadHistory(at url: URL) throws -> [DailyRecord] {
        let data = try Data(contentsOf: url)
        let decoded = try KeyedArchive.root(from: data)
        guard let root = decoded as? [String: Any] else {
            return []
        }
        let days = root["Days"] as? [String: Any] ?? [:]
        var records: [DailyRecord] = []
        for (date, rawDay) in days {
            guard let day = rawDay as? [String: Any] else { continue }
            records.append(contentsOf: networks(from: day["Networks"], date: date, source: "bandwidth-plus-history"))
        }
        return records
    }

    public static func loadToday(at url: URL, now: Date = Date(), timeZone: TimeZone = .current) throws -> [DailyRecord] {
        let data = try Data(contentsOf: url)
        guard let root = try KeyedArchive.root(from: data) as? [String: Any] else { return [] }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let date: String
        if let lastDate = root["LastDate"] as? Date {
            date = DailyRecord.dayFormatter.string(from: lastDate)
        } else {
            date = Period.dayString(now, calendar: calendar)
        }
        return networks(from: root["Networks"], date: date, source: "bandwidth-plus-today")
    }

    private static func networks(from raw: Any?, date: String, source: String) -> [DailyRecord] {
        guard let dict = raw as? [String: Any] else { return [] }
        var records: [DailyRecord] = []
        for (name, rawNetwork) in dict {
            let values = rawNetwork as? [String: Any] ?? [:]
            let down = uint64(values["In"])
            let up = uint64(values["Out"])
            if down == 0 && up == 0 { continue }
            records.append(
                DailyRecord(
                    date: date,
                    network: name,
                    downBytes: down,
                    upBytes: up,
                    source: source
                )
            )
        }
        return records
    }

    private static func uint64(_ value: Any?) -> UInt64 {
        switch value {
        case let n as UInt64: n
        case let n as Int: UInt64(max(0, n))
        case let n as Int64: n >= 0 ? UInt64(n) : 0
        case let n as NSNumber: n.uint64Value
        case let n as Double: n >= 0 ? UInt64(n) : 0
        default: 0
        }
    }
}
