import Foundation

/// Errors thrown by distance measurement validation.
public enum DistanceError: Error, Equatable, Sendable {
    case negativeDistance(Double)
}

/// Type-safe representation of distance in meters with unit conversions.
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable, Comparable, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    public let meters: Double

    public init(meters: Double) throws {
        guard meters >= 0 else {
            throw DistanceError.negativeDistance(meters)
        }
        self.meters = meters
    }

    public init(floatLiteral value: Double) {
        self.meters = max(0.0, value)
    }

    public init(integerLiteral value: Int) {
        self.meters = max(0.0, Double(value))
    }

    public var kilometers: Double {
        meters / 1000.0
    }

    public var miles: Double {
        meters / 1609.344
    }

    public var formatted: String {
        formatted(locale: .current)
    }

    public func formatted(locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        if meters >= 1000.0 {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            let numStr = formatter.string(from: NSNumber(value: kilometers)) ?? "\(kilometers)"
            return "\(numStr) km"
        } else {
            formatter.maximumFractionDigits = 0
            let numStr = formatter.string(from: NSNumber(value: meters)) ?? "\(meters)"
            return "\(numStr) m"
        }
    }

    public static func + (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) -> __MODULE_NAME__ {
        __MODULE_NAME__(floatLiteral: lhs.meters + rhs.meters)
    }

    public static func < (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) -> Bool {
        lhs.meters < rhs.meters
    }
}
