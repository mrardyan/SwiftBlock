import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testDistanceConversionsAndFormatting() throws {
        let d = try __MODULE_NAME__(meters: 2500)
        XCTAssertEqual(d.meters, 2500)
        XCTAssertEqual(d.kilometers, 2.5)
        XCTAssertEqual(d.formatted(locale: Locale(identifier: "en_US")), "2.50 km")
        XCTAssertFalse(d.formatted.isEmpty)

        let dMeters = try __MODULE_NAME__(meters: 450)
        XCTAssertEqual(dMeters.formatted(locale: Locale(identifier: "en_US")), "450 m")
    }

    func testNegativeDistanceThrows() {
        XCTAssertThrowsError(try __MODULE_NAME__(meters: -100)) { error in
            XCTAssertEqual(error as? DistanceError, DistanceError.negativeDistance(-100))
        }
    }

    func testLiteralsAndAddition() {
        let d1: __MODULE_NAME__ = 500
        let d2: __MODULE_NAME__ = 1500.0

        let sum = d1 + d2
        XCTAssertEqual(sum.meters, 2000.0)
        XCTAssertEqual(sum.kilometers, 2.0)
    }
}
