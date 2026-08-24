import Foundation

public final class UsageStore: @unchecked Sendable {
    public private(set) var records: [DailyRecord]
    public var settings: MeterSettings
    public let fileURL: URL

    public init(fileURL: URL? = nil) {
        let url = fileURL ?? Self.defaultURL
        self.fileURL = url
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(PersistedStore.self, from: data) {
            self.records = decoded.records
            self.settings = decoded.settings
        } else {
            self.records = []
            self.settings = .default
        }
    }

    public static var defaultDirectory: URL {
        let base = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/BandwidthMeter", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    public static var defaultURL: URL {
        defaultDirectory.appendingPathComponent("usage.json")
    }

    @discardableResult
    public func merge(_ incoming: [DailyRecord]) -> Bool {
        let merged = Aggregator.merge(records, with: incoming)
        let changed = merged != records
        records = merged
        return changed
    }

    public func addToToday(network: String, down: UInt64, up: UInt64, now: Date = Date()) {
        guard down > 0 || up > 0 else { return }
        let date = DailyRecord.dayFormatter.string(from: now)
        let incoming = DailyRecord(
            date: date,
            network: network,
            downBytes: down,
            upBytes: up,
            source: "sampler"
        )
        if let index = records.firstIndex(where: { $0.id == incoming.id }) {
            records[index].downBytes &+= down
            records[index].upBytes &+= up
            records[index].source = "sampler"
        } else {
            records.append(incoming)
        }
    }

    public func save() throws {
        let payload = PersistedStore(records: records, settings: settings)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(payload)
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: fileURL, options: [.atomic])
    }
}
