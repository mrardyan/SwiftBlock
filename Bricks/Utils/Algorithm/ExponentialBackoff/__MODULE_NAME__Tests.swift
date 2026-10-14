import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testDeterministicBackoffWithoutJitter() {
        let backoff = __MODULE_NAME__(baseDelay: 1.0, maxDelay: 10.0, multiplier: 2.0, jitter: .none)

        XCTAssertEqual(backoff.delay(forAttempt: 0), 1.0)
        XCTAssertEqual(backoff.delay(forAttempt: 1), 2.0)
        XCTAssertEqual(backoff.delay(forAttempt: 2), 4.0)
        XCTAssertEqual(backoff.delay(forAttempt: 3), 8.0)
        XCTAssertEqual(backoff.delay(forAttempt: 4), 10.0) // Capped at maxDelay
    }

    func testFullJitterRange() {
        let backoff = __MODULE_NAME__(baseDelay: 2.0, maxDelay: 10.0, multiplier: 2.0, jitter: .full)

        for _ in 0..<20 {
            let delay = backoff.delay(forAttempt: 1) // max 4.0
            XCTAssertGreaterThanOrEqual(delay, 0.0)
            XCTAssertLessThanOrEqual(delay, 4.0)
        }
    }

    func testAsyncRetrySuccess() async throws {
        let backoff = __MODULE_NAME__(baseDelay: 0.01, maxDelay: 0.05, jitter: .none)
        final class State: @unchecked Sendable {
            var attempts = 0
        }
        let state = State()

        struct DummyError: Error {}

        let result = try await backoff.retry(maxAttempts: 3) {
            state.attempts += 1
            if state.attempts < 2 {
                throw DummyError()
            }
            return "success"
        }

        XCTAssertEqual(result, "success")
        XCTAssertEqual(state.attempts, 2)
    }
}
