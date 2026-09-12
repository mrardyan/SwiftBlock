import Foundation

/// Errors thrown by calorie validation.
public enum CalorieError: Error, Equatable, Sendable {
    case negativeCalorie(Double)
}

/// Type-safe representation of energy/calories in kilocalories (kCal).
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable, Comparable, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    public let kilocalories: Double

    public init(kilocalories: Double) throws {
        guard kilocalories >= 0 else {
            throw CalorieError.negativeCalorie(kilocalories)
        }
        self.kilocalories = kilocalories
    }

    public init(kilojoules: Double) throws {
        try self.init(kilocalories: kilojoules / 4.184)
    }

    public init(floatLiteral value: Double) {
        self.kilocalories = max(0.0, value)
    }

    public init(integerLiteral value: Int) {
        self.kilocalories = max(0.0, Double(value))
    }

    public var kilojoules: Double {
        kilocalories * 4.184
    }

    public var formatted: String {
        formatted(locale: .current)
    }

    public func formatted(locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.locale = locale
        let kcalStr = formatter.string(from: NSNumber(value: kilocalories)) ?? "\(kilocalories)"
        return "\(kcalStr) kcal"
    }

    public static func + (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) -> __MODULE_NAME__ {
        __MODULE_NAME__(floatLiteral: lhs.kilocalories + rhs.kilocalories)
    }

    public static func < (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) -> Bool {
        lhs.kilocalories < rhs.kilocalories
    }
}
