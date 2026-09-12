import Foundation

/// Errors thrown by mobile SMS operations.
public enum MobileSMSError: Error, Equatable, Sendable {
    case negativeCount(Int)
}

/// Type-safe representation of mobile SMS message quota.
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable, Comparable, ExpressibleByIntegerLiteral {
    public let count: Int

    public init(count: Int) throws {
        guard count >= 0 else {
            throw MobileSMSError.negativeCount(count)
        }
        self.count = count
    }

    public init(integerLiteral value: Int) {
        self.count = max(0, value)
    }

    public var formatted: String {
        formatted(locale: .current)
    }

    public func formatted(locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        let numStr = formatter.string(from: NSNumber(value: count)) ?? "\(count)"
        return "\(numStr) SMS"
    }

    public static func + (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) -> __MODULE_NAME__ {
        __MODULE_NAME__(integerLiteral: lhs.count + rhs.count)
    }

    public static func < (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) -> Bool {
        lhs.count < rhs.count
    }
}

/// Convenient typealias for SMSQuota
public typealias SMSQuota = __MODULE_NAME__
