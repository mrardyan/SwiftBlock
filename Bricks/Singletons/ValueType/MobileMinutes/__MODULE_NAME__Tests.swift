import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testMobileMinutesFormattingAndAddition() throws {
        let m = try __MODULE_NAME__(minutes: 100)
        XCTAssertEqual(m.minutes, 100)
        XCTAssertEqual(m.formatted, "100 Mins")

        let m1: __MODULE_NAME__ = 50
        let m2: __MODULE_NAME__ = 30
        let sum = m1 + m2
        XCTAssertEqual(sum.minutes, 80)
    }

    func testNegativeMinutesThrows() {
        XCTAssertThrowsError(try __MODULE_NAME__(minutes: -10)) { error in
            XCTAssertEqual(error as? MobileMinutesError, MobileMinutesError.negativeMinutes(-10))
        }
    }

    func testAirtimeMinutesTypealiasCompatibility() {
        let airtime: AirtimeMinutes = 60
        XCTAssertEqual(airtime.minutes, 60)
    }
}
