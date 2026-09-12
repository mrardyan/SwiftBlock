import Foundation

/// Errors thrown by credit balance operations.
public enum CreditError: Error, Equatable, Sendable {
    case insufficientCredit(requested: Decimal, available: Decimal)
    case negativeAmount(Decimal)
}

/// Type-safe representation of store or service credit.
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable, Comparable {
    public let amount: Decimal

    public init(amount: Decimal) throws {
        guard amount >= 0 else {
            throw CreditError.negativeAmount(amount)
        }
        self.amount = amount
    }

    public init(doubleValue: Double) throws {
        try self.init(amount: Decimal(doubleValue))
    }

    public var formatted: String {
        formatted(locale: .current)
    }

    public func formatted(locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.locale = locale
        let numberString = formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
        return "\(numberString) Credits"
    }

    public func deduct(_ deduction: Decimal) throws -> __MODULE_NAME__ {
        guard deduction <= amount else {
            throw CreditError.insufficientCredit(requested: deduction, available: amount)
        }
        return try __MODULE_NAME__(amount: amount - deduction)
    }

    public static func + (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) throws -> __MODULE_NAME__ {
        try __MODULE_NAME__(amount: lhs.amount + rhs.amount)
    }

    public static func < (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) -> Bool {
        lhs.amount < rhs.amount
    }
}
