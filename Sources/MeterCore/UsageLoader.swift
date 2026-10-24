import Foundation

public struct LoadedUsage: Sendable {
    public var records: [DailyRecord]
    public var settings: MeterSettings
    public var sourceNote: String
    public var problems: [String]
}

public enum UsageLoader {
    public static func load(csvURL: URL? = nil, persist: Bool = true, store: UsageStore? = nil) throws -> LoadedUsage {
        let active = store ?? UsageStore()
        var problems: [String] = []
        if let loadError = active.loadError {
            problems.append(loadError)
        }
        let plus = BandwidthPlus.loadRecords()
        var incoming = plus.records
        problems.append(contentsOf: plus.problems)
        if let csvURL {
            let csv = try CSV.parseFile(at: csvURL, source: "csv")
            incoming.append(contentsOf: csv)
        } else if incoming.isEmpty {
            let desktop = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop/History.csv")
            if FileManager.default.fileExists(atPath: desktop.path),
               let csv = try? CSV.parseFile(at: desktop, source: "desktop-csv") {
                incoming.append(contentsOf: csv)
            }
        }
        _ = active.merge(incoming)
        if persist {
            try active.save()
        }
        let note: String
        if !plus.problems.isEmpty {
            note = "Source: " + plus.problems.joined(separator: " ")
        } else if plus.filesFound {
            note = "Source: Bandwidth+ live history"
        } else if incoming.contains(where: { $0.source.contains("csv") }) {
            note = "Source: CSV import"
        } else {
            note = "Source: local store"
        }
        return LoadedUsage(records: active.records, settings: active.settings, sourceNote: note, problems: problems)
    }
}

public enum MeterStatus {
    public static func line(
        bandwidthProblems: [String],
        storeProblem: String?,
        readingBandwidthPlus: Bool,
        trackingThisMac: Bool,
        hasRecords: Bool
    ) -> String {
        var issues = bandwidthProblems
        if let storeProblem {
            issues.append(storeProblem)
        }
        if !issues.isEmpty {
            return issues.joined(separator: "\n")
        }
        if readingBandwidthPlus {
            return "Live from Bandwidth+"
        }
        if trackingThisMac {
            return "Tracking this Mac"
        }
        if !hasRecords {
            return "Import a Bandwidth+ History.csv to get started"
        }
        return "Local history"
    }
}
