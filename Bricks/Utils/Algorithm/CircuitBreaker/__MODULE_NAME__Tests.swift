import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    struct DummyError: Error {}

    func testCircuitTripsOpenAfterFailures() async {
        let breaker = __MODULE_NAME__(failureThreshold: 2, resetTimeout: 1.0)
        XCTAssertEqual(breaker.currentState, .closed)

        // 1st failure
        do {
            _ = try await breaker.execute { throw DummyError() }
        } catch {}
        XCTAssertEqual(breaker.currentState, .closed)

        // 2nd failure -> should trip to open
        do {
            _ = try await breaker.execute { throw DummyError() }
        } catch {}
        XCTAssertEqual(breaker.currentState, .open)

        // Next call should fail immediately with circuitOpen
        do {
            _ = try await breaker.execute { "value" }
            XCTFail("Should have thrown circuitOpen")
        } catch let err as CircuitBreakerError {
            XCTAssertEqual(err, .circuitOpen)
        } catch {
            XCTFail("Unexpected error")
        }
    }

    func testCircuitTransitionsToHalfOpenAndRecovers() async throws {
        let breaker = __MODULE_NAME__(failureThreshold: 1, resetTimeout: 0.1, halfOpenSuccessThreshold: 1)

        // Trip open
        do {
            _ = try await breaker.execute { throw DummyError() }
        } catch {}
        XCTAssertEqual(breaker.currentState, .open)

        // Wait for reset timeout
        try? await Task.sleep(nanoseconds: 120_000_000)
        XCTAssertEqual(breaker.currentState, .halfOpen)

        // Successful execution restores closed state
        let result = try await breaker.execute { "recovered" }
        XCTAssertEqual(result, "recovered")
        XCTAssertEqual(breaker.currentState, .closed)
    }
}
