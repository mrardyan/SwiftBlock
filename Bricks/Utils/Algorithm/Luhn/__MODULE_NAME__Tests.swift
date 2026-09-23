import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testValidCardNumbers() {
        // Standard test card numbers (Luhn valid)
        XCTAssertTrue(__MODULE_NAME__.validate("49927398716"))
        XCTAssertTrue(__MODULE_NAME__.validate("79927398713"))
        XCTAssertTrue(__MODULE_NAME__.validate("4992-7398-716")) // Handles formatting hyphens/spaces
    }

    func testInvalidCardNumbers() {
        XCTAssertFalse(__MODULE_NAME__.validate("49927398717"))
        XCTAssertFalse(__MODULE_NAME__.validate("1234567812345670"))
        XCTAssertFalse(__MODULE_NAME__.validate("1")) // Too short
    }

    func testCheckDigitComputation() {
        XCTAssertEqual(__MODULE_NAME__.computeCheckDigit(for: "7992739871"), 3)
        XCTAssertEqual(__MODULE_NAME__.computeCheckDigit(for: "4992739871"), 6)
    }
}
