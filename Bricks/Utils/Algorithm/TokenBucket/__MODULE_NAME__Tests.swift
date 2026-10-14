import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testTokenConsumptionAndExhaustion() {
        let bucket = __MODULE_NAME__(capacity: 3, refillRate: 1)

        XCTAssertTrue(bucket.consume(tokens: 1))
        XCTAssertTrue(bucket.consume(tokens: 2))
        XCTAssertFalse(bucket.consume(tokens: 1)) // Should fail, bucket is empty
    }

    func testTokenRefillOverTime() async {
        let bucket = __MODULE_NAME__(capacity: 2, refillRate: 10) // 10 tokens / sec

        XCTAssertTrue(bucket.consume(tokens: 2))
        XCTAssertFalse(bucket.consume(tokens: 1))

        // Wait 150ms -> should refill at least 1.5 tokens
        try? await Task.sleep(nanoseconds: 150_000_000)
        XCTAssertTrue(bucket.consume(tokens: 1))
    }

    func testReset() {
        let bucket = __MODULE_NAME__(capacity: 5, refillRate: 1)
        _ = bucket.consume(tokens: 5)
        XCTAssertFalse(bucket.consume(tokens: 1))

        bucket.reset()
        XCTAssertTrue(bucket.consume(tokens: 5))
    }
}
