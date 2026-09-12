import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testSpeedConversionsAndFormatting() throws {
        let spd: __MODULE_NAME__ = 100
        XCTAssertEqual(spd.kilometersPerHour, 100.0)
        XCTAssertEqual(spd.formatted(locale: Locale(identifier: "en_US")), "100 km/h")
    }

    func testNegativeSpeedThrows() {
        XCTAssertThrowsError(try __MODULE_NAME__(kilometersPerHour: -20)) { error in
            XCTAssertEqual(error as? SpeedError, SpeedError.negativeSpeed(-20))
        }
    }
}
