import Foundation

/// Result of an input validation check.
public enum ValidationResult: Equatable, Sendable {
    case valid
    case invalid(reason: String)

    public var isValid: Bool {
        if case .valid = self { return true }
        return false
    }
}

/// Interface for input validation.
public protocol __MODULE_NAME__Validating: Sendable {
    associatedtype Input
    func validate(_ input: Input) -> ValidationResult
}

/// Generic input validator implementation for `__MODULE_NAME__`.
public struct __MODULE_NAME__Validator<Input>: __MODULE_NAME__Validating {
    private let validateHandler: @Sendable (Input) -> ValidationResult

    public init(validateHandler: @escaping @Sendable (Input) -> ValidationResult) {
        self.validateHandler = validateHandler
    }

    public func validate(_ input: Input) -> ValidationResult {
        validateHandler(input)
    }
}
