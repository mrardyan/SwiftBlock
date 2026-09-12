import Foundation

/// Defines standard interface for phone number validation.
public protocol PhoneValidatorProtocol: Sendable {
    /// Validates whether the given string is a valid phone number.
    /// - Parameter phone: The phone string to validate.
    /// - Returns: `true` if valid, `false` otherwise.
    func validate(_ phone: String) -> Bool
}

/// Thread-safe phone number validator implementing `PhoneValidatorProtocol`.
public final class __MODULE_NAME__: PhoneValidatorProtocol {
    /// Shared singleton instance configured with default international E.164 and local phone format rules.
    public static let shared = __MODULE_NAME__()

    private let regex: NSRegularExpression?

    /// Initializes a new phone validator with a custom regex pattern.
    /// - Parameter pattern: Regex pattern for phone number validation. Default accepts E.164 and standard local formats.
    public init(pattern: String = "^\\+?[0-9]\\d{6,14}$") {
        self.regex = try? NSRegularExpression(pattern: pattern)
    }

    /// Validates whether the given string matches valid phone number formatting.
    /// - Parameter phone: The phone number string to validate.
    /// - Returns: `true` if valid, `false` otherwise.
    public func validate(_ phone: String) -> Bool {
        let cleaned = phone.components(separatedBy: CharacterSet(charactersIn: " -()").union(.whitespacesAndNewlines)).joined()
        guard !cleaned.isEmpty else { return false }
        let range = NSRange(location: 0, length: cleaned.utf16.count)
        return regex?.firstMatch(in: cleaned, options: [], range: range) != nil
    }
}
