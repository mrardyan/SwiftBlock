import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testExchangeRateConversionAndFormatting() throws {
        let fx = try __MODULE_NAME__(base: "USD", target: "IDR", rate: 15500)
        XCTAssertEqual(fx.convert(100), 1550000)
        XCTAssertEqual(fx.formatted(locale: Locale(identifier: "en_US")), "1 USD = 15,500 IDR")
    }

    func testInvalidRateThrows() {
        XCTAssertThrowsError(try __MODULE_NAME__(base: "USD", target: "IDR", rate: -10)) { error in
            XCTAssertEqual(error as? ExchangeRateError, ExchangeRateError.invalidRate(-10))
        }
    }
}
