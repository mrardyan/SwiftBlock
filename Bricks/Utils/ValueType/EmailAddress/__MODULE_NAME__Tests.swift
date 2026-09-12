import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testValidEmailAddress() throws {
        let email = try __MODULE_NAME__("User.Name@Example.COM")
        XCTAssertEqual(email.rawValue, "user.name@example.com")
        XCTAssertEqual(email.username, "user.name")
        XCTAssertEqual(email.domain, "example.com")
        XCTAssertEqual(email.description, "user.name@example.com")
    }

    func testInvalidEmailAddressThrows() {
        XCTAssertThrowsError(try __MODULE_NAME__("invalid-email")) { error in
            XCTAssertEqual(error as? EmailAddressError, EmailAddressError.invalidFormat("invalid-email"))
        }
    }

    func testFailableRawRepresentableInit() {
        XCTAssertNil(__MODULE_NAME__(rawValue: "not_an_email"))
        XCTAssertNotNil(__MODULE_NAME__(rawValue: "test@domain.org"))
    }
}
