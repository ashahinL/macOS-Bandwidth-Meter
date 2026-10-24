import AppKit
import Darwin
import MeterCore
import SwiftUI

@main
struct BandwidthMeterApp: App {
    @StateObject private var meter = MeterController()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        Self.runCLIIfNeeded()
    }

    var body: some Scene {
        MenuBarExtra {
            DashboardView()
                .environmentObject(meter)
        } label: {
            MenuBarLabel(meter: meter)
        }
        .menuBarExtraStyle(.window)
    }

    private static func runCLIIfNeeded() {
        let args = CommandLine.arguments
        guard args.contains("--report") || args.contains("report") else { return }
        do {
            let loaded = try UsageLoader.load()
            for problem in loaded.problems {
                fputs("bandwidth-meter: \(problem)\n", stderr)
            }
            print(Report.text(records: loaded.records, settings: loaded.settings, sourceNote: loaded.sourceNote), terminator: "")
            exit(loaded.problems.isEmpty ? 0 : 1)
        } catch {
            fputs("bandwidth-meter: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
