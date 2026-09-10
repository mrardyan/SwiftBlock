import Foundation

/// Result enum representing validation outcome.
public enum ValidationResult: Equatable {
    case valid
    case invalid(reason: String)

    /// Returns true if the validation result is valid.
    public var isValid: Bool {
        if case .valid = self { return true }
        return false
    }
}

/// Interface for input validation logic.
public protocol __MODULE_NAME__Validating {
    /// Validates an input string.
    func validate(_ input: String) -> ValidationResult
}

/// Form input validator implementation for __MODULE_NAME__.
public struct __MODULE_NAME__Validator: __MODULE_NAME__Validating {
    /// Initializes a new validator instance.
    public init() {}

    /// Validates input string ensuring non-empty state after trimming.
    public func validate(_ input: String) -> ValidationResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .invalid(reason: "Input cannot be empty.")
        }
        return .valid
    }
}
