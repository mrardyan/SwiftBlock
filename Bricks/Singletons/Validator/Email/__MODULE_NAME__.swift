import Foundation

/// Defines standard interface for email validation.
public protocol EmailValidatorProtocol: Sendable {
    /// Validates whether the given string is a correctly formatted email address.
    /// - Parameter email: The string to validate.
    /// - Returns: `true` if valid, `false` otherwise.
    func validate(_ email: String) -> Bool
}

/// Thread-safe email validator implementing `EmailValidatorProtocol`.
public final class __MODULE_NAME__: EmailValidatorProtocol {
    /// Shared singleton instance with standard RFC-compliant rules.
    public static let shared = __MODULE_NAME__()

    private let regex: NSRegularExpression?

    /// Initializes a new instance with a custom validation pattern.
    /// - Parameters:
    ///   - pattern: Regular expression pattern for email validation.
    ///   - options: Regular expression matching options. Default is case-insensitive.
    public init(pattern: String = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$", options: NSRegularExpression.Options = [.caseInsensitive]) {
        self.regex = try? NSRegularExpression(pattern: pattern, options: options)
    }

    /// Validates whether the given string is a valid email address.
    /// - Parameter email: The string to validate.
    /// - Returns: `true` if valid, `false` otherwise.
    public func validate(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let range = NSRange(location: 0, length: trimmed.utf16.count)
        return regex?.firstMatch(in: trimmed, options: [], range: range) != nil
    }
}
