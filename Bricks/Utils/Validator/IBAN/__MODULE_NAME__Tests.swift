import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testValidIBANs() {
        let validator = __MODULE_NAME__()

        // Valid German IBAN
        XCTAssertTrue(validator.isValid("DE89 3704 0044 0532 0130 00"))
        // Valid UK IBAN
        XCTAssertTrue(validator.isValid("GB82 WEST 1234 5698 7654 32"))
    }

    func testInvalidIBANs() {
        let validator = __MODULE_NAME__()

        XCTAssertFalse(validator.isValid(""))
        XCTAssertFalse(validator.isValid("DE89 3704 0044 0532 0130 01")) // Invalid check digit
        XCTAssertFalse(validator.isValid("123456789012345")) // Invalid country code
    }
}
