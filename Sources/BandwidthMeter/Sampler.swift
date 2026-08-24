import Foundation
import InterfaceCounters

struct BytePair {
    var down: UInt64
    var up: UInt64
}

struct InterfaceSnapshot {
    var bytesIn: UInt64
    var bytesOut: UInt64
    var at: Date
    var byName: [String: BytePair]
}

enum Sampler {
    private static let ignoredPrefixes = [
        "lo", "utun", "awdl", "llw", "gif", "stf", "anpi", "ap",
        "dummy", "bridge", "vmenet", "ipsec", "vlan", "tap", "tun",
        "pdp_ip", "llw",
    ]

    static func snapshot() -> InterfaceSnapshot {
        var buffer = [IFCounter](repeating: IFCounter(), count: 64)
        let count = buffer.withUnsafeMutableBufferPointer { ptr in
            copy_interface_counters(ptr.baseAddress, Int32(ptr.count))
        }
        var byName: [String: BytePair] = [:]
        var down: UInt64 = 0
        var up: UInt64 = 0
        if count > 0 {
            for index in 0..<Int(count) {
                let row = buffer[index]
                let name = withUnsafePointer(to: row.name) {
                    $0.withMemoryRebound(to: CChar.self, capacity: 32) { String(cString: $0) }
                }
                guard shouldTrack(name) else { continue }
                byName[name] = BytePair(down: row.bytes_in, up: row.bytes_out)
                down &+= row.bytes_in
                up &+= row.bytes_out
            }
        }
        return InterfaceSnapshot(bytesIn: down, bytesOut: up, at: Date(), byName: byName)
    }

    static func deltas(from old: InterfaceSnapshot, to new: InterfaceSnapshot) -> (down: UInt64, up: UInt64, byName: [String: BytePair]) {
        var down: UInt64 = 0
        var up: UInt64 = 0
        var byName: [String: BytePair] = [:]
        for (name, current) in new.byName {
            let previous = old.byName[name] ?? BytePair(down: 0, up: 0)
            let d = current.down >= previous.down ? current.down - previous.down : 0
            let u = current.up >= previous.up ? current.up - previous.up : 0
            if d == 0 && u == 0 { continue }
            byName[name] = BytePair(down: d, up: u)
            down &+= d
            up &+= u
        }
        return (down, up, byName)
    }

    private static func shouldTrack(_ name: String) -> Bool {
        if name.isEmpty { return false }
        for prefix in ignoredPrefixes {
            if name == prefix || name.hasPrefix(prefix) { return false }
        }
        return true
    }
}
