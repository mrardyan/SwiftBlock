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

    func testDecimalStyle() {
        let result = formatter.string(from: 1234567, style: .decimal, locale: Locale(identifier: "en_US"))
        XCTAssertEqual(result, "1,234,567")
    }

    func testPercentStyle() {
        let result = formatter.string(from: 0.75, style: .percent, locale: Locale(identifier: "en_US"))
        XCTAssertTrue(result?.contains("75") == true)
    }
}
