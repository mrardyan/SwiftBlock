import XCTest
@testable import __PROJECT_NAME__

final class __MODULE_NAME__ValidatorTests: XCTestCase {
    func testValidatorValidation() {
        let validator = Default__MODULE_NAME__Validator()
        XCTAssertTrue(validator.validate("valid_input"))
        XCTAssertFalse(validator.validate(""))
    }
}
