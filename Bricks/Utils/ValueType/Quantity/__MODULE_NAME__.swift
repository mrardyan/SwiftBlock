import Foundation

/// Error thrown by quantity operations.
public enum QuantityError: Error, Equatable, Sendable {
    case negativeQuantity(Int)
}

/// Type-safe representation of non-negative integer count/quantity.
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable, Comparable, ExpressibleByIntegerLiteral {
    public let rawValue: Int

    public init(value: Int) throws {
        guard value >= 0 else {
            throw QuantityError.negativeQuantity(value)
        }
        self.rawValue = value
    }

    public init(integerLiteral value: Int) {
        self.rawValue = max(0, value)
    }

    public static var zero: __MODULE_NAME__ {
        __MODULE_NAME__(integerLiteral: 0)
    }

    public var isZero: Bool {
        rawValue == 0
    }

    public var formatted: String {
        formatted(locale: .current)
    }

    public func formatted(locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        return formatter.string(from: NSNumber(value: rawValue)) ?? "\(rawValue)"
    }

    public static func + (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) -> __MODULE_NAME__ {
        __MODULE_NAME__(integerLiteral: lhs.rawValue + rhs.rawValue)
    }

    public static func - (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) throws -> __MODULE_NAME__ {
        let result = lhs.rawValue - rhs.rawValue
        return try __MODULE_NAME__(value: result)
    }

    public static func < (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
