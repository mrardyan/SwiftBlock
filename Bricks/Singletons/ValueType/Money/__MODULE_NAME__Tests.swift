import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testMoneyInitializationAndFormatting() {
        let money = __MODULE_NAME__(amount: 150000, currency: "IDR")
        XCTAssertEqual(money.amount, 150000)
        XCTAssertEqual(money.currency, "IDR")
        XCTAssertFalse(money.formatted.isEmpty)
    }

    func testMoneyArithmetic() throws {
        let m1 = __MODULE_NAME__(amount: 50, currency: "USD")
        let m2 = __MODULE_NAME__(amount: 25, currency: "USD")

        let sum = try m1 + m2
        XCTAssertEqual(sum.amount, 75)
        XCTAssertEqual(sum.currency, "USD")

        let diff = try m1 - m2
        XCTAssertEqual(diff.amount, 25)

        let product = m1 * 3
        XCTAssertEqual(product.amount, 150)
    }

    func testCurrencyMismatchThrows() {
        let usd = __MODULE_NAME__(amount: 10, currency: "USD")
        let idr = __MODULE_NAME__(amount: 10000, currency: "IDR")

        XCTAssertThrowsError(try usd + idr) { error in
            XCTAssertEqual(error as? MoneyError, MoneyError.currencyMismatch(lhs: "USD", rhs: "IDR"))
        }
    }
}
