import Foundation

/// Errors thrown by virtual account validation.
public enum VirtualAccountError: Error, Equatable, Sendable {
    case invalidLength(String)
    case containsNonDigits(String)
}

/// Type-safe representation of bank Virtual Account / Bank Account numbers.
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable, CustomStringConvertible, ExpressibleByStringLiteral {
    public let number: String
    public let bankName: String?

    public init(number: String, bankName: String? = nil) throws {
        let cleaned = number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard (8...20).contains(cleaned.count) else {
            throw VirtualAccountError.invalidLength(number)
        }
        self.number = cleaned
        self.bankName = bankName
    }

    public init(stringLiteral value: String) {
        let cleaned = value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        self.number = cleaned.isEmpty ? "0000000000" : cleaned
        self.bankName = nil
    }

    public var description: String {
        formattedGrouped
    }

    /// Formatted number grouped per 4 digits (e.g. "8801 2345 6789")
    public var formattedGrouped: String {
        var result = ""
        for (index, char) in number.enumerated() {
            if index > 0 && index % 4 == 0 {
                result.append(" ")
            }
            result.append(char)
        }
        return result
    }
}
