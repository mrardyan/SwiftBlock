import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testIndonesiaNPWPFormatting() throws {
        let npwp = try __MODULE_NAME__(value: "012345678901000", format: .indonesia)
        XCTAssertEqual(npwp.digits, "012345678901000")
        XCTAssertEqual(npwp.formatted, "01.234.567.8-901.000")
    }

    func testUSTINFormatting() throws {
        let tin = try __MODULE_NAME__(value: "123-45-6789", format: .unitedStates)
        XCTAssertEqual(tin.digits, "123456789")
        XCTAssertEqual(tin.formatted, "123-45-6789")
    }

    func testInvalidLengthThrows() {
        XCTAssertThrowsError(try __MODULE_NAME__(value: "123", format: .indonesia))
    }
}
