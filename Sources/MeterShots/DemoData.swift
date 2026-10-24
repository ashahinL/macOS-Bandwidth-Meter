import Foundation
import MeterCore

/// A made-up but believable history: about three months on a few generic
/// networks. Every number comes from a seeded generator, so each run of
/// `make shots` produces the same pictures. No real usage is read.
enum Demo {
    /// Friday 9 October 2026, 18:24 local time. "Today" in every shot.
    static let now: Date = {
        let calendar = Calendar(identifier: .gregorian)
        return calendar.date(from: DateComponents(year: 2026, month: 10, day: 9, hour: 18, minute: 24))!
    }()

    static let settings = MeterSettings(
        weekStartsOnMonday: true,
        billingDay: 1,
        menuBarPeriod: .thisMonth,
        monthlyQuotaGB: 300,
        launchAtLogin: true,
        showSpeedInMenuBar: false
    )

    static let downBps: Double = 2_400_000
    static let upBps: Double = 310_000

    static let sourceNote = "Source: Bandwidth+ live history"

    static let records: [DailyRecord] = {
        var random = SplitMix64(seed: 0xB4D7_2026)
        let calendar = Calendar(identifier: .gregorian)
        var day = calendar.date(from: DateComponents(year: 2026, month: 7, day: 1, hour: 12))!
        let lastDay = calendar.startOfDay(for: now)
        var rows: [DailyRecord] = []

        while calendar.startOfDay(for: day) <= lastDay {
            let weekday = calendar.component(.weekday, from: day)
            let weekend = weekday == 1 || weekday == 7
            let isToday = calendar.isDate(day, inSameDayAs: now)
            // Today is still open in Bandwidth+, so it holds part of a day.
            let share = isToday ? 0.62 : 1.0
            let date = DailyRecord.dayFormatter.string(from: day)

            func add(_ network: String, _ gigabytes: ClosedRange<Double>) {
                let down = UInt64(random.next(in: gigabytes) * share * 1_000_000_000)
                let up = UInt64(Double(down) * random.next(in: 0.06...0.14))
                rows.append(DailyRecord(
                    date: date,
                    network: network,
                    downBytes: down,
                    upBytes: up,
                    source: isToday ? "bandwidth-plus-today" : "bandwidth-plus-history"
                ))
            }

            if weekend {
                add("Home-5G", 5.5...11.0)
            } else {
                add("Home-5G", 2.2...5.8)
                if random.next(in: 0...1) < 0.9 {
                    add("Office", 1.1...3.2)
                }
            }
            if random.next(in: 0...1) < 0.45 {
                add("Home-2.4G", 0.08...0.6)
            }
            if random.next(in: 0...1) < 0.18 {
                add("iPhone", 0.2...1.4)
            }
            day = calendar.date(byAdding: .day, value: 1, to: day)!
        }
        // Go through the same merge the app uses on Bandwidth+ rows.
        return Aggregator.merge([], with: rows)
    }()
}

struct SplitMix64 {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func nextBits() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    mutating func next(in range: ClosedRange<Double>) -> Double {
        let unit = Double(nextBits() >> 11) / Double(1 << 53)
        return range.lowerBound + unit * (range.upperBound - range.lowerBound)
    }
}
