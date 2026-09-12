import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testTimeSlotDurationAndContains() throws {
        let start = Date(timeIntervalSince1970: 1000)
        let end = Date(timeIntervalSince1970: 4600) // 1 hour later
        let slot = try __MODULE_NAME__(start: start, end: end)

        XCTAssertEqual(slot.durationMinutes, 60.0)
        XCTAssertTrue(slot.contains(Date(timeIntervalSince1970: 2000)))
        XCTAssertFalse(slot.contains(Date(timeIntervalSince1970: 5000)))
    }

    func testOverlapDetection() throws {
        let slot1 = try __MODULE_NAME__(start: Date(timeIntervalSince1970: 0), end: Date(timeIntervalSince1970: 3600))
        let slot2 = try __MODULE_NAME__(start: Date(timeIntervalSince1970: 1800), end: Date(timeIntervalSince1970: 5400))
        let slot3 = try __MODULE_NAME__(start: Date(timeIntervalSince1970: 3600), end: Date(timeIntervalSince1970: 7200))

        XCTAssertTrue(slot1.overlaps(with: slot2))
        XCTAssertFalse(slot1.overlaps(with: slot3))
    }

    func testEndBeforeStartThrows() {
        let later = Date(timeIntervalSince1970: 1000)
        let earlier = Date(timeIntervalSince1970: 500)
        XCTAssertThrowsError(try __MODULE_NAME__(start: later, end: earlier))
    }
}
