import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testCalorieConversionsAndFormatting() throws {
        let cal: __MODULE_NAME__ = 500
        XCTAssertEqual(cal.kilocalories, 500.0)
        XCTAssertEqual(cal.kilojoules, 2092.0)
        XCTAssertEqual(cal.formatted(locale: Locale(identifier: "en_US")), "500 kcal")
    }

    func testNegativeCalorieThrows() {
        XCTAssertThrowsError(try __MODULE_NAME__(kilocalories: -100)) { error in
            XCTAssertEqual(error as? CalorieError, CalorieError.negativeCalorie(-100))
        }
    }
}
