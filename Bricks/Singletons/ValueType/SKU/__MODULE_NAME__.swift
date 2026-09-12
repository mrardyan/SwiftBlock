import Foundation

/// Errors thrown by SKU validation.
public enum SKUError: Error, Equatable, Sendable {
    case emptyValue
    case invalidCharacters(String)
    case invalidLength(String, min: Int, max: Int)
}

/// Type-safe representation of a Stock Keeping Unit (SKU).
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable, CustomStringConvertible, ExpressibleByStringLiteral {
    public let rawValue: String

    public var description: String {
        rawValue
    }

    public init(rawValue: String, minLength: Int = 3, maxLength: Int = 30) throws {
        let clean = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !clean.isEmpty else {
            throw SKUError.emptyValue
        }
        guard (minLength...maxLength).contains(clean.count) else {
            throw SKUError.invalidLength(clean, min: minLength, max: maxLength)
        }
        // SKUs usually contain alphanumeric, dash, underscore
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        guard clean.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
            throw SKUError.invalidCharacters(clean)
        }
        self.rawValue = clean
    }

    public init(stringLiteral value: String) {
        try! self.init(rawValue: value)
    }
}
