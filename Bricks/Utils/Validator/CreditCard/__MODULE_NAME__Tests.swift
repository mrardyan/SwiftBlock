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

    func testLuhnAlgorithm() {
        XCTAssertTrue(validator.validateNumber("49927398716"))
        XCTAssertTrue(validator.validateNumber("4532015112830366"))
        XCTAssertFalse(validator.validateNumber("49927398717"))
    }

    func testBrandDetection() {
        XCTAssertEqual(validator.detectBrand("4111111111111111"), .visa)
        XCTAssertEqual(validator.detectBrand("378282246310005"), .amex)
        XCTAssertEqual(validator.detectBrand("5500000000000004"), .mastercard)
    }

    func testCVVValidation() {
        XCTAssertTrue(validator.validateCVV("123", brand: .visa))
        XCTAssertTrue(validator.validateCVV("1234", brand: .amex))
        XCTAssertFalse(validator.validateCVV("12", brand: .visa))
    }
}
