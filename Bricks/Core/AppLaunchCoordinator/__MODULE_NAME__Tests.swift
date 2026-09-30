import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

private struct MockService: Sendable {
    let name: String
}

private struct MockSuccessfulTask: InitializableTask {
    let id: String
    let phase: LaunchPhase
    let isBlocking: Bool

    func initialize(container: DependencyContainerProtocol) async throws {
        await container.registerSingleton(MockService.self, instance: MockService(name: id))
    }
}

private struct MockFailingTask: InitializableTask {
    let id: String
    let phase: LaunchPhase
    let isBlocking: Bool

    enum MockError: Error {
        case failed
    }

    func initialize(container: DependencyContainerProtocol) async throws {
        throw MockError.failed
    }
}

final class __MODULE_NAME__Tests: XCTestCase {
    func testDependencyContainerRegistrationAndResolution() async {
        let container = AppDependencyContainer()
        await container.registerSingleton(MockService.self, instance: MockService(name: "DatabaseService"))

        let resolved = await container.resolve(MockService.self)
        XCTAssertNotNil(resolved)
        XCTAssertEqual(resolved?.name, "DatabaseService")
    }

    func testMultiPhaseLaunchPipeline() async throws {
        let container = AppDependencyContainer()
        let coordinator = __MODULE_NAME__(
            container: container,
            tasks: [
                MockSuccessfulTask(id: "task.core", phase: .core, isBlocking: true),
                MockSuccessfulTask(id: "task.services", phase: .services, isBlocking: false)
            ]
        )

        var completedPhases: [LaunchPhase] = []
        let results = try await coordinator.launch { phase, _ in
            completedPhases.append(phase)
        }

        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.isSuccess })
        XCTAssertEqual(completedPhases, [.core, .services])
    }

    func testNonBlockingTaskFailureResilience() async throws {
        let coordinator = __MODULE_NAME__(
            tasks: [
                MockFailingTask(id: "task.analytics.optional", phase: .deferred, isBlocking: false),
                MockSuccessfulTask(id: "task.logger", phase: .core, isBlocking: true)
            ]
        )

        let results = try await coordinator.launch()
        XCTAssertEqual(results.count, 2)

        let failingResult = results.first(where: { $0.taskId == "task.analytics.optional" })
        XCTAssertFalse(failingResult?.isSuccess ?? true)
        XCTAssertNotNil(failingResult?.error)
    }

    func testBlockingTaskAbortsPipeline() async {
        let coordinator = __MODULE_NAME__(
            tasks: [
                MockFailingTask(id: "task.critical.security", phase: .core, isBlocking: true)
            ]
        )

        do {
            _ = try await coordinator.launch()
            XCTFail("Expected launch to throw on blocking task failure")
        } catch {
            XCTAssertTrue(true)
        }
    }
}
