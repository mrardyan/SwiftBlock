import Foundation

/// Universal asynchronous domain logic business contract.
public protocol __MODULE_NAME__<Input, Output>: Sendable {
    associatedtype Input: Sendable
    associatedtype Output: Sendable

    /// Executes the business logic unit with given input.
    func execute(_ input: Input) async throws -> Output
}

// MARK: - Decorators

/// Decorator wrapping an AsyncUseCase with retry logic.
public struct RetryUseCaseDecorator<Base: __MODULE_NAME__>: __MODULE_NAME__ {
    public typealias Input = Base.Input
    public typealias Output = Base.Output

    private let base: Base
    private let maxAttempts: Int

    public init(base: Base, maxAttempts: Int = 3) {
        self.base = base
        self.maxAttempts = max(1, maxAttempts)
    }

    public func execute(_ input: Input) async throws -> Output {
        var lastError: Error?
        for attempt in 0..<maxAttempts {
            do {
                return try await base.execute(input)
            } catch {
                lastError = error
                guard attempt < maxAttempts - 1 else { break }
                let delay = Double(attempt + 1) * 0.1
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        throw lastError ?? CancellationError()
    }
}

/// Decorator wrapping an AsyncUseCase with execution timing metrics.
public struct TimedUseCaseDecorator<Base: __MODULE_NAME__>: __MODULE_NAME__ {
    public typealias Input = Base.Input
    public typealias Output = Base.Output

    private let base: Base
    private let onComplete: @Sendable (TimeInterval, Result<Output, Error>) -> Void

    public init(base: Base, onComplete: @escaping @Sendable (TimeInterval, Result<Output, Error>) -> Void) {
        self.base = base
        self.onComplete = onComplete
    }

    public func execute(_ input: Input) async throws -> Output {
        let start = ProcessInfo.processInfo.systemUptime
        do {
            let result = try await base.execute(input)
            let duration = ProcessInfo.processInfo.systemUptime - start
            onComplete(duration, .success(result))
            return result
        } catch {
            let duration = ProcessInfo.processInfo.systemUptime - start
            onComplete(duration, .failure(error))
            throw error
        }
    }
}

// MARK: - Composable Extensions
public extension __MODULE_NAME__ {
    /// Decorates this use case with automated retry attempts upon failure.
    func withRetry(maxAttempts: Int = 3) -> RetryUseCaseDecorator<Self> {
        RetryUseCaseDecorator(base: self, maxAttempts: maxAttempts)
    }

    /// Decorates this usecase with execution time telemetry.
    func withTiming(_ onComplete: @escaping @Sendable (TimeInterval, Result<Output, Error>) -> Void) -> TimedUseCaseDecorator<Self> {
        TimedUseCaseDecorator(base: self, onComplete: onComplete)
    }
}
