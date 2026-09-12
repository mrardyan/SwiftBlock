import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testHeartRateZonesAndFormatting() throws {
        let hr: __MODULE_NAME__ = 145
        XCTAssertEqual(hr.bpm, 145)
        XCTAssertEqual(hr.formatted(locale: Locale(identifier: "en_US")), "145 BPM")
        XCTAssertEqual(hr.zone(age: 30), CardiacZone.cardio)
    }

    func testInvalidBPMThrows() {
        XCTAssertThrowsError(try __MODULE_NAME__(bpm: 10)) { error in
            XCTAssertEqual(error as? HeartRateError, HeartRateError.invalidBPM(10))
        }
    }
}
