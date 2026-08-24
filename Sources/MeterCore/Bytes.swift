import Foundation

public enum Bytes {
    /// Bandwidth+ exports decimal megabytes (1 MB = 1_000_000 bytes).
    public static let megabyte: Double = 1_000_000
    public static let gigabyte: Double = 1_000_000_000

    public static func fromMegabytes(_ mb: Double) -> UInt64 {
        if mb <= 0 { return 0 }
        return UInt64((mb * megabyte).rounded())
    }

    public static func megabytes(_ bytes: UInt64) -> Double {
        Double(bytes) / megabyte
    }

    public static func gigabytes(_ bytes: UInt64) -> Double {
        Double(bytes) / gigabyte
    }

    public static func format(_ bytes: UInt64, decimals: Int? = nil) -> String {
        let value = Double(bytes)
        let (amount, suffix, defaultDecimals): (Double, String, Int) = {
            if value >= 1_000_000_000_000 { return (value / 1_000_000_000_000, " TB", 2) }
            if value >= gigabyte { return (value / gigabyte, " GB", 2) }
            if value >= megabyte { return (value / megabyte, " MB", 1) }
            if value >= 1_000 { return (value / 1_000, " KB", 0) }
            return (value, " B", 0)
        }()
        let places = decimals ?? defaultDecimals
        return String(format: "%.\(places)f%@", amount, suffix)
    }

    public static func compact(_ bytes: UInt64) -> String {
        let value = Double(bytes)
        if value >= 1_000_000_000_000 { return String(format: "%.1fT", value / 1_000_000_000_000) }
        if value >= gigabyte { return String(format: "%.1fG", value / gigabyte) }
        if value >= megabyte { return String(format: "%.0fM", value / megabyte) }
        if value >= 1_000 { return String(format: "%.0fK", value / 1_000) }
        return "\(bytes)B"
    }
}
