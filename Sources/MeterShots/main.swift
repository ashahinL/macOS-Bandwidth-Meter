// Renders the README screenshots from the real SwiftUI views with fixed demo
// data. Run it with `make shots`. Nothing here reads Bandwidth+ or the local
// usage store.
import AppKit
import MeterCore
import MeterUI
import SwiftUI

@MainActor
func snapshot<V: View>(_ view: V, dark: Bool, scale: CGFloat = 2) -> NSBitmapImageRep {
    let host = NSHostingView(rootView: view)
    host.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
    let size = host.fittingSize
    host.frame = CGRect(origin: .zero, size: size)

    let window = NSWindow(
        contentRect: host.frame,
        styleMask: [.borderless],
        backing: .buffered,
        defer: false
    )
    window.appearance = host.appearance
    window.isOpaque = false
    window.backgroundColor = .clear
    window.contentView = host
    window.setFrameOrigin(NSPoint(x: -30_000, y: -30_000))
    window.orderFrontRegardless()
    host.layoutSubtreeIfNeeded()
    // Let Charts and the switches finish their first layout pass.
    RunLoop.main.run(until: Date().addingTimeInterval(0.6))
    host.layoutSubtreeIfNeeded()

    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int((size.width * scale).rounded()),
        pixelsHigh: Int((size.height * scale).rounded()),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .calibratedRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = size
    host.cacheDisplay(in: host.bounds, to: rep)
    window.orderOut(nil)
    return rep.retagging(with: .sRGB) ?? rep
}

@MainActor
func write(_ rep: NSBitmapImageRep, _ name: String, to directory: URL) throws {
    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "MeterShots", code: 1, userInfo: [NSLocalizedDescriptionKey: "could not encode \(name)"])
    }
    let url = directory.appendingPathComponent(name)
    try data.write(to: url, options: .atomic)
    print("wrote \(url.path) (\(rep.pixelsWide)×\(rep.pixelsHigh))")
}

@MainActor
func meter(_ period: PeriodKind, network: String? = nil, speedInMenuBar: Bool = false) -> MeterController {
    var settings = Demo.settings
    settings.showSpeedInMenuBar = speedInMenuBar
    return MeterController(
        previewRecords: Demo.records,
        settings: settings,
        period: period,
        network: network,
        now: Demo.now,
        downBps: Demo.downBps,
        upBps: Demo.upBps
    )
}

@MainActor
func run() throws {
    let directory = URL(fileURLWithPath: ProcessInfo.processInfo.environment["SHOTS_DIR"] ?? "docs/screenshots")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

    try write(snapshot(HeroShot(meter: meter(.thisMonth)), dark: false), "hero.png", to: directory)

    let panels: [(String, PeriodKind, String?)] = [
        ("panel-month.png", .thisMonth, nil),
        ("panel-week.png", .thisWeek, nil),
        ("panel-last-month.png", .lastMonth, nil),
        ("panel-network.png", .thisMonth, "Office"),
    ]
    for (name, period, network) in panels {
        let view = PanelShot { DashboardView().environmentObject(meter(period, network: network)) }
        try write(snapshot(view, dark: true), name, to: directory)
    }

    let settings = PanelShot { SettingsView(onClose: {}).environmentObject(meter(.thisMonth)) }
    try write(snapshot(settings, dark: true), "settings.png", to: directory)

    try write(snapshot(MenuBarShot(meter: meter(.thisMonth), dark: false), dark: false), "menubar-light.png", to: directory)
    try write(snapshot(MenuBarShot(meter: meter(.thisMonth), dark: true), dark: true), "menubar-dark.png", to: directory)
    try write(
        snapshot(MenuBarShot(meter: meter(.thisMonth, speedInMenuBar: true), dark: true), dark: true),
        "menubar-speed.png",
        to: directory
    )

    // The exact call the CLI makes for a bare `bandwidth-meter`, pinned to the demo date.
    let summary = try Report.render(
        records: Demo.records,
        period: nil,
        now: Demo.now,
        settings: Demo.settings,
        sourceNote: Demo.sourceNote
    )
    try write(snapshot(TerminalShot(command: "bandwidth-meter", output: summary.trimmingCharacters(in: .newlines)), dark: true), "cli.png", to: directory)
    if ProcessInfo.processInfo.environment["SHOTS_PRINT_CLI"] != nil {
        print(summary, terminator: "")
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
MainActor.assumeIsolated {
    do {
        try run()
    } catch {
        FileHandle.standardError.write(Data("MeterShots: \(error.localizedDescription)\n".utf8))
        exit(1)
    }
}
