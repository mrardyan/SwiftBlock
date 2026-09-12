import Foundation

/// Rules option set for configuring password criteria.
public struct PasswordRules: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let minLength = PasswordRules(rawValue: 1 << 0)
    public static let uppercase = PasswordRules(rawValue: 1 << 1)
    public static let lowercase = PasswordRules(rawValue: 1 << 2)
    public static let number    = PasswordRules(rawValue: 1 << 3)
    public static let symbol    = PasswordRules(rawValue: 1 << 4)

    public static let standard: PasswordRules = [.minLength, .uppercase, .lowercase, .number]
    public static let strict: PasswordRules = [.minLength, .uppercase, .lowercase, .number, .symbol]
}

/// Detailed validation failure reasons.
public enum PasswordValidationError: Error, Equatable, Sendable {
    case tooShort(minLength: Int)
    case missingUppercase
    case missingLowercase
    case missingNumber
    case missingSymbol
}

/// Defines standard interface for password validation.
public protocol PasswordValidatorProtocol: Sendable {
    func validate(_ password: String) -> Bool
    func validateWithDetails(_ password: String) -> [PasswordValidationError]
}

/// Thread-safe password validator with customizable criteria.
public final class __MODULE_NAME__: PasswordValidatorProtocol {
    /// Shared singleton instance with standard rules (min 8 chars, upper, lower, number).
    public static let shared = __MODULE_NAME__()

    public let minLength: Int
    public let rules: PasswordRules

    /// Initializes a password validator instance.
    /// - Parameters:
    ///   - minLength: Minimum required length (default is 8).
    ///   - rules: Set of rules required to pass validation.
    public init(minLength: Int = 8, rules: PasswordRules = .standard) {
        self.minLength = minLength
        self.rules = rules
    }

    /// Validates if password meets configured rules.
    public func validate(_ password: String) -> Bool {
        return validateWithDetails(password).isEmpty
    }

    /// Returns a list of detailed validation errors if password fails required rules.
    public func validateWithDetails(_ password: String) -> [PasswordValidationError] {
        var errors: [PasswordValidationError] = []

        if rules.contains(.minLength) && password.count < minLength {
            errors.append(.tooShort(minLength: minLength))
        }
        if rules.contains(.uppercase) && !password.contains(where: { $0.isUppercase }) {
            errors.append(.missingUppercase)
        }
        if rules.contains(.lowercase) && !password.contains(where: { $0.isLowercase }) {
            errors.append(.missingLowercase)
        }
        if rules.contains(.number) && !password.contains(where: { $0.isNumber }) {
            errors.append(.missingNumber)
        }
        if rules.contains(.symbol) && !password.contains(where: { $0.isPunctuation || $0.isSymbol }) {
            errors.append(.missingSymbol)
        }

        return errors
    }
}
