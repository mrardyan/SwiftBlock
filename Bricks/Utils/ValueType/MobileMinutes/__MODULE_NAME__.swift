import Foundation

/// Errors thrown by mobile minutes operations.
public enum MobileMinutesError: Error, Equatable, Sendable {
    case negativeMinutes(Int)
}

/// Type-safe representation of mobile voice call quota in minutes.
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable, Comparable, ExpressibleByIntegerLiteral {
    public let minutes: Int

    public init(minutes: Int) throws {
        guard minutes >= 0 else {
            throw MobileMinutesError.negativeMinutes(minutes)
        }
        self.minutes = minutes
    }

    public init(integerLiteral value: Int) {
        self.minutes = max(0, value)
    }

    public var formatted: String {
        formatted(locale: .current)
    }

    public func formatted(locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        let numStr = formatter.string(from: NSNumber(value: minutes)) ?? "\(minutes)"
        return "\(numStr) Mins"
    }

    public static func + (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) -> __MODULE_NAME__ {
        __MODULE_NAME__(integerLiteral: lhs.minutes + rhs.minutes)
    }

    public static func < (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) -> Bool {
        lhs.minutes < rhs.minutes
    }
}

/// Convenient typealias for AirtimeMinutes
public typealias AirtimeMinutes = __MODULE_NAME__
