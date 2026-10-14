import Foundation

public enum CircuitBreakerError: Error, LocalizedError, Sendable {
    case circuitOpen

    public var errorDescription: String? {
        switch self {
        case .circuitOpen:
            return "Circuit is open; call rejected to protect downstream service."
        }
    }
}

/// Thread-safe Circuit Breaker state machine (Closed, Open, Half-Open).
///
/// Prevents cascading failures by short-circuiting calls to a failing remote dependency.
public final class __MODULE_NAME__: @unchecked Sendable {
    public enum State: Sendable, Equatable {
        case closed
        case open
        case halfOpen
    }

    public let failureThreshold: Int
    public let resetTimeout: TimeInterval
    public let halfOpenSuccessThreshold: Int

    private var state: State = .closed
    private var failureCount = 0
    private var successCount = 0
    private var activeProbes = 0
    private var lastStateChangeTimestamp: TimeInterval
    private let lock = NSLock()

    /// Creates a Circuit Breaker.
    /// - Parameters:
    ///   - failureThreshold: Consecutive failures required to trip the circuit open (default: 5).
    ///   - resetTimeout: Duration in seconds to wait in Open state before transitioning to Half-Open (default: 30.0).
    ///   - halfOpenSuccessThreshold: Consecutive successes in Half-Open needed to restore Closed state (default: 2).
    public init(
        failureThreshold: Int = 5,
        resetTimeout: TimeInterval = 30.0,
        halfOpenSuccessThreshold: Int = 2
    ) {
        self.failureThreshold = max(1, failureThreshold)
        self.resetTimeout = max(0.1, resetTimeout)
        self.halfOpenSuccessThreshold = max(1, halfOpenSuccessThreshold)
        self.lastStateChangeTimestamp = ProcessInfo.processInfo.systemUptime
    }

    /// Current operational state of the circuit.
    public var currentState: State {
        lock.lock()
        defer { lock.unlock() }
        evaluateStateTransition()
        return state
    }

    private func tryAcquireExecution() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        evaluateStateTransition()
        switch state {
        case .closed:
            return true
        case .open:
            return false
        case .halfOpen:
            if activeProbes < halfOpenSuccessThreshold {
                activeProbes += 1
                return true
            }
            return false
        }
    }

    /// Runs a throwing async operation protected by the circuit breaker.
    public func execute<T: Sendable>(_ operation: @Sendable () async throws -> T) async throws -> T {
        guard tryAcquireExecution() else {
            throw CircuitBreakerError.circuitOpen
        }

        do {
            let result = try await operation()
            onSuccess()
            return result
        } catch {
            onFailure(error: error)
            throw error
        }
    }

    private func evaluateStateTransition() {
        if state == .open {
            let now = ProcessInfo.processInfo.systemUptime
            if now - lastStateChangeTimestamp >= resetTimeout {
                state = .halfOpen
                successCount = 0
                activeProbes = 0
                lastStateChangeTimestamp = now
            }
        }
    }

    private func onSuccess() {
        lock.lock()
        defer { lock.unlock() }

        if state == .halfOpen {
            activeProbes = max(0, activeProbes - 1)
            successCount += 1
            if successCount >= halfOpenSuccessThreshold {
                state = .closed
                failureCount = 0
                successCount = 0
                activeProbes = 0
                lastStateChangeTimestamp = ProcessInfo.processInfo.systemUptime
            }
        } else if state == .closed {
            failureCount = 0
        }
    }

    private func onFailure(error: Error) {
        if error is CancellationError {
            lock.lock()
            defer { lock.unlock() }
            if state == .halfOpen {
                activeProbes = max(0, activeProbes - 1)
            }
            return
        }

        lock.lock()
        defer { lock.unlock() }

        if state == .halfOpen {
            activeProbes = 0
            state = .open
            lastStateChangeTimestamp = ProcessInfo.processInfo.systemUptime
        } else if state == .closed {
            failureCount += 1
            if failureCount >= failureThreshold {
                state = .open
                lastStateChangeTimestamp = ProcessInfo.processInfo.systemUptime
            }
        }
    }

    /// Manually reset circuit breaker to closed state.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        state = .closed
        failureCount = 0
        successCount = 0
        activeProbes = 0
        lastStateChangeTimestamp = ProcessInfo.processInfo.systemUptime
    }
}
