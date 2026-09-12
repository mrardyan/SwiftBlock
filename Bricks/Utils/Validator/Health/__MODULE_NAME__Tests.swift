import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    private var validator: __MODULE_NAME__!

    override func setUp() {
        super.setUp()
        validator = __MODULE_NAME__()
    }

    override func tearDown() {
        validator = nil
        super.tearDown()
    }

    func testHeartRateValidation() {
        XCTAssertTrue(validator.validateHeartRate(72))
        XCTAssertFalse(validator.validateHeartRate(15))
        XCTAssertFalse(validator.validateHeartRate(250))
    }

    func testBloodPressureValidation() {
        XCTAssertTrue(validator.validateBloodPressure(systolic: 120, diastolic: 80))
        XCTAssertFalse(validator.validateBloodPressure(systolic: 80, diastolic: 120))
        XCTAssertFalse(validator.validateBloodPressure(systolic: 300, diastolic: 80))
    }

    func testBodyTemperatureValidation() {
        XCTAssertTrue(validator.validateBodyTemperature(celsius: 36.6))
        XCTAssertFalse(validator.validateBodyTemperature(celsius: 32.0))
        XCTAssertFalse(validator.validateBodyTemperature(celsius: 44.0))
    }

    func testBMIAndGlucose() {
        XCTAssertTrue(validator.validateBMI(22.5))
        XCTAssertFalse(validator.validateBMI(5.0))

        XCTAssertTrue(validator.validateBloodGlucose(100.0))
        XCTAssertFalse(validator.validateBloodGlucose(5.0))
    }
}
