import Foundation

/// Thread-safe Token Bucket rate limiter algorithm.
///
/// Refills tokens at a constant rate up to `capacity`, allowing short bursts
/// while maintaining an average rate limit.
public final class __MODULE_NAME__: @unchecked Sendable {
    public let capacity: Double
    public let refillRate: Double // tokens per second
    private var tokens: Double
    private var lastRefillTimestamp: TimeInterval
    private let lock = NSLock()

    /// Creates a token bucket rate limiter.
    /// - Parameters:
    ///   - capacity: Maximum burst capacity (max tokens stored).
    ///   - refillRate: Tokens added per second.
    public init(capacity: Double, refillRate: Double) {
        self.capacity = capacity
        self.refillRate = refillRate
        self.tokens = capacity
        self.lastRefillTimestamp = ProcessInfo.processInfo.systemUptime
    }

    /// Attempts to consume `count` tokens. Returns `true` if allowed, `false` otherwise.
    public func consume(tokens count: Double = 1.0) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        refill()

        guard tokens >= count else {
            return false
        }

        tokens -= count
        return true
    }

    /// Current available token count after accounting for elapsed time.
    public var currentTokens: Double {
        lock.lock()
        defer { lock.unlock() }
        refill()
        return tokens
    }

    /// Resets the bucket back to full capacity.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        tokens = capacity
        lastRefillTimestamp = ProcessInfo.processInfo.systemUptime
    }

    private func refill() {
        let now = ProcessInfo.processInfo.systemUptime
        let elapsed = max(0, now - lastRefillTimestamp)
        lastRefillTimestamp = now

        let newTokens = elapsed * refillRate
        tokens = min(capacity, tokens + newTokens)
    }
}
