import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testMobileCreditInitializationAndFormatting() throws {
        let credit = try __MODULE_NAME__(amount: 50000, currency: "IDR")
        XCTAssertEqual(credit.amount, 50000)
        XCTAssertFalse(credit.isExpired)
        XCTAssertFalse(credit.formatted.isEmpty)
    }

    func testDeductMobileCredit() throws {
        let credit = try __MODULE_NAME__(amount: 20000)
        let remaining = try credit.deduct(5000)
        XCTAssertEqual(remaining.amount, 15000)

        XCTAssertThrowsError(try credit.deduct(30000)) { error in
            XCTAssertEqual(error as? MobileCreditError, MobileCreditError.insufficientCredit(requested: 30000, available: 20000))
        }
    }

    func testPulsaTypealiasCompatibility() throws {
        let pulsa: Pulsa = try Pulsa(amount: 10000)
        XCTAssertEqual(pulsa.amount, 10000)
    }
}
