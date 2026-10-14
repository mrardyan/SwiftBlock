import Foundation

/// Luhn Algorithm (Modulo 10 checksum formula).
///
/// Widely used to validate primary account numbers (credit/debit cards), IMEI numbers,
/// and National Provider Identifiers against accidental input errors.
public enum __MODULE_NAME__: Sendable {
    /// Validates whether a numerical string passes the Luhn checksum test.
    public static func validate(_ numberString: String) -> Bool {
        let digits = numberString.filter { $0.isNumber }
        guard digits.count >= 2 else { return false }

        var sum = 0
        let reversedDigits = digits.reversed()

        for (index, char) in reversedDigits.enumerated() {
            guard let digit = char.wholeNumberValue else { return false }

            if index % 2 == 1 {
                let doubled = digit * 2
                sum += (doubled > 9 ? doubled - 9 : doubled)
            } else {
                sum += digit
            }
        }

        return sum % 10 == 0
    }

    /// Computes the Luhn check digit for a given payload (without the check digit).
    public static func computeCheckDigit(for payload: String) -> Int? {
        let digits = payload.filter { $0.isNumber }
        guard !digits.isEmpty else { return nil }

        var sum = 0
        let reversedDigits = digits.reversed()

        for (index, char) in reversedDigits.enumerated() {
            guard let digit = char.wholeNumberValue else { return nil }

            if index % 2 == 0 {
                let doubled = digit * 2
                sum += (doubled > 9 ? doubled - 9 : doubled)
            } else {
                sum += digit
            }
        }

        let remainder = sum % 10
        return remainder == 0 ? 0 : (10 - remainder)
    }
}
