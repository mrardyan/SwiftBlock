import Foundation

/// Errors thrown by mobile data operations.
public enum MobileDataError: Error, Equatable, Sendable {
    case negativeBytes(Int64)
}

/// Type-safe representation of mobile internet data in bytes.
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable, Comparable, ExpressibleByIntegerLiteral {
    public let bytes: Int64

    public init(bytes: Int64) throws {
        guard bytes >= 0 else {
            throw MobileDataError.negativeBytes(bytes)
        }
        self.bytes = bytes
    }

    public init(gigabytes: Double) {
        self.bytes = max(0, Int64(gigabytes * 1_073_741_824.0))
    }

    public init(megabytes: Double) {
        self.bytes = max(0, Int64(megabytes * 1_048_576.0))
    }

    public init(integerLiteral value: Int) {
        self.bytes = max(0, Int64(value))
    }

    public var megabytes: Double {
        Double(bytes) / 1_048_576.0
    }

    public var gigabytes: Double {
        Double(bytes) / 1_073_741_824.0
    }

    public var formatted: String {
        formatted(locale: .current)
    }

    public func formatted(locale: Locale = .current) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB, .useTB]
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }

    public static func + (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) -> __MODULE_NAME__ {
        __MODULE_NAME__(integerLiteral: Int(lhs.bytes + rhs.bytes))
    }

    public static func - (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) throws -> __MODULE_NAME__ {
        let result = lhs.bytes - rhs.bytes
        return try __MODULE_NAME__(bytes: result)
    }

    public static func < (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) -> Bool {
        lhs.bytes < rhs.bytes
    }
}

/// Convenient typealias for DataQuota
public typealias DataQuota = __MODULE_NAME__
