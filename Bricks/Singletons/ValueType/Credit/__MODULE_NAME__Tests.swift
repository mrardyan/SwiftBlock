import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testCreditInitializationAndFormatting() throws {
        let c = try __MODULE_NAME__(amount: 250.50)
        XCTAssertEqual(c.amount, 250.50)
        XCTAssertTrue(c.formatted.contains("Credits"))
    }

    func testNegativeAmountThrows() {
        XCTAssertThrowsError(try __MODULE_NAME__(amount: -10)) { error in
            XCTAssertEqual(error as? CreditError, CreditError.negativeAmount(-10))
        }
    }

    func testDeductCredit() throws {
        let credit = try __MODULE_NAME__(amount: 100)
        let remaining = try credit.deduct(40)
        XCTAssertEqual(remaining.amount, 60)

        XCTAssertThrowsError(try credit.deduct(150)) { error in
            XCTAssertEqual(error as? CreditError, CreditError.insufficientCredit(requested: 150, available: 100))
        }
    }
}
