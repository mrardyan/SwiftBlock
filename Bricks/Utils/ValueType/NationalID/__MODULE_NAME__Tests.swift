import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testNationalIDMaskingAndValidation() throws {
        let nik = try __MODULE_NAME__(value: "3171012304950001")
        XCTAssertEqual(nik.value, "3171012304950001")
        XCTAssertEqual(nik.masked, "317101******0001")
    }

    func testInvalidLengthThrows() {
        XCTAssertThrowsError(try __MODULE_NAME__(value: "12345")) { error in
            XCTAssertEqual(error as? NationalIDError, NationalIDError.invalidLength("12345", expected: 16))
        }
    }
}
