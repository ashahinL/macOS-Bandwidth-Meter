import MeterCore
import SwiftUI

struct MenuBarLabel: View {
    @ObservedObject var meter: MeterController

    var body: some View {
        // MenuBarExtra only reliably draws a single Text. An HStack of "M" + amount
        // was clipping to the letter. Keep this one string and fixed-size.
        Text(caption)
            .font(.system(size: 13, weight: .semibold, design: .monospaced))
            .monospacedDigit()
            .fixedSize()
            .help(tooltip)
    }

    private var caption: String {
        if meter.settings.showSpeedInMenuBar {
            return "↓\(Bytes.compact(UInt64(max(0, meter.downBps)))) ↑\(Bytes.compact(UInt64(max(0, meter.upBps))))"
        }
        return Bytes.compact(meter.menuBarReport.totals.totalBytes)
    }

    private var tooltip: String {
        let totals = meter.menuBarReport.totals
        return "\(meter.settings.menuBarPeriod.title): \(Bytes.format(totals.totalBytes))  ↓ \(Bytes.format(totals.downBytes))  ↑ \(Bytes.format(totals.upBytes))"
    }
}
