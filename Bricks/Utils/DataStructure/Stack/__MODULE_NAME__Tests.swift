import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testStackLIFOBehavior() {
        var stack = __MODULE_NAME__<Int>()

        stack.push(10)
        stack.push(20)
        stack.push(30)

        XCTAssertEqual(stack.count, 3)
        XCTAssertEqual(stack.top, 30)

        XCTAssertEqual(stack.pop(), 30)
        XCTAssertEqual(stack.pop(), 20)
        XCTAssertEqual(stack.pop(), 10)
        XCTAssertNil(stack.pop())
        XCTAssertTrue(stack.isEmpty)
    }

    func testSequenceIterationFromTopToBottom() {
        let stack: __MODULE_NAME__<String> = ["bottom", "middle", "top"]
        let items = Array(stack)
        XCTAssertEqual(items, ["top", "middle", "bottom"])
    }
}
