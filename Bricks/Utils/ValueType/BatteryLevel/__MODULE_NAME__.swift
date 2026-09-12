import Foundation

/// Errors thrown by battery level validation.
public enum BatteryLevelError: Error, Equatable, Sendable {
    case invalidPercentage(Double)
}

/// Type-safe representation of battery level ratio (0.0 to 1.0 or 0% to 100%).
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable, Comparable, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
    public let level: Double

    public init(level: Double, clamped: Bool = true) throws {
        if clamped {
            self.level = max(0.0, min(1.0, level))
        } else {
            guard (0.0...1.0).contains(level) else {
                throw BatteryLevelError.invalidPercentage(level)
            }
            self.level = level
        }
    }

    public init(percent: Int) {
        self.level = max(0.0, min(1.0, Double(percent) / 100.0))
    }

    public init(floatLiteral value: Double) {
        self.level = max(0.0, min(1.0, value))
    }

    public init(integerLiteral value: Int) {
        self.level = max(0.0, min(1.0, Double(value) / 100.0))
    }

    public var percentage: Int {
        Int((level * 100.0).rounded())
    }

    public var isLowBattery: Bool {
        level <= 0.20
    }

    public var formatted: String {
        "\(percentage)%"
    }

    public static func < (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) -> Bool {
        lhs.level < rhs.level
    }
}
