import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testDequePushAndPopOperations() {
        var deque = __MODULE_NAME__<Int>()

        deque.append(10)
        deque.append(20)
        deque.prepend(5)
        deque.prepend(1)

        // Order: [1, 5, 10, 20]
        XCTAssertEqual(deque.count, 4)
        XCTAssertEqual(deque.first, 1)
        XCTAssertEqual(deque.last, 20)

        XCTAssertEqual(deque.popFirst(), 1)
        XCTAssertEqual(deque.popLast(), 20)
        XCTAssertEqual(deque.popFirst(), 5)
        XCTAssertEqual(deque.popLast(), 10)
        XCTAssertNil(deque.popFirst())
        XCTAssertTrue(deque.isEmpty)
    }

    func testArrayLiteralInitialization() {
        var deque: __MODULE_NAME__<String> = ["alpha", "beta", "gamma"]
        XCTAssertEqual(deque.count, 3)
        XCTAssertEqual(deque.popFirst(), "alpha")
        XCTAssertEqual(deque.popLast(), "gamma")
    }
}
