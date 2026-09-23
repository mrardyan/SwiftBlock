import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testCircularBufferWriteAndRead() {
        var buffer = __MODULE_NAME__<Int>(capacity: 3)

        buffer.write(1)
        buffer.write(2)
        XCTAssertEqual(buffer.count, 2)
        XCTAssertFalse(buffer.isFull)

        XCTAssertEqual(buffer.read(), 1)
        XCTAssertEqual(buffer.count, 1)

        buffer.write(3)
        buffer.write(4)
        XCTAssertTrue(buffer.isFull)

        XCTAssertEqual(buffer.elements, [2, 3, 4])
    }

    func testOverwriteOnOverflow() {
        var buffer = __MODULE_NAME__<String>(capacity: 3)

        buffer.write("A")
        buffer.write("B")
        buffer.write("C")
        XCTAssertTrue(buffer.isFull)

        // Overwrite "A" with "D"
        buffer.write("D")
        XCTAssertEqual(buffer.count, 3)
        XCTAssertEqual(buffer.elements, ["B", "C", "D"])

        // Overwrite "B" with "E"
        buffer.write("E")
        XCTAssertEqual(buffer.elements, ["C", "D", "E"])
        XCTAssertEqual(buffer.read(), "C")
    }
}
