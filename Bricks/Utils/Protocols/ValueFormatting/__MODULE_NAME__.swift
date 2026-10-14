import Foundation

/// Universal protocol contract for data formatting into human-readable strings.
public protocol __MODULE_NAME__<Input>: Sendable {
    associatedtype Input

    /// Formats input into a localized or styled string representation.
    func format(_ value: Input) -> String
}

// MARK: - Optional Formatter Wrapper
public struct OptionalValueFormatter<Base: __MODULE_NAME__>: __MODULE_NAME__ {
    public typealias Input = Base.Input?

    private let base: Base
    private let fallback: String

    public init(base: Base, fallback: String = "-") {
        self.base = base
        self.fallback = fallback
    }

    public func format(_ value: Base.Input?) -> String {
        guard let val = value else { return fallback }
        return base.format(val)
    }
}

// MARK: - Closure-based Formatter
public struct AnyValueFormatter<Input>: __MODULE_NAME__, @unchecked Sendable {
    private let closure: (Input) -> String

    public init(_ closure: @escaping (Input) -> String) {
        self.closure = closure
    }

    public func format(_ value: Input) -> String {
        closure(value)
    }
}

public extension __MODULE_NAME__ {
    /// Transforms this formatter to support optional inputs with a default fallback string.
    func optional(fallback: String = "-") -> OptionalValueFormatter<Self> {
        OptionalValueFormatter(base: self, fallback: fallback)
    }
}
