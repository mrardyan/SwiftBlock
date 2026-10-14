import Foundation

/// Exponential backoff calculator with jitter strategies.
///
/// Prevents the "thundering herd" problem during network retries by scaling delays
/// exponentially and adding randomness.
public struct __MODULE_NAME__: Sendable {
    public enum JitterStrategy: Sendable {
        /// No randomness, strict exponential delay: `min(maxDelay, base * multiplier^attempt)`
        case none
        /// Full jitter: `random(0 ... min(maxDelay, base * multiplier^attempt))`
        case full
        /// Equal jitter: `delay / 2 + random(0 ... delay / 2)`
        case equal
    }

    public let baseDelay: TimeInterval
    public let maxDelay: TimeInterval
    public let multiplier: Double
    public let jitter: JitterStrategy

    /// Creates an ExponentialBackoff configuration.
    /// - Parameters:
    ///   - baseDelay: Starting initial delay in seconds (default: 1.0).
    ///   - maxDelay: Upper ceiling for delay in seconds (default: 60.0).
    ///   - multiplier: Growth rate factor per retry attempt (default: 2.0).
    ///   - jitter: Jitter strategy to apply (default: `.full`).
    public init(
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 60.0,
        multiplier: Double = 2.0,
        jitter: JitterStrategy = .full
    ) {
        self.baseDelay = max(0, baseDelay)
        self.maxDelay = max(baseDelay, maxDelay)
        self.multiplier = max(1.0, multiplier)
        self.jitter = jitter
    }

    /// Computes the delay for a 0-indexed or 1-indexed `attempt`.
    public func delay(forAttempt attempt: Int) -> TimeInterval {
        guard attempt >= 0 else { return 0 }
        let calculated = baseDelay * pow(multiplier, Double(attempt))
        let capped = min(maxDelay, calculated)

        switch jitter {
        case .none:
            return capped
        case .full:
            return Double.random(in: 0...capped)
        case .equal:
            let half = capped / 2.0
            return half + Double.random(in: 0...half)
        }
    }

    /// Executes an async throwing closure with retries according to backoff rules.
    public func retry<T: Sendable>(
        maxAttempts: Int = 3,
        shouldRetry: @Sendable (Error) -> Bool = { _ in true },
        operation: @Sendable () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        for attempt in 0..<maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                guard attempt < maxAttempts - 1, shouldRetry(error) else {
                    throw error
                }
                let sleepSecs = delay(forAttempt: attempt)
                let nanos = UInt64(sleepSecs * 1_000_000_000)
                try await Task.sleep(nanoseconds: nanos)
            }
        }
        throw lastError ?? CancellationError()
    }
}
