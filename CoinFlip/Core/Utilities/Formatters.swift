import Foundation

struct Formatters {
    static func currency(_ value: Double, decimals: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = decimals
        formatter.minimumFractionDigits = decimals
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    static func currencyCompact(_ value: Double) -> String {
        if value >= 1_000_000_000 {
            return String(format: "$%.1fB", value / 1_000_000_000)
        } else if value >= 1_000_000 {
            return String(format: "$%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "$%.1fK", value / 1_000)
        }
        return currency(value)
    }

    static func cryptoPrice(_ value: Double) -> String {
        if value < 0.00001 {
            return String(format: "$%.10f", value)
        } else if value < 0.01 {
            return String(format: "$%.6f", value)
        } else if value < 1 {
            return String(format: "$%.4f", value)
        }
        return currency(value)
    }

    static func quantity(_ value: Double) -> String {
        if value >= 1_000_000_000 {
            return String(format: "%.2fB", value / 1_000_000_000)
        } else if value >= 1_000_000 {
            return String(format: "%.2fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.2fK", value / 1_000)
        } else if value >= 1 {
            return String(format: "%.2f", value)
        }
        return String(format: "%.6f", value)
    }

    static func percentage(_ value: Double, includeSign: Bool = true) -> String {
        let sign = includeSign && value >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", value))%"
    }
}
