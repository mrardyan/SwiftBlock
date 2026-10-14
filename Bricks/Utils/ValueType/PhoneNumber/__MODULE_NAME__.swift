import Foundation

/// Errors thrown by phone number validation.
public enum PhoneNumberError: Error, Equatable, Sendable {
    case invalidFormat(String)
}

/// Type-safe semantic wrapper for phone numbers.
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable, CustomStringConvertible, RawRepresentable {
    public let rawValue: String

    public init?(rawValue: String) {
        let cleaned = rawValue.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard cleaned.count >= 7 && cleaned.count <= 15 else {
            return nil
        }
        let formatted = rawValue.hasPrefix("+") ? "+" + cleaned : cleaned
        self.rawValue = formatted
    }

    public init(_ stringValue: String) throws {
        guard let instance = __MODULE_NAME__(rawValue: stringValue) else {
            throw PhoneNumberError.invalidFormat(stringValue)
        }
        self = instance
    }

    public var description: String {
        rawValue
    }

    public var e164Formatted: String {
        if rawValue.hasPrefix("+") {
            return rawValue
        }
        return "+" + rawValue
    }
}
