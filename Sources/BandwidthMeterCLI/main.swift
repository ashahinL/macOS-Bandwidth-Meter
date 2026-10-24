import Foundation
import MeterCore

func main() -> Int32 {
    let args = Array(CommandLine.arguments.dropFirst())
    if args.contains("-h") || args.contains("--help") || args.contains("help") {
        fputs(Report.helpText, stdout)
        return 0
    }

    var csvURL: URL?
    var network: String?
    var asJSON = args.contains("--json") || (args.first == "json" && !args.contains("--json"))
    var positional: [String] = []

    var index = 0
    while index < args.count {
        let arg = args[index]
        if arg == "--json" {
            asJSON = true
        } else if arg == "--import" {
            guard index + 1 < args.count else {
                fputs("bandwidth-meter: --import needs a CSV path\n", stderr)
                return 2
            }
            csvURL = URL(fileURLWithPath: args[index + 1])
            index += 1
        } else if arg.hasPrefix("--import=") {
            csvURL = URL(fileURLWithPath: String(arg.dropFirst("--import=".count)))
        } else if arg == "--network" {
            guard index + 1 < args.count else {
                fputs("bandwidth-meter: --network needs a name\n", stderr)
                return 2
            }
            network = args[index + 1]
            index += 1
        } else if arg.hasPrefix("--network=") {
            network = String(arg.dropFirst("--network=".count))
        } else if arg.hasPrefix("-") {
            fputs("bandwidth-meter: unknown option \(arg)\n\n\(Report.helpText)", stderr)
            return 2
        } else if arg != "json" {
            positional.append(arg)
        }
        index += 1
    }

    if positional.count > 1 {
        fputs("bandwidth-meter: unexpected arguments: \(positional.joined(separator: " "))\n\n\(Report.helpText)", stderr)
        return 2
    }

    let period: PeriodKind?
    if let token = positional.first {
        guard let parsed = PeriodKind.parseCLI(token) else {
            fputs("bandwidth-meter: unknown period '\(token)'\n\n\(Report.helpText)", stderr)
            return 2
        }
        period = parsed
    } else {
        period = nil
    }

    if let csvURL, !FileManager.default.fileExists(atPath: csvURL.path) {
        fputs("bandwidth-meter: file not found: \(csvURL.path)\n", stderr)
        return 2
    }

    let loaded = UsageLoader.load(csvURL: csvURL)
    if loaded.records.isEmpty {
        fputs("bandwidth-meter: no usage yet. Keep Bandwidth+ running, then try again.\n", stderr)
        return 1
    }

    do {
        let text = try Report.render(
            records: loaded.records,
            period: period,
            network: network,
            asJSON: asJSON,
            settings: loaded.settings,
            sourceNote: loaded.sourceNote
        )
        fputs(text, stdout)
        return 0
    } catch {
        fputs("bandwidth-meter: \(error.localizedDescription)\n", stderr)
        return 1
    }
}

exit(main())
