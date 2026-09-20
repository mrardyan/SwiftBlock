import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

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
