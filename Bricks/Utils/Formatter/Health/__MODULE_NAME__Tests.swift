import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    private var formatter: __MODULE_NAME__!

    override func setUp() {
        super.setUp()
        formatter = __MODULE_NAME__()
    }

    override func tearDown() {
        formatter = nil
        super.tearDown()
    }

    func testFormatSteps() {
        let result = formatter.formatSteps(10452, locale: Locale(identifier: "en_US"))
        XCTAssertTrue(result.contains("10,452"))
        XCTAssertTrue(result.contains("steps"))
    }

    func testFormatEnergy() {
        let result = formatter.formatEnergy(calories: 500, locale: Locale(identifier: "en_US"))
        XCTAssertFalse(result.isEmpty)
    }

    func testFormatDistance() {
        let result = formatter.formatDistance(meters: 5000, locale: Locale(identifier: "en_US"))
        XCTAssertFalse(result.isEmpty)
    }

    func testFormatWeight() {
        let result = formatter.formatWeight(kilograms: 70, locale: Locale(identifier: "en_US"))
        XCTAssertFalse(result.isEmpty)
    }

    func testFormatHeartRateAndBloodPressure() {
        XCTAssertEqual(formatter.formatHeartRate(72), "72 bpm")
        XCTAssertEqual(formatter.formatBloodPressure(systolic: 120, diastolic: 80), "120/80 mmHg")
    }
}
