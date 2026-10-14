import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testQueueFIFOBehavior() {
        var queue = __MODULE_NAME__<Int>()

        queue.enqueue(1)
        queue.enqueue(2)
        queue.enqueue(3)

        XCTAssertEqual(queue.count, 3)
        XCTAssertEqual(queue.peek, 1)

        XCTAssertEqual(queue.dequeue(), 1)
        XCTAssertEqual(queue.dequeue(), 2)

        queue.enqueue(4)
        XCTAssertEqual(queue.dequeue(), 3)
        XCTAssertEqual(queue.dequeue(), 4)
        XCTAssertNil(queue.dequeue())
        XCTAssertTrue(queue.isEmpty)
    }
}
