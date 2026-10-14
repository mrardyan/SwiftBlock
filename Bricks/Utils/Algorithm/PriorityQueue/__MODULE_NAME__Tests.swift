import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testMinHeapOrdering() {
        var queue = __MODULE_NAME__<Int>.minHeap()

        queue.enqueue(10)
        queue.enqueue(4)
        queue.enqueue(15)
        queue.enqueue(1)

        XCTAssertEqual(queue.count, 4)
        XCTAssertEqual(queue.peek, 1)

        XCTAssertEqual(queue.dequeue(), 1)
        XCTAssertEqual(queue.dequeue(), 4)
        XCTAssertEqual(queue.dequeue(), 10)
        XCTAssertEqual(queue.dequeue(), 15)
        XCTAssertNil(queue.dequeue())
        XCTAssertTrue(queue.isEmpty)
    }

    func testMaxHeapOrdering() {
        var queue = __MODULE_NAME__<Int>.maxHeap()

        queue.enqueue(5)
        queue.enqueue(20)
        queue.enqueue(10)

        XCTAssertEqual(queue.peek, 20)
        XCTAssertEqual(queue.dequeue(), 20)
        XCTAssertEqual(queue.dequeue(), 10)
        XCTAssertEqual(queue.dequeue(), 5)
    }
}
