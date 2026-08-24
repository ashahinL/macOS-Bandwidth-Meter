import Foundation

public enum CSVError: Error, LocalizedError {
    case empty
    case missingHeader
    case unreadable

    public var errorDescription: String? {
        switch self {
        case .empty: "The CSV file is empty."
        case .missingHeader: "Expected a header row with Date, Network, Down (MB), Up (MB)."
        case .unreadable: "Could not read the CSV file."
        }
    }
}

public enum CSV {
    public static func parse(_ text: String, source: String = "csv") throws -> [DailyRecord] {
        var content = text
        if content.hasPrefix("\u{feff}") {
            content.removeFirst()
        }
        let lines = content
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard let headerLine = lines.first else { throw CSVError.empty }

        let header = splitCSV(String(headerLine)).map { $0.lowercased() }
        func index(_ names: [String]) -> Int? {
            header.firstIndex { names.contains($0) }
        }

        guard
            let dateIndex = index(["date"]),
            let networkIndex = index(["network"]),
            let downIndex = index(["down (mb)", "down", "download (mb)", "download"]),
            let upIndex = index(["up (mb)", "up", "upload (mb)", "upload"])
        else {
            throw CSVError.missingHeader
        }

        var records: [DailyRecord] = []
        for line in lines.dropFirst() {
            let cols = splitCSV(String(line))
            guard cols.count > max(dateIndex, networkIndex, downIndex, upIndex) else { continue }
            let date = cols[dateIndex].trimmingCharacters(in: .whitespaces)
            let network = cols[networkIndex].trimmingCharacters(in: .whitespaces)
            guard !date.isEmpty, !network.isEmpty else { continue }
            let down = Double(cols[downIndex].replacingOccurrences(of: ",", with: "")) ?? 0
            let up = Double(cols[upIndex].replacingOccurrences(of: ",", with: "")) ?? 0
            records.append(
                DailyRecord(
                    date: date,
                    network: network,
                    downBytes: Bytes.fromMegabytes(down),
                    upBytes: Bytes.fromMegabytes(up),
                    source: source
                )
            )
        }
        return records
    }

    public static func parseFile(at url: URL, source: String = "csv") throws -> [DailyRecord] {
        let text = try String(contentsOf: url, encoding: .utf8)
        return try parse(text, source: source)
    }

    public static func exportDaily(_ records: [DailyRecord]) -> String {
        var lines = ["Date,Network,Down (MB),Up (MB),Total (MB)"]
        for record in records.sorted(by: { $0.date == $1.date ? $0.network < $1.network : $0.date < $1.date }) {
            let down = Bytes.megabytes(record.downBytes)
            let up = Bytes.megabytes(record.upBytes)
            let total = Bytes.megabytes(record.totalBytes)
            lines.append(String(format: "%@,%@,%.1f,%.1f,%.1f", record.date, csvEscape(record.network), down, up, total))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    public static func exportPeriod(_ days: [DayTotal], label: String = "Period") -> String {
        var lines = ["Date,Down (MB),Up (MB),Total (MB)"]
        for day in days {
            lines.append(
                String(
                    format: "%@,%.1f,%.1f,%.1f",
                    day.date,
                    Bytes.megabytes(day.totals.downBytes),
                    Bytes.megabytes(day.totals.upBytes),
                    Bytes.megabytes(day.totals.totalBytes)
                )
            )
        }
        return lines.joined(separator: "\n") + "\n"
    }

    private static func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }

    private static func splitCSV(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        for char in line {
            if char == "\"" {
                inQuotes.toggle()
                continue
            }
            if char == "," && !inQuotes {
                result.append(current)
                current = ""
                continue
            }
            current.append(char)
        }
        result.append(current)
        return result
    }
}
