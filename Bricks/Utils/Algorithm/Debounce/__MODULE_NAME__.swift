import Foundation

/// Thread-safe debouncer using Swift Concurrency (`Task` cancellation).
///
/// Ensures that a block of code is only executed after a specified quiet delay has elapsed
/// since the last time `call` was invoked.
public final class __MODULE_NAME__: @unchecked Sendable {
    private let delay: TimeInterval
    private var currentTask: Task<Void, Never>?
    private let lock = NSLock()

    /// Creates a new Debounce instance with the specified delay in seconds.
    public init(delay: TimeInterval) {
        self.delay = delay
    }

    /// Triggers the debounced action.
    /// Cancels any pending task and starts a new timer for the given action.
    public func call(action: @escaping @Sendable () async -> Void) {
        lock.lock()
        defer { lock.unlock() }

        currentTask?.cancel()
        let delayNanos = UInt64(delay * 1_000_000_000)

        currentTask = Task {
            do {
                try await Task.sleep(nanoseconds: delayNanos)
                guard !Task.isCancelled else { return }
                await action()
            } catch {
                // Task cancelled during sleep
            }
        }
    }

    /// Synchronous variant of `call`.
    public func call(action: @escaping @Sendable () -> Void) {
        call {
            action()
        }
    }

    /// Cancels any scheduled debounced action.
    public func cancel() {
        lock.lock()
        defer { lock.unlock() }
        currentTask?.cancel()
        currentTask = nil
    }
}
