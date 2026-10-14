import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testDebounceExecutesOnlyLastCall() async {
        let debouncer = __MODULE_NAME__(delay: 0.05)
        let expectation = expectation(description: "Debounced action executed")

        final class Counter: @unchecked Sendable {
            var value = 0
        }
        let counter = Counter()

        debouncer.call {
            counter.value += 1
        }
        debouncer.call {
            counter.value += 1
        }
        debouncer.call {
            counter.value += 1
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(counter.value, 1)
    }

    func testDebounceCancelPreventsExecution() async {
        let debouncer = __MODULE_NAME__(delay: 0.1)

        final class Flag: @unchecked Sendable {
            var executed = false
        }
        let flag = Flag()

        debouncer.call {
            flag.executed = true
        }
        debouncer.cancel()

        try? await Task.sleep(nanoseconds: 150_000_000)
        XCTAssertFalse(flag.executed)
    }
}
