import Foundation

/// Errors thrown by speed validation.
public enum SpeedError: Error, Equatable, Sendable {
    case negativeSpeed(Double)
}

/// Type-safe representation of speed in kilometers per hour (km/h).
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable, Comparable, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    public let kilometersPerHour: Double

    public init(kilometersPerHour: Double) throws {
        guard kilometersPerHour >= 0 else {
            throw SpeedError.negativeSpeed(kilometersPerHour)
        }
        self.kilometersPerHour = kilometersPerHour
    }

    public init(floatLiteral value: Double) {
        self.kilometersPerHour = max(0.0, value)
    }

    public init(integerLiteral value: Int) {
        self.kilometersPerHour = max(0.0, Double(value))
    }

    public var milesPerHour: Double {
        kilometersPerHour / 1.609344
    }

    public var metersPerSecond: Double {
        kilometersPerHour / 3.6
    }

    public var formatted: String {
        formatted(locale: .current)
    }

    public func formatted(locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.locale = locale
        let speedStr = formatter.string(from: NSNumber(value: kilometersPerHour)) ?? "\(kilometersPerHour)"
        return "\(speedStr) km/h"
    }

    public static func < (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) -> Bool {
        lhs.kilometersPerHour < rhs.kilometersPerHour
    }
}
