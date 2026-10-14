import Foundation

/// Errors thrown by mobile credit operations.
public enum MobileCreditError: Error, Equatable, Sendable {
    case negativeAmount(Decimal)
    case insufficientCredit(requested: Decimal, available: Decimal)
    case currencyMismatch(lhs: String, rhs: String)
}

/// Type-safe representation of mobile phone credit (pulsa) balance.
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable, Comparable {
    public let amount: Decimal
    public let currency: String
    public let expiryDate: Date?

    public init(amount: Decimal, currency: String = "IDR", expiryDate: Date? = nil) throws {
        guard amount >= 0 else {
            throw MobileCreditError.negativeAmount(amount)
        }
        self.amount = amount
        self.currency = currency.uppercased()
        self.expiryDate = expiryDate
    }

    public var isExpired: Bool {
        guard let expiryDate = expiryDate else { return false }
        return expiryDate < Date()
    }

    public var formatted: String {
        formatted(locale: .current)
    }

    public func formatted(locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 0
        formatter.locale = locale
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currency) \(amount)"
    }

    public func deduct(_ value: Decimal) throws -> __MODULE_NAME__ {
        guard value <= amount else {
            throw MobileCreditError.insufficientCredit(requested: value, available: amount)
        }
        return try __MODULE_NAME__(amount: amount - value, currency: currency, expiryDate: expiryDate)
    }

    public static func + (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) throws -> __MODULE_NAME__ {
        guard lhs.currency == rhs.currency else {
            throw MobileCreditError.currencyMismatch(lhs: lhs.currency, rhs: rhs.currency)
        }
        let latestExpiry: Date?
        if let lhsExp = lhs.expiryDate, let rhsExp = rhs.expiryDate {
            latestExpiry = max(lhsExp, rhsExp)
        } else {
            latestExpiry = lhs.expiryDate ?? rhs.expiryDate
        }
        return try __MODULE_NAME__(amount: lhs.amount + rhs.amount, currency: lhs.currency, expiryDate: latestExpiry)
    }

    public static func < (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) -> Bool {
        if lhs.currency != rhs.currency {
            return lhs.currency < rhs.currency
        }
        return lhs.amount < rhs.amount
    }
}

/// Convenient typealias for Indonesian term 'Pulsa'
public typealias Pulsa = __MODULE_NAME__
