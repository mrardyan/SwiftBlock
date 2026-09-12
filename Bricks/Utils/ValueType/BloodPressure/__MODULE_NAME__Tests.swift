import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testBloodPressureCategoryAndFormatting() throws {
        let bp = try __MODULE_NAME__(systolic: 120, diastolic: 80)
        XCTAssertEqual(bp.systolic, 120)
        XCTAssertEqual(bp.diastolic, 80)
        XCTAssertEqual(bp.formatted(locale: Locale(identifier: "en_US")), "120/80 mmHg")
        XCTAssertEqual(bp.category, BloodPressureCategory.hypertensionStage1)
    }

    func testInvalidReadingsThrow() {
        XCTAssertThrowsError(try __MODULE_NAME__(systolic: 70, diastolic: 90)) { error in
            XCTAssertEqual(error as? BloodPressureError, BloodPressureError.invalidReadings(systolic: 70, diastolic: 90))
        }
    }
}
