import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testValidPhoneNumber() throws {
        let phone = try __MODULE_NAME__("+62 812 3456 7890")
        XCTAssertEqual(phone.rawValue, "+6281234567890")
        XCTAssertEqual(phone.e164Formatted, "+6281234567890")
    }

    func testInvalidPhoneNumberThrows() {
        XCTAssertThrowsError(try __MODULE_NAME__("123")) { error in
            XCTAssertEqual(error as? PhoneNumberError, PhoneNumberError.invalidFormat("123"))
        }
    }
}
