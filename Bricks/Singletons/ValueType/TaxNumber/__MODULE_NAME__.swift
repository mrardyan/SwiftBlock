import Foundation

/// Errors thrown by tax number validation.
public enum TaxNumberError: Error, Equatable, Sendable {
    case invalidLength(value: String, expected: ClosedRange<Int>)
    case invalidCharacters(String)
}

/// Predefined tax number format rules.
public enum TaxNumberFormat: Codable, Equatable, Hashable, Sendable {
    /// Indonesian NPWP (15 or 16 digits, formatted as XX.XXX.XXX.X-XXX.XXX).
    case indonesia
    /// US TIN / SSN / EIN (9 digits, formatted as XXX-XX-XXXX).
    case unitedStates
    /// Custom pattern where '#' represents a digit placeholder (e.g. "##.###.###.#-###.###").
    case custom(pattern: String)
    /// Freeform with length constraint only.
    case freeform(minLength: Int, maxLength: Int)
}

/// Type-safe representation of tax identification numbers with adjustable format.
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable, CustomStringConvertible {
    public let digits: String
    public let format: TaxNumberFormat

    public init(value: String, format: TaxNumberFormat = .freeform(minLength: 8, maxLength: 20)) throws {
        let cleaned = value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        let lengthRange = Self.lengthRange(for: format)

        guard lengthRange.contains(cleaned.count) else {
            throw TaxNumberError.invalidLength(value: value, expected: lengthRange)
        }

        self.digits = cleaned
        self.format = format
    }

    public var description: String {
        formatted
    }

    /// Formatted string according to the tax number format pattern.
    public var formatted: String {
        switch format {
        case .indonesia:
            return Self.applyPattern(digits: digits, pattern: "##.###.###.#-###.###")
        case .unitedStates:
            return Self.applyPattern(digits: digits, pattern: "###-##-####")
        case .custom(let pattern):
            return Self.applyPattern(digits: digits, pattern: pattern)
        case .freeform:
            return digits
        }
    }

    /// Masked string for privacy (e.g. "01.234.***.*-***.000").
    public var masked: String {
        guard digits.count >= 6 else { return String(repeating: "*", count: digits.count) }
        let prefix = digits.prefix(4)
        let suffix = digits.suffix(3)
        let maskCount = digits.count - 7
        return "\(prefix)\(String(repeating: "*", count: maskCount))\(suffix)"
    }

    // MARK: - Private

    private static func lengthRange(for format: TaxNumberFormat) -> ClosedRange<Int> {
        switch format {
        case .indonesia: return 15...16
        case .unitedStates: return 9...9
        case .custom(let pattern): let count = pattern.filter({ $0 == "#" }).count; return count...count
        case .freeform(let min, let max): return min...max
        }
    }

    private static func applyPattern(digits: String, pattern: String) -> String {
        var result = ""
        var digitIndex = digits.startIndex
        for char in pattern {
            guard digitIndex < digits.endIndex else { break }
            if char == "#" {
                result.append(digits[digitIndex])
                digitIndex = digits.index(after: digitIndex)
            } else {
                result.append(char)
            }
        }
        // Append remaining digits if pattern is shorter
        if digitIndex < digits.endIndex {
            result.append(contentsOf: digits[digitIndex...])
        }
        return result
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case digits
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.digits = try container.decode(String.self, forKey: .digits)
        self.format = .freeform(minLength: 1, maxLength: 30)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(digits, forKey: .digits)
    }
}

/// Convenient typealias for Indonesian NPWP.
public typealias NPWP = __MODULE_NAME__
