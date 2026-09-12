import Foundation

/// Errors thrown by weight validation.
public enum WeightError: Error, Equatable, Sendable {
    case negativeWeight(Double)
}

/// Type-safe representation of weight in grams with unit conversions and localization.
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable, Comparable, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    public let grams: Double

    public init(grams: Double) throws {
        guard grams >= 0 else {
            throw WeightError.negativeWeight(grams)
        }
        self.grams = grams
    }

    public init(kilograms: Double) throws {
        try self.init(grams: kilograms * 1000.0)
    }

    public init(floatLiteral value: Double) {
        self.grams = max(0.0, value)
    }

    public init(integerLiteral value: Int) {
        self.grams = max(0.0, Double(value))
    }

    public var kilograms: Double {
        grams / 1000.0
    }

    public var pounds: Double {
        grams / 453.59237
    }

    public var formatted: String {
        formatted(locale: .current)
    }

    public func formatted(locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        if grams >= 1000.0 {
            formatter.maximumFractionDigits = 2
            let numStr = formatter.string(from: NSNumber(value: kilograms)) ?? "\(kilograms)"
            return "\(numStr) kg"
        } else {
            formatter.maximumFractionDigits = 0
            let numStr = formatter.string(from: NSNumber(value: grams)) ?? "\(grams)"
            return "\(numStr) g"
        }
    }

    public static func + (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) -> __MODULE_NAME__ {
        __MODULE_NAME__(floatLiteral: lhs.grams + rhs.grams)
    }

    public static func < (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) -> Bool {
        lhs.grams < rhs.grams
    }
}
