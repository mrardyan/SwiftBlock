import Foundation

/// Error thrown by non-negative numeric validation.
public enum NonNegativeError<T: Numeric & Comparable & Sendable>: Error, Equatable, Sendable {
    case valueIsNegative(T)
}

/// Type-safe generic wrapper guaranteeing a non-negative numeric value (>= 0).
public struct __MODULE_NAME__<Value: Numeric & Comparable & Hashable & Codable & Sendable>: Codable, Equatable, Hashable, Sendable, Comparable {
    public let value: Value

    public init(value: Value) throws {
        guard value >= 0 else {
            throw NonNegativeError.valueIsNegative(value)
        }
        self.value = value
    }

    public init(clamped value: Value) {
        self.value = max(0, value)
    }

    public static func < (lhs: __MODULE_NAME__<Value>, rhs: __MODULE_NAME__<Value>) -> Bool {
        lhs.value < rhs.value
    }
}

// Convenient typealiases for common numeric types
public typealias NonNegativeInt = __MODULE_NAME__<Int>
public typealias NonNegativeDouble = __MODULE_NAME__<Double>
public typealias NonNegativeDecimal = __MODULE_NAME__<Decimal>
