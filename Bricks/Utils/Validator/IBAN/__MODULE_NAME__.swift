import Foundation

/// Errors thrown by IBAN validation.
public enum IBANValidationError: Error, Equatable, Sendable {
    case emptyString
    case invalidLength(Int)
    case invalidCountryCode(String)
    case invalidFormat
    case invalidCheckDigits
}

/// Validator for International Bank Account Numbers (IBAN) using ISO 13616 Mod-97 check digits.
public struct __MODULE_NAME__: Sendable {
    public static let shared = __MODULE_NAME__()

    public init() {}

    public func validate(_ ibanString: String) -> Result<Void, IBANValidationError> {
        let cleaned = ibanString.components(separatedBy: .whitespacesAndNewlines).joined().uppercased()

        guard !cleaned.isEmpty else {
            return .failure(.emptyString)
        }

        guard (15...34).contains(cleaned.count) else {
            return .failure(.invalidLength(cleaned.count))
        }

        let countryCode = String(cleaned.prefix(2))
        guard countryCode.allSatisfy({ $0.isLetter }) else {
            return .failure(.invalidCountryCode(countryCode))
        }

        // Move first 4 chars to the end
        let rearranged = String(cleaned.dropFirst(4)) + cleaned.prefix(4)

        // Convert letters to numbers (A=10 ... Z=35)
        var numericString = ""
        for char in rearranged {
            if let ascii = char.asciiValue, ascii >= 65 && ascii <= 90 {
                numericString.append(String(ascii - 55))
            } else if char.isNumber {
                numericString.append(char)
            } else {
                return .failure(.invalidFormat)
            }
        }

        // Perform MOD-97 in chunks to avoid numeric overflow
        var remainder = 0
        for char in numericString {
            guard let digit = Int(String(char)) else { return .failure(.invalidFormat) }
            remainder = (remainder * 10 + digit) % 97
        }

        guard remainder == 1 else {
            return .failure(.invalidCheckDigits)
        }

        return .success(())
    }

    public func isValid(_ ibanString: String) -> Bool {
        if case .success = validate(ibanString) {
            return true
        }
        return false
    }
}
