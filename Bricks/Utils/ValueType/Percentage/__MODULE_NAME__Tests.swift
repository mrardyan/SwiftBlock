import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testPercentageInitializationAndClamping() {
        let p1 = __MODULE_NAME__(percent: 25)
        XCTAssertEqual(p1.ratio, 0.25)
        XCTAssertEqual(p1.value, 25.0)

        let pClampedHigh = __MODULE_NAME__(ratio: 1.5)
        XCTAssertEqual(pClampedHigh.ratio, 1.0)

        let pClampedLow = __MODULE_NAME__(ratio: -0.5)
        XCTAssertEqual(pClampedLow.ratio, 0.0)
    }

    func testLiteralConformances() {
        let floatP: __MODULE_NAME__ = 0.15
        XCTAssertEqual(floatP.ratio, 0.15)

        let intP: __MODULE_NAME__ = 20
        XCTAssertEqual(intP.value, 20.0)
    }

    func testPercentageOfAmount() {
        let discount: __MODULE_NAME__ = 20 // 20%
        let originalPrice: Double = 100.0
        XCTAssertEqual(discount.of(originalPrice), 20.0)
    }
}
