import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testInitialState() {
        let pagination = __MODULE_NAME__(page: 0, pageSize: 20)
        XCTAssertEqual(pagination.page, 0)
        XCTAssertEqual(pagination.pageSize, 20)
        XCTAssertTrue(pagination.hasMore)
    }

    func testNextPageAdvances() {
        let pagination = __MODULE_NAME__(page: 0, pageSize: 10)
        let next = pagination.nextPage
        XCTAssertEqual(next.page, 1)
        XCTAssertEqual(next.pageSize, 10)
    }

    func testApplyWithTotalStopsAtEnd() {
        var pagination = __MODULE_NAME__(page: 0, pageSize: 10)
        pagination.apply(count: 10, total: 10)
        XCTAssertFalse(pagination.hasMore)
        XCTAssertEqual(pagination.total, 10)
    }

    func testApplyWithoutTotalUsesPageFill() {
        var pagination = __MODULE_NAME__(page: 1, pageSize: 10)
        pagination.apply(count: 10) // full page -> assume more
        XCTAssertTrue(pagination.hasMore)

        pagination.apply(count: 3) // partial page -> done
        XCTAssertFalse(pagination.hasMore)
    }
}