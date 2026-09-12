import Foundation

/// Errors thrown by email address validation.
public enum EmailAddressError: Error, Equatable, Sendable {
    case invalidFormat(String)
}

/// Type-safe semantic wrapper for email addresses.
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable, CustomStringConvertible, RawRepresentable {
    public let rawValue: String

    public init?(rawValue: String) {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let pattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        guard trimmed.range(of: pattern, options: .regularExpression) != nil else {
            return nil
        }
        self.rawValue = trimmed
    }

    public init(_ stringValue: String) throws {
        guard let instance = __MODULE_NAME__(rawValue: stringValue) else {
            throw EmailAddressError.invalidFormat(stringValue)
        }
        self = instance
    }

    public var description: String {
        rawValue
    }

    public var username: String {
        String(rawValue.prefix(while: { $0 != "@" }))
    }

    public var domain: String {
        if let atIndex = rawValue.firstIndex(of: "@") {
            return String(rawValue.suffix(from: rawValue.index(after: atIndex)))
        }
        return ""
    }
}
