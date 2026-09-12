import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testDateRangeDaysAndContains() throws {
        let start = Date(timeIntervalSince1970: 0)
        let end = Date(timeIntervalSince1970: 86400 * 3) // 3 days later
        let range = try __MODULE_NAME__(start: start, end: end)

        XCTAssertEqual(range.numberOfDays, 4) // inclusive
        XCTAssertTrue(range.contains(Date(timeIntervalSince1970: 86400)))
        XCTAssertFalse(range.contains(Date(timeIntervalSince1970: 86400 * 5)))
    }

    func testEndBeforeStartThrows() {
        let later = Date(timeIntervalSince1970: 86400)
        let earlier = Date(timeIntervalSince1970: 0)
        XCTAssertThrowsError(try __MODULE_NAME__(start: later, end: earlier))
    }
}
