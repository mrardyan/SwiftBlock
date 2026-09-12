import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testLicensePlateFormattingAndValidation() throws {
        let plate: __MODULE_NAME__ = "b 1234 abc"
        XCTAssertEqual(plate.plateNumber, "B 1234 ABC")
        XCTAssertEqual(plate.formatted, "B 1234 ABC")
    }

    func testInvalidLengthThrows() {
        XCTAssertThrowsError(try __MODULE_NAME__(plateNumber: "A")) { error in
            XCTAssertEqual(error as? LicensePlateError, LicensePlateError.invalidLength("A"))
        }
    }
}
