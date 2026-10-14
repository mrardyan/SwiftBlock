import Foundation

/// Thread-safe throttler enforcing a maximum execution frequency.
///
/// Executes the first call immediately (leading edge) and suppresses subsequent calls
/// until the interval has elapsed, optionally running the trailing call.
public final class __MODULE_NAME__: @unchecked Sendable {
    private let interval: TimeInterval
    private let latestOnly: Bool
    private var lastExecutionUptime: TimeInterval?
    private var pendingTask: Task<Void, Never>?
    private let lock = NSLock()

    /// Creates a new Throttle instance.
    /// - Parameters:
    ///   - interval: Minimum time between executions in seconds.
    ///   - latestOnly: If true, schedules the most recent suppressed call to execute when the interval expires.
    public init(interval: TimeInterval, latestOnly: Bool = true) {
        self.interval = max(0, interval)
        self.latestOnly = latestOnly
    }

    /// Triggers the throttled action.
    public func call(action: @escaping @Sendable () async -> Void) {
        lock.lock()
        defer { lock.unlock() }

        let now = ProcessInfo.processInfo.systemUptime
        let elapsed = lastExecutionUptime.map { now - $0 } ?? interval

        if elapsed >= interval {
            lastExecutionUptime = now
            pendingTask?.cancel()
            pendingTask = nil
            Task {
                await action()
            }
        } else if latestOnly {
            pendingTask?.cancel()
            let remaining = max(0, interval - elapsed)
            let remainingNanos = UInt64(remaining * 1_000_000_000)

            pendingTask = Task {
                do {
                    try await Task.sleep(nanoseconds: remainingNanos)
                    guard !Task.isCancelled else { return }
                    self.updateLastExecutionUptime(ProcessInfo.processInfo.systemUptime)
                    await action()
                } catch {
                    // Cancelled
                }
            }
        }
    }

    /// Synchronous variant of `call`.
    public func call(action: @escaping @Sendable () -> Void) {
        call { () async in
            action()
        }
    }

    private func updateLastExecutionUptime(_ uptime: TimeInterval) {
        lock.lock()
        defer { lock.unlock() }
        lastExecutionUptime = uptime
    }

    /// Cancels any scheduled trailing action.
    public func cancel() {
        lock.lock()
        defer { lock.unlock() }
        pendingTask?.cancel()
        pendingTask = nil
    }
}
