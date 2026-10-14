import Foundation

public struct ValidationError: Error, LocalizedError, Equatable, Sendable {
    public let message: String
    public let field: String?

    public init(_ message: String, field: String? = nil) {
        self.message = message
        self.field = field
    }

    public var errorDescription: String? { message }
}

/// Universal protocol contract for composable input validation rules.
public protocol __MODULE_NAME__<Input>: Sendable {
    associatedtype Input

    /// Validates an input value, returning `.success` or `.failure(ValidationError)`.
    func validate(_ input: Input) -> Result<Void, ValidationError>
}

public extension __MODULE_NAME__ {
    /// Convenience helper returning `true` if validation passes.
    func isValid(_ input: Input) -> Bool {
        if case .success = validate(input) { return true }
        return false
    }

    /// Combines this validator with another using logical AND (both must pass).
    func and<V: __MODULE_NAME__>(_ other: V) -> AndValidator<Self, V> where V.Input == Input {
        AndValidator(first: self, second: other)
    }

    /// Combines this validator with another using logical OR (at least one must pass).
    func or<V: __MODULE_NAME__>(_ other: V) -> OrValidator<Self, V> where V.Input == Input {
        OrValidator(first: self, second: other)
    }

    /// Inverts this validator using logical NOT.
    func not(failureMessage: String = "Validation condition inverted") -> NotValidator<Self> {
        NotValidator(base: self, message: failureMessage)
    }
}

// MARK: - Combinators

public struct AndValidator<First: __MODULE_NAME__, Second: __MODULE_NAME__>: __MODULE_NAME__ where First.Input == Second.Input {
    public typealias Input = First.Input

    private let first: First
    private let second: Second

    public init(first: First, second: Second) {
        self.first = first
        self.second = second
    }

    public func validate(_ input: Input) -> Result<Void, ValidationError> {
        switch first.validate(input) {
        case .failure(let err): return .failure(err)
        case .success: return second.validate(input)
        }
    }
}

public struct OrValidator<First: __MODULE_NAME__, Second: __MODULE_NAME__>: __MODULE_NAME__ where First.Input == Second.Input {
    public typealias Input = First.Input

    private let first: First
    private let second: Second

    public init(first: First, second: Second) {
        self.first = first
        self.second = second
    }

    public func validate(_ input: Input) -> Result<Void, ValidationError> {
        switch first.validate(input) {
        case .success: return .success(())
        case .failure: return second.validate(input)
        }
    }
}

public struct NotValidator<Base: __MODULE_NAME__>: __MODULE_NAME__ {
    public typealias Input = Base.Input

    private let base: Base
    private let message: String

    public init(base: Base, message: String) {
        self.base = base
        self.message = message
    }

    public func validate(_ input: Input) -> Result<Void, ValidationError> {
        if case .success = base.validate(input) {
            return .failure(ValidationError(message))
        }
        return .success(())
    }
}

/// Closure-based validator rule.
public struct AnyValidator<Input>: __MODULE_NAME__, @unchecked Sendable {
    private let predicate: (Input) -> Result<Void, ValidationError>

    public init(_ predicate: @escaping (Input) -> Result<Void, ValidationError>) {
        self.predicate = predicate
    }

    public init(_ boolPredicate: @escaping (Input) -> Bool, failureMessage: String) {
        self.predicate = { input in
            boolPredicate(input) ? .success(()) : .failure(ValidationError(failureMessage))
        }
    }

    public func validate(_ input: Input) -> Result<Void, ValidationError> {
        predicate(input)
    }
}
