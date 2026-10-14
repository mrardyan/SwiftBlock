import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testOrderedSetDeduplicationAndOrder() {
        var set: __MODULE_NAME__<Int> = [5, 3, 1, 3, 5, 2]

        XCTAssertEqual(set.count, 4)
        XCTAssertEqual(set.elements, [5, 3, 1, 2])
        XCTAssertTrue(set.contains(3))
        XCTAssertFalse(set.contains(99))

        set.append(10)
        XCTAssertEqual(set.elements, [5, 3, 1, 2, 10])

        set.remove(1)
        XCTAssertEqual(set.elements, [5, 3, 2, 10])
    }
}
