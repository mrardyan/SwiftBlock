import Foundation

/// Thread-safe throttler enforcing a maximum execution frequency.
///
/// Executes the first call immediately (leading edge) and suppresses subsequent calls
/// until the interval has elapsed, optionally running the trailing call.
public final class __MODULE_NAME__: @unchecked Sendable {
    private let interval: TimeInterval
    private let latestOnly: Bool
    private var lastExecutionTime: Date?
    private var pendingTask: Task<Void, Never>?
    private let lock = NSLock()

    /// Creates a new Throttle instance.
    /// - Parameters:
    ///   - interval: Minimum time between executions in seconds.
    ///   - latestOnly: If true, schedules the most recent suppressed call to execute when the interval expires.
    public init(interval: TimeInterval, latestOnly: Bool = true) {
        self.interval = interval
        self.latestOnly = latestOnly
    }

    /// Triggers the throttled action.
    public func call(action: @escaping @Sendable () async -> Void) {
        lock.lock()
        defer { lock.unlock() }

        let now = Date()
        let elapsed = now.timeIntervalSince(lastExecutionTime ?? .distantPast)

        if elapsed >= interval {
            lastExecutionTime = now
            pendingTask?.cancel()
            pendingTask = nil
            Task {
                await action()
            }
        } else if latestOnly {
            pendingTask?.cancel()
            let remaining = interval - elapsed
            let remainingNanos = UInt64(remaining * 1_000_000_000)

            pendingTask = Task {
                do {
                    try await Task.sleep(nanoseconds: remainingNanos)
                    guard !Task.isCancelled else { return }
                    self.updateLastExecutionTime(Date())
                    await action()
                } catch {
                    // Cancelled
                }
            }
        }
    }

    /// Synchronous variant of `call`.
    public func call(action: @escaping @Sendable () -> Void) {
        call {
            action()
        }
    }

    private func updateLastExecutionTime(_ date: Date) {
        lock.lock()
        defer { lock.unlock() }
        lastExecutionTime = date
    }

    /// Cancels any scheduled trailing action.
    public func cancel() {
        lock.lock()
        defer { lock.unlock() }
        pendingTask?.cancel()
        pendingTask = nil
    }
}
