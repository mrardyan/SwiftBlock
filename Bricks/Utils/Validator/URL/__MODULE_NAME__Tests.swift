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

    func testValidURLs() {
        XCTAssertTrue(validator.validate("https://example.com"))
        XCTAssertTrue(validator.validate("http://sub.domain.co.id/path?query=1#hash"))
    }

    func testInvalidURLs() {
        XCTAssertFalse(validator.validate(""))
        XCTAssertFalse(validator.validate("not a url"))
        XCTAssertFalse(validator.validate("ftp://example.com"))
    }

    func testSecureOptions() {
        let secureValidator = __MODULE_NAME__(options: .secure)
        XCTAssertTrue(secureValidator.validate("https://example.com"))
        XCTAssertFalse(secureValidator.validate("http://example.com"))
        XCTAssertFalse(secureValidator.validate("https://localhost"))
    }
}
