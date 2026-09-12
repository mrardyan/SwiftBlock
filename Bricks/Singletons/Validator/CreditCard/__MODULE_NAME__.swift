import Foundation

/// Supported payment card networks.
public enum CreditCardBrand: String, Sendable, CaseIterable {
    case visa = "Visa"
    case mastercard = "Mastercard"
    case amex = "American Express"
    case discover = "Discover"
    case jcb = "JCB"
    case unknown = "Unknown"
}

/// Defines standard interface for payment card validation.
public protocol CreditCardValidatorProtocol: Sendable {
    func validateNumber(_ cardNumber: String) -> Bool
    func detectBrand(_ cardNumber: String) -> CreditCardBrand
    func validateExpiration(month: Int, year: Int) -> Bool
    func validateCVV(_ cvv: String, brand: CreditCardBrand) -> Bool
}

/// Thread-safe payment card validator implementing the Luhn checksum algorithm (ISO/IEC 7812-1).
public final class __MODULE_NAME__: CreditCardValidatorProtocol {
    /// Shared singleton instance.
    public static let shared = __MODULE_NAME__()

    public init() {}

    /// Validates a credit card number using Luhn algorithm (ISO/IEC 7812-1).
    public func validateNumber(_ cardNumber: String) -> Bool {
        let digits = cardNumber.compactMap { $0.wholeNumberValue }
        guard digits.count >= 8 && digits.count <= 19 else { return false }
        guard digits.count == cardNumber.filter({ !$0.isWhitespace && $0 != "-" }).count else { return false }

        var sum = 0
        let reversedDigits = digits.reversed()
        for (index, digit) in reversedDigits.enumerated() {
            if index % 2 == 1 {
                let doubled = digit * 2
                sum += doubled > 9 ? doubled - 9 : doubled
            } else {
                sum += digit
            }
        }
        return sum % 10 == 0
    }

    /// Detects card issuer brand from IIN/BIN prefix patterns.
    public func detectBrand(_ cardNumber: String) -> CreditCardBrand {
        let cleaned = cardNumber.filter { $0.isNumber }
        guard !cleaned.isEmpty else { return .unknown }

        if cleaned.hasPrefix("4") { return .visa }
        if cleaned.hasPrefix("34") || cleaned.hasPrefix("37") { return .amex }

        if let firstTwo = Int(cleaned.prefix(2)), (51...55).contains(firstTwo) {
            return .mastercard
        }
        if let firstFour = Int(cleaned.prefix(4)), (2221...2720).contains(firstFour) {
            return .mastercard
        }
        if cleaned.hasPrefix("6011") || cleaned.hasPrefix("65") { return .discover }
        if let firstFour = Int(cleaned.prefix(4)), (3528...3589).contains(firstFour) {
            return .jcb
        }

        return .unknown
    }

    /// Validates card expiration month and year against current date.
    public func validateExpiration(month: Int, year: Int) -> Bool {
        guard (1...12).contains(month) else { return false }

        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)

        let fullYear = year < 100 ? 2000 + year : year

        if fullYear < currentYear { return false }
        if fullYear == currentYear && month < currentMonth { return false }
        return fullYear <= currentYear + 20
    }

    /// Validates security code (CVV/CVC) length based on card brand.
    public func validateCVV(_ cvv: String, brand: CreditCardBrand = .unknown) -> Bool {
        let cleaned = cvv.filter { $0.isNumber }
        let requiredLength = (brand == .amex) ? 4 : 3
        return cleaned.count == requiredLength
    }
}
