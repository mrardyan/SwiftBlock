import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testUnionAndConnected() {
        var uf = __MODULE_NAME__<Int>([1, 2, 3, 4, 5, 6])
        XCTAssertEqual(uf.count, 6)

        // Connect 1-2 and 3-4
        uf.union(1, 2)
        uf.union(3, 4)
        XCTAssertTrue(uf.connected(1, 2))
        XCTAssertTrue(uf.connected(3, 4))
        XCTAssertFalse(uf.connected(1, 3))
        XCTAssertEqual(uf.count, 4)

        // Connect 2-4 (merges {1,2} and {3,4})
        uf.union(2, 4)
        XCTAssertTrue(uf.connected(1, 4))
        XCTAssertTrue(uf.connected(2, 3))
        XCTAssertEqual(uf.count, 3)
    }
}
