import AppKit
import Combine
import Foundation
import MeterCore
import ServiceManagement

@MainActor
final class MeterController: ObservableObject {
    @Published var records: [DailyRecord] = []
    @Published var settings: MeterSettings = .default
    @Published var selectedPeriod: PeriodKind = .thisMonth
    @Published var selectedNetwork: String?
    @Published var usingBandwidthPlus = false
    @Published var lastSync: Date?
    @Published var downBps: Double = 0
    @Published var upBps: Double = 0
    @Published var status: String = "Starting…"

    private let store: UsageStore
    private var timer: Timer?
    private var previousSnapshot: InterfaceSnapshot?
    private var usingLiveTracker = false
    private var bandwidthProblems: [String] = []

    init(store: UsageStore = UsageStore()) {
        self.store = store
        self.records = store.records
        self.settings = store.settings
        self.selectedPeriod = store.settings.menuBarPeriod
        bootstrap()
        startTimer()
    }

    var report: PeriodReport {
        Aggregator.report(
            records,
            kind: selectedPeriod,
            network: selectedNetwork,
            settings: settings
        )
    }

    var menuBarReport: PeriodReport {
        Aggregator.report(records, kind: settings.menuBarPeriod, network: selectedNetwork, settings: settings)
    }

    var availableNetworks: [String] {
        Aggregator.networks(in: records)
    }

    var trackingSince: String? {
        records.map(\.date).min()
    }

    var statusIsProblem: Bool {
        !bandwidthProblems.isEmpty || store.loadError != nil
    }

    func bootstrap() {
        let plus = BandwidthPlus.loadRecords()
        bandwidthProblems = plus.problems
        var incoming = plus.records
        usingBandwidthPlus = plus.problems.isEmpty && plus.filesFound
        usingLiveTracker = plus.problems.isEmpty && !plus.filesFound

        if plus.records.isEmpty {
            let desktopCSV = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Desktop/History.csv")
            if FileManager.default.fileExists(atPath: desktopCSV.path),
               let csv = try? CSV.parseFile(at: desktopCSV, source: "desktop-csv") {
                incoming.append(contentsOf: csv)
            }
        }

        if store.merge(incoming) {
            try? store.save()
        }
        records = store.records
        lastSync = Date()
        refreshStatus()
    }

    func refreshFromBandwidthPlus() {
        let plus = BandwidthPlus.loadRecords()
        bandwidthProblems = plus.problems
        if !plus.records.isEmpty {
            if store.merge(plus.records) {
                try? store.save()
            }
            records = store.records
            lastSync = Date()
        }
        if plus.problems.isEmpty && plus.filesFound {
            usingBandwidthPlus = true
            usingLiveTracker = false
        } else if !plus.problems.isEmpty {
            usingBandwidthPlus = false
            usingLiveTracker = false
        }
        refreshStatus()
    }

    func importCSV(at url: URL) throws {
        let parsed = try CSV.parseFile(at: url, source: "csv")
        _ = store.merge(parsed)
        try store.save()
        records = store.records
        lastSync = Date()
        refreshStatus()
    }

    func updateSettings(_ mutate: (inout MeterSettings) -> Void) {
        mutate(&store.settings)
        settings = store.settings
        try? store.save()
        if store.settings.launchAtLogin {
            try? SMAppService.mainApp.register()
        } else {
            try? SMAppService.mainApp.unregister()
        }
    }

    func exportCSV() -> String {
        CSV.exportDaily(records)
    }

    func exportSelectedPeriodCSV() -> String {
        CSV.exportPeriod(report.days.filter { !$0.totals.isEmpty })
    }

    func quit() {
        try? store.save()
        NSApplication.shared.terminate(nil)
    }

    private func startTimer() {
        previousSnapshot = Sampler.snapshot()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func tick() {
        let snapshot = Sampler.snapshot()
        if let previous = previousSnapshot {
            let delta = Sampler.deltas(from: previous, to: snapshot)
            let dt = max(snapshot.at.timeIntervalSince(previous.at), 0.001)
            downBps = Double(delta.down) / dt
            upBps = Double(delta.up) / dt
            if usingLiveTracker {
                for (name, amounts) in delta.byName {
                    store.addToToday(network: displayName(name), down: amounts.down, up: amounts.up)
                }
                records = store.records
            }
        }
        previousSnapshot = snapshot

        let second = Calendar.current.component(.second, from: Date())
        if second % 2 == 0 {
            refreshFromBandwidthPlus()
        }
        if second == 5 {
            try? store.save()
        }
    }

    private func displayName(_ interface: String) -> String {
        if interface.hasPrefix("en") { return "Network (\(interface))" }
        return interface
    }

    private func refreshStatus() {
        status = MeterStatus.line(
            bandwidthProblems: bandwidthProblems,
            storeProblem: store.loadError,
            readingBandwidthPlus: usingBandwidthPlus,
            trackingThisMac: usingLiveTracker,
            hasRecords: !records.isEmpty
        )
    }
}
