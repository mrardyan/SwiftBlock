import Foundation

/// Defines standard interface for currency formatting.
public protocol CurrencyFormatterProtocol: Sendable {
    func string(from value: Decimal, code: String, locale: Locale) -> String?
    func string(from value: Double, code: String, locale: Locale) -> String?
}

/// Thread-safe currency formatter singleton reusing `NumberFormatter`.
public final class __MODULE_NAME__: @unchecked Sendable, CurrencyFormatterProtocol {
    /// Shared singleton instance.
    public static let shared = __MODULE_NAME__()

    private let lock = NSLock()
    private let formatter: NumberFormatter

    public init() {
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        self.formatter = fmt
    }

    /// Formats a `Decimal` value as a currency string.
    public func string(from value: Decimal, code: String = "USD", locale: Locale = .current) -> String? {
        lock.lock()
        defer { lock.unlock() }
        formatter.locale = locale
        formatter.currencyCode = code
        return formatter.string(from: value as NSDecimalNumber)
    }

    /// Formats a `Double` value as a currency string.
    public func string(from value: Double, code: String = "USD", locale: Locale = .current) -> String? {
        return string(from: Decimal(value), code: code, locale: locale)
    }
}
