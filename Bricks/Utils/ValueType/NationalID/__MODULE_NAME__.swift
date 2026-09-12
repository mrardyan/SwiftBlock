import Foundation

/// Errors thrown by national ID validation.
public enum NationalIDError: Error, Equatable, Sendable {
    case invalidLength(String, expected: Int)
    case nonNumericCharacters(String)
}

/// Type-safe representation of national identity number (e.g. NIK / KTP 16-digit).
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable, CustomStringConvertible, ExpressibleByStringLiteral {
    public let value: String

    public init(value: String, expectedLength: Int = 16) throws {
        let cleaned = value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard cleaned.count == expectedLength else {
            throw NationalIDError.invalidLength(value, expected: expectedLength)
        }
        self.value = cleaned
    }

    public init(stringLiteral value: String) {
        let cleaned = value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        self.value = cleaned
    }

    public var description: String {
        value
    }

    /// Masked string for privacy (e.g. "317101******0001")
    public var masked: String {
        guard value.count >= 12 else { return "************" }
        let prefix = value.prefix(6)
        let suffix = value.suffix(4)
        let maskCount = value.count - 10
        return "\(prefix)\(String(repeating: "*", count: maskCount))\(suffix)"
    }
}

/// Convenient typealias for Indonesian term 'NIK'
public typealias NIK = __MODULE_NAME__
