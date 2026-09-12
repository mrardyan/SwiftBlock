import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testBatteryLevelAndLowBatteryFlag() throws {
        let bat: __MODULE_NAME__ = 15 // 15%
        XCTAssertEqual(bat.percentage, 15)
        XCTAssertTrue(bat.isLowBattery)
        XCTAssertEqual(bat.formatted, "15%")
    }

    func testInvalidBatteryLevelThrowsWithoutClamping() {
        XCTAssertThrowsError(try __MODULE_NAME__(level: 1.5, clamped: false)) { error in
            XCTAssertEqual(error as? BatteryLevelError, BatteryLevelError.invalidPercentage(1.5))
        }
    }
}
