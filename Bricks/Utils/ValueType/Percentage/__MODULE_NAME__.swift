import Foundation

/// Type-safe representation of percentage values (0.0 to 1.0 or 0% to 100%).
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable, Comparable, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    /// Decimal ratio representation between 0.0 and 1.0.
    public let ratio: Double

    /// Percentage value between 0.0 and 100.0.
    public var value: Double {
        ratio * 100.0
    }

    /// Initializes percentage with a ratio (0.0 to 1.0) and optional clamping.
    public init(ratio: Double, clamped: Bool = true) {
        if clamped {
            self.ratio = max(0.0, min(1.0, ratio))
        } else {
            self.ratio = ratio
        }
    }

    /// Initializes percentage from percent value (e.g. 15 for 15%).
    public init(percent: Double, clamped: Bool = true) {
        self.init(ratio: percent / 100.0, clamped: clamped)
    }

    public init(floatLiteral value: Double) {
        self.init(ratio: value)
    }

    public init(integerLiteral value: Int) {
        self.init(percent: Double(value))
    }

    /// Formatted localized percentage string (e.g., "15%").
    public var formatted: String {
        formatted(locale: .current)
    }

    /// Localized percentage string with custom locale.
    public func formatted(locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 2
        formatter.locale = locale
        return formatter.string(from: NSNumber(value: ratio)) ?? "\(Int(value))%"
    }

    /// Calculates percentage of a numeric value.
    public func of(_ amount: Double) -> Double {
        amount * ratio
    }

    public static func < (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) -> Bool {
        lhs.ratio < rhs.ratio
    }
}
