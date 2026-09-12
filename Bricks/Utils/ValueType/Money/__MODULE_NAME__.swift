import Foundation

/// Errors thrown by monetary operations.
public enum MoneyError: Error, Equatable, Sendable {
    case invalidAmount
    case currencyMismatch(lhs: String, rhs: String)
}

/// Type-safe monetary value representation combining Decimal amount and Currency code.
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable, Comparable {
    public let amount: Decimal
    public let currency: String

    public init(amount: Decimal, currency: String = "USD") {
        self.amount = amount
        self.currency = currency.uppercased()
    }

    public init(doubleValue: Double, currency: String = "USD") {
        self.amount = Decimal(doubleValue)
        self.currency = currency.uppercased()
    }

    public init(intValue: Int, currency: String = "USD") {
        self.amount = Decimal(intValue)
        self.currency = currency.uppercased()
    }

    public var formatted: String {
        formatted(locale: .current)
    }

    public func formatted(locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = locale
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currency) \(amount)"
    }

    public static func + (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) throws -> __MODULE_NAME__ {
        guard lhs.currency == rhs.currency else {
            throw MoneyError.currencyMismatch(lhs: lhs.currency, rhs: rhs.currency)
        }
        return __MODULE_NAME__(amount: lhs.amount + rhs.amount, currency: lhs.currency)
    }

    public static func - (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) throws -> __MODULE_NAME__ {
        guard lhs.currency == rhs.currency else {
            throw MoneyError.currencyMismatch(lhs: lhs.currency, rhs: rhs.currency)
        }
        return __MODULE_NAME__(amount: lhs.amount - rhs.amount, currency: lhs.currency)
    }

    public static func * (lhs: __MODULE_NAME__, multiplier: Int) -> __MODULE_NAME__ {
        __MODULE_NAME__(amount: lhs.amount * Decimal(multiplier), currency: lhs.currency)
    }

    public static func < (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) -> Bool {
        guard lhs.currency == rhs.currency else { return false }
        return lhs.amount < rhs.amount
    }
}
