import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    private var formatter: __MODULE_NAME__!

    override func setUp() {
        super.setUp()
        formatter = __MODULE_NAME__()
    }

    override func tearDown() {
        formatter = nil
        super.tearDown()
    }

    func testCurrencyFormatting() {
        let resultUSD = formatter.string(from: 1234.56, code: "USD", locale: Locale(identifier: "en_US"))
        XCTAssertNotNil(resultUSD)
        XCTAssertTrue(resultUSD?.contains("1,234.56") == true || resultUSD?.contains("1.234,56") == true)
    }

    func testDecimalFormatting() {
        let decimalVal = Decimal(string: "99.99")!
        let result = formatter.string(from: decimalVal, code: "USD", locale: Locale(identifier: "en_US"))
        XCTAssertNotNil(result)
    }
}
