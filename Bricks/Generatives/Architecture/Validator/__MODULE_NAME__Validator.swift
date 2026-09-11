import Foundation

/// Result of an input validation check.
public enum ValidationResult: Equatable {
    case valid
    case invalid(reason: String)

    public var isValid: Bool {
        if case .valid = self { return true }
        return false
    }
}

/// Interface for input validation.
public protocol __MODULE_NAME__Validating {
    func validate(_ input: String) -> ValidationResult
}

/// Form input validator for `__MODULE_NAME__`.
public struct __MODULE_NAME__Validator: __MODULE_NAME__Validating {
    public init() {}

    public func validate(_ input: String) -> ValidationResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .invalid(reason: "Input cannot be empty.")
        }
        return .valid
    }
}
