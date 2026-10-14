import Foundation

/// Main orchestrator that coordinates application initialization across structured concurrent task groups.
public final class __MODULE_NAME__: Sendable {
    public static let shared = __MODULE_NAME__()

    public let container: DependencyContainerProtocol
    private let registeredTasks: [@Sendable () -> [any InitializableTask]]

    public init(
        container: DependencyContainerProtocol = AppDependencyContainer.shared,
        tasks: [any InitializableTask] = []
    ) {
        self.container = container
        self.registeredTasks = [{ tasks }]
    }

    /// Factory with builder closure for dynamic task registration.
    public init(
        container: DependencyContainerProtocol = AppDependencyContainer.shared,
        @LaunchTaskBuilder builder: @escaping @Sendable () -> [any InitializableTask]
    ) {
        self.container = container
        self.registeredTasks = [builder]
    }

    /// Executes the multi-phase launch pipeline.
    @discardableResult
    public func launch(
        onPhaseComplete: (@Sendable (LaunchPhase, [TaskLaunchResult]) -> Void)? = nil
    ) async throws -> [TaskLaunchResult] {
        let allTasks = registeredTasks.flatMap { $0() }
        let tasksByPhase = Dictionary(grouping: allTasks, by: { $0.phase })
        let sortedPhases = LaunchPhase.allCases.sorted()

        var overallResults: [TaskLaunchResult] = []

        for phase in sortedPhases {
            guard let phaseTasks = tasksByPhase[phase], !phaseTasks.isEmpty else {
                continue
            }

            let phaseResults = try await executePhase(phase, tasks: phaseTasks)
            overallResults.append(contentsOf: phaseResults)
            onPhaseComplete?(phase, phaseResults)
        }

        return overallResults
    }

    // MARK: - Private Concurrent Phase Execution

    private func executePhase(
        _ phase: LaunchPhase,
        tasks: [any InitializableTask]
    ) async throws -> [TaskLaunchResult] {
        try await withThrowingTaskGroup(of: TaskLaunchResult.self) { group in
            for task in tasks {
                group.addTask(priority: task.priority) {
                    let startTime = CFAbsoluteTimeGetCurrent()
                    do {
                        if let timeout = task.timeoutInterval {
                            try await withThrowingTimeout(seconds: timeout) {
                                try await task.initialize(container: self.container)
                            }
                        } else {
                            try await task.initialize(container: self.container)
                        }
                        let duration = CFAbsoluteTimeGetCurrent() - startTime
                        return TaskLaunchResult(
                            taskId: task.id,
                            phase: phase,
                            duration: duration,
                            isSuccess: true
                        )
                    } catch {
                        let duration = CFAbsoluteTimeGetCurrent() - startTime
                        if task.isBlocking {
                            throw error
                        }
                        return TaskLaunchResult(
                            taskId: task.id,
                            phase: phase,
                            duration: duration,
                            isSuccess: false,
                            error: error
                        )
                    }
                }
            }

            var results: [TaskLaunchResult] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }
}

// MARK: - Result Builder for Tasks

@resultBuilder
public struct LaunchTaskBuilder {
    public static func buildBlock(_ components: [any InitializableTask]...) -> [any InitializableTask] {
        components.flatMap { $0 }
    }

    public static func buildExpression(_ expression: any InitializableTask) -> [any InitializableTask] {
        [expression]
    }

    public static func buildExpression(_ expressions: [any InitializableTask]) -> [any InitializableTask] {
        expressions
    }

    public static func buildOptional(_ component: [any InitializableTask]?) -> [any InitializableTask] {
        component ?? []
    }

    public static func buildEither(first component: [any InitializableTask]) -> [any InitializableTask] {
        component
    }

    public static func buildEither(second component: [any InitializableTask]) -> [any InitializableTask] {
        component
    }
}

// MARK: - Timeout Helper

private enum LaunchTimeoutError: Error, LocalizedError {
    case timedOut

    var errorDescription: String? {
        "The startup task timed out before completion."
    }
}

private func withThrowingTimeout<T: Sendable>(
    seconds: TimeInterval,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        group.addTask {
            let nanoseconds = UInt64(seconds * 1_000_000_000)
            try await Task.sleep(nanoseconds: nanoseconds)
            throw LaunchTimeoutError.timedOut
        }

        guard let firstCompleted = try await group.next() else {
            throw LaunchTimeoutError.timedOut
        }
        group.cancelAll()
        return firstCompleted
    }
}
