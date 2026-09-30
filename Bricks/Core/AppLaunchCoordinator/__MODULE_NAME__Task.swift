import Foundation

/// Defines the sequential phases during application startup.
public enum LaunchPhase: Int, Comparable, CaseIterable, Sendable {
    /// Phase 0: Immediate synchronous and critical foundation (Logging, Crash reporting).
    case core = 0
    /// Phase 1: Local storage, Security, Keychain, and local database setup.
    case infrastructure = 1
    /// Phase 2: Remote configuration, Auth session restoration, and Network transport.
    case services = 2
    /// Phase 3: Deferred tasks (Analytics setup, cache warming, background sync).
    case deferred = 3

    public static func < (lhs: LaunchPhase, rhs: LaunchPhase) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Represents the execution outcome of an initialization task.
public struct TaskLaunchResult: Sendable {
    public let taskId: String
    public let phase: LaunchPhase
    public let duration: TimeInterval
    public let isSuccess: Bool
    public let error: (any Error)?

    public init(
        taskId: String,
        phase: LaunchPhase,
        duration: TimeInterval,
        isSuccess: Bool,
        error: (any Error)? = nil
    ) {
        self.taskId = taskId
        self.phase = phase
        self.duration = duration
        self.isSuccess = isSuccess
        self.error = error
    }
}

/// Protocol that every modular initialization task must conform to.
public protocol InitializableTask: Sendable {
    /// Unique identifier of the task (e.g. "com.app.logger.init").
    var id: String { get }

    /// Launch phase in which this task should execute.
    var phase: LaunchPhase { get }

    /// Concurrency task priority.
    var priority: TaskPriority { get }

    /// Whether failure of this task should abort the remaining startup sequence.
    var isBlocking: Bool { get }

    /// Optional task execution timeout in seconds (default: nil / no timeout).
    var timeoutInterval: TimeInterval? { get }

    /// Executes the task asynchronously.
    func initialize(container: DependencyContainerProtocol) async throws
}

public extension InitializableTask {
    var priority: TaskPriority { .medium }
    var isBlocking: Bool { false }
    var timeoutInterval: TimeInterval? { nil }
}

/// Closure-based lightweight implementation of InitializableTask.
public struct BlockLaunchTask: InitializableTask {
    public let id: String
    public let phase: LaunchPhase
    public let priority: TaskPriority
    public let isBlocking: Bool
    public let timeoutInterval: TimeInterval?
    private let block: @Sendable (DependencyContainerProtocol) async throws -> Void

    public init(
        id: String,
        phase: LaunchPhase = .services,
        priority: TaskPriority = .medium,
        isBlocking: Bool = false,
        timeoutInterval: TimeInterval? = nil,
        block: @Sendable @escaping (DependencyContainerProtocol) async throws -> Void
    ) {
        self.id = id
        self.phase = phase
        self.priority = priority
        self.isBlocking = isBlocking
        self.timeoutInterval = timeoutInterval
        self.block = block
    }

    public func initialize(container: DependencyContainerProtocol) async throws {
        try await block(container)
    }
}
