import Foundation

/// Universal protocol contract for data transformations and model mapping.
public protocol __MODULE_NAME__<Source, Target>: Sendable {
    associatedtype Source
    associatedtype Target

    /// Transforms a source model into a target representation.
    func transform(_ source: Source) throws -> Target
}

// MARK: - Pipeline Combinator

/// Transformer composed of two sequential transformers (A -> B -> C).
public struct PipedTransformer<First: __MODULE_NAME__, Second: __MODULE_NAME__>: __MODULE_NAME__ where First.Target == Second.Source {
    public typealias Source = First.Source
    public typealias Target = Second.Target

    private let first: First
    private let second: Second

    public init(first: First, second: Second) {
        self.first = first
        self.second = second
    }

    public func transform(_ source: Source) throws -> Target {
        let intermediate = try first.transform(source)
        return try second.transform(intermediate)
    }
}

// MARK: - Closure-based Transformer
public struct AnyTransformer<Source, Target>: __MODULE_NAME__, @unchecked Sendable {
    private let closure: (Source) throws -> Target

    public init(_ closure: @escaping (Source) throws -> Target) {
        self.closure = closure
    }

    public func transform(_ source: Source) throws -> Target {
        try closure(source)
    }
}

// MARK: - Composable Extensions
public extension __MODULE_NAME__ {
    /// Connects this transformer with a subsequent transformer into a single pipeline.
    func pipe<Next: __MODULE_NAME__>(_ next: Next) -> PipedTransformer<Self, Next> where Next.Source == Target {
        PipedTransformer(first: self, second: next)
    }

    /// Transforms an array of source elements.
    func transformAll(_ sources: [Source]) throws -> [Target] {
        try sources.map { try transform($0) }
    }
}
