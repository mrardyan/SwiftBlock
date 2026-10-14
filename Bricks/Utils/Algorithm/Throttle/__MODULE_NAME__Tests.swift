import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testThrottleExecutesLeadingCallImmediately() async {
        let throttler = __MODULE_NAME__(interval: 0.1, latestOnly: false)
        let expectation = expectation(description: "Leading execution")

        final class Counter: @unchecked Sendable {
            var value = 0
        }
        let counter = Counter()

        throttler.call {
            counter.value += 1
            expectation.fulfill()
        }

        // Second call should be ignored because latestOnly is false
        throttler.call {
            counter.value += 1
        }

        await fulfillment(of: [expectation], timeout: 1.0)
        try? await Task.sleep(nanoseconds: 120_000_000)
        XCTAssertEqual(counter.value, 1)
    }

    func testThrottleExecutesTrailingCallWhenEnabled() async {
        let throttler = __MODULE_NAME__(interval: 0.05, latestOnly: true)
        let expectation = expectation(description: "Trailing execution")

        final class Counter: @unchecked Sendable {
            var value = 0
        }
        let counter = Counter()

        throttler.call {
            counter.value += 1
        }

        throttler.call {
            counter.value += 1
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(counter.value, 2)
    }
}
