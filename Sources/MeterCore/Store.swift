import Foundation

public enum StoreSaveError: Error, LocalizedError {
    case refusingToReplaceUnreadableFile(URL)

    public var errorDescription: String? {
        switch self {
        case .refusingToReplaceUnreadableFile(let url):
            "Refusing to replace \(url.path) because it could not be read and no backup was made."
        }
    }
}

public final class UsageStore: @unchecked Sendable {
    public private(set) var records: [DailyRecord]
    public var settings: MeterSettings
    public let fileURL: URL
    public private(set) var loadError: String?
    private var allowSave: Bool

    public init(fileURL: URL? = nil) {
        let url = fileURL ?? Self.defaultURL
        self.fileURL = url
        self.records = []
        self.settings = .default
        self.loadError = nil
        self.allowSave = true

        guard FileManager.default.fileExists(atPath: url.path) else { return }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(PersistedStore.self, from: data)
            self.records = decoded.records
            self.settings = decoded.settings
        } catch {
            let detail = Self.describe(error)
            if let backup = Self.preserveCorruptFile(at: url) {
                self.loadError = "Couldn't read \(url.path). \(detail) A copy is at \(backup.path). Billing day and quota were reset."
                self.allowSave = true
            } else {
                self.loadError = "Couldn't read \(url.path). \(detail) The file was left in place."
                self.allowSave = false
            }
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
        if !allowSave {
            throw StoreSaveError.refusingToReplaceUnreadableFile(fileURL)
        }
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

    private static func describe(_ error: Error) -> String {
        guard let decoding = error as? DecodingError else {
            return error.localizedDescription
        }
        switch decoding {
        case .dataCorrupted(let context):
            return context.debugDescription
        case .keyNotFound(let key, let context):
            return "Missing key \(key.stringValue). \(context.debugDescription)"
        case .typeMismatch(_, let context):
            return context.debugDescription
        case .valueNotFound(_, let context):
            return context.debugDescription
        @unknown default:
            return decoding.localizedDescription
        }
    }

    private static func preserveCorruptFile(at url: URL) -> URL? {
        let primary = URL(fileURLWithPath: url.path + ".bak")
        let destination: URL
        if FileManager.default.fileExists(atPath: primary.path) {
            let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
            destination = URL(fileURLWithPath: "\(url.path).\(stamp).bak")
        } else {
            destination = primary
        }
        do {
            try FileManager.default.copyItem(at: url, to: destination)
            return destination
        } catch {
            return nil
        }
    }
}
