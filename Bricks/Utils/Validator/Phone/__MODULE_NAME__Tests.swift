import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

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

    func testValidPhoneNumbers() {
        XCTAssertTrue(validator.validate("+14155552671"))
        XCTAssertTrue(validator.validate("+62 812 3456 7890"))
        XCTAssertTrue(validator.validate("081234567890"))
    }

    func testInvalidPhoneNumbers() {
        XCTAssertFalse(validator.validate(""))
        XCTAssertFalse(validator.validate("abc"))
        XCTAssertFalse(validator.validate("123"))
    }
}
