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

    func testValidEmails() {
        XCTAssertTrue(validator.validate("user@example.com"))
        XCTAssertTrue(validator.validate("john.doe@domain.co.id"))
        XCTAssertTrue(validator.validate("test+tag@gmail.com"))
    }

    func testInvalidEmails() {
        XCTAssertFalse(validator.validate(""))
        XCTAssertFalse(validator.validate("  "))
        XCTAssertFalse(validator.validate("plainaddress"))
        XCTAssertFalse(validator.validate("@missinguser.com"))
        XCTAssertFalse(validator.validate("user@.com"))
    }

    func testCustomPattern() {
        let strictValidator = __MODULE_NAME__(pattern: "^[a-z]+@example\\.com$", options: [])
        XCTAssertTrue(strictValidator.validate("test@example.com"))
        XCTAssertFalse(strictValidator.validate("test@other.com"))
        XCTAssertFalse(strictValidator.validate("TEST@example.com"))
    }
}
