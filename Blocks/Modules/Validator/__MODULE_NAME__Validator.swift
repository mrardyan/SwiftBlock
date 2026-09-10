import Foundation

public enum ValidationResult: Equatable {
    case valid
    case invalid(reason: String)

    public var isValid: Bool {
        if case .valid = self { return true }
        return false
    }
}

public protocol __MODULE_NAME__Validating {
    func validate(_ input: String) -> ValidationResult
}

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
