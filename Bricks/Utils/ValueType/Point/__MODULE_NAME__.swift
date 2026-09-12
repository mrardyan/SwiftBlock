import Foundation

/// Errors thrown by point operations.
public enum PointError: Error, Equatable, Sendable {
    case negativeBalance(Int)
}

/// Type-safe representation of loyalty or reward points.
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable, Comparable, ExpressibleByIntegerLiteral {
    public let rawValue: Int

    public init(value: Int) throws {
        guard value >= 0 else {
            throw PointError.negativeBalance(value)
        }
        self.rawValue = value
    }

    public init(integerLiteral value: Int) {
        self.rawValue = max(0, value)
    }

    public var formatted: String {
        formatted(locale: .current)
    }

    public func formatted(locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        let numStr = formatter.string(from: NSNumber(value: rawValue)) ?? "\(rawValue)"
        return "\(numStr) pts"
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
