import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    struct MockUseCase: __MODULE_NAME__ {
        typealias Input = Int
        typealias Output = String

        let failAttempts: Int
        final class Counter: @unchecked Sendable {
            var calls = 0
        }
        let counter = Counter()

        func execute(_ input: Int) async throws -> String {
            counter.calls += 1
            if counter.calls <= failAttempts {
                throw NSError(domain: "test", code: 500)
            }
            return "Success: \(input)"
        }
    }

    func testUseCaseRetryDecorator() async throws {
        let mock = MockUseCase(failAttempts: 2)
        let composable = mock.withRetry(maxAttempts: 3)

        let result = try await composable.execute(42)
        XCTAssertEqual(result, "Success: 42")
        XCTAssertEqual(mock.counter.calls, 3)
    }

    func testUseCaseTimingDecorator() async throws {
        let mock = MockUseCase(failAttempts: 0)
        let expectation = expectation(description: "Timing captured")

        let timed = mock.withTiming { duration, result in
            XCTAssertGreaterThanOrEqual(duration, 0)
            if case .success(let val) = result {
                XCTAssertEqual(val, "Success: 99")
                expectation.fulfill()
            }
        }

        _ = try await timed.execute(99)
        await fulfillment(of: [expectation], timeout: 1.0)
    }
}
