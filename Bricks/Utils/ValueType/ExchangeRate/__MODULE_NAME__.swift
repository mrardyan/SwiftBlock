import Foundation

/// Errors thrown by exchange rate operations.
public enum ExchangeRateError: Error, Equatable, Sendable {
    case invalidRate(Decimal)
    case currencyMismatch(expected: String, actual: String)
}

/// Type-safe representation of foreign exchange rates between two currency codes.
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable {
    public let baseCurrency: String
    public let targetCurrency: String
    public let rate: Decimal

    public init(base: String, target: String, rate: Decimal) throws {
        guard rate > 0 else {
            throw ExchangeRateError.invalidRate(rate)
        }
        self.baseCurrency = base.uppercased()
        self.targetCurrency = target.uppercased()
        self.rate = rate
    }

    /// Converts an amount in base currency to target currency.
    public func convert(_ amount: Decimal) -> Decimal {
        amount * rate
    }

    /// Inverted rate (target -> base).
    public var inverted: __MODULE_NAME__ {
        try! __MODULE_NAME__(base: targetCurrency, target: baseCurrency, rate: 1 / rate)
    }

    public var formatted: String {
        formatted(locale: .current)
    }

    public func formatted(locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 4
        formatter.locale = locale
        let rateStr = formatter.string(from: rate as NSDecimalNumber) ?? "\(rate)"
        return "1 \(baseCurrency) = \(rateStr) \(targetCurrency)"
    }
}
