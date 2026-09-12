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

    func testValidPassword() {
        XCTAssertTrue(validator.validate("P@ssword123"))
        XCTAssertTrue(validator.validateWithDetails("P@ssword123").isEmpty)
    }

    func testWeakPasswordFails() {
        XCTAssertFalse(validator.validate("short"))
        let errors = validator.validateWithDetails("short")
        XCTAssertTrue(errors.contains(.tooShort(minLength: 8)))
        XCTAssertTrue(errors.contains(.missingUppercase))
        XCTAssertTrue(errors.contains(.missingNumber))
    }

    func testCustomRules() {
        let strictValidator = __MODULE_NAME__(minLength: 10, rules: .strict)
        XCTAssertFalse(strictValidator.validate("Password123"))
        XCTAssertTrue(strictValidator.validate("Password123!"))
    }
}
