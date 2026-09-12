import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testPointInitializationAndFormatting() throws {
        let pts = try __MODULE_NAME__(value: 1500)
        XCTAssertEqual(pts.rawValue, 1500)
        XCTAssertTrue(pts.formatted.contains("pts"))
    }

    func testNegativeBalanceThrows() {
        XCTAssertThrowsError(try __MODULE_NAME__(value: -50)) { error in
            XCTAssertEqual(error as? PointError, PointError.negativeBalance(-50))
        }
    }

    func testIntegerLiteralAndArithmetic() throws {
        let p1: __MODULE_NAME__ = 100
        let p2: __MODULE_NAME__ = 50

        let sum = p1 + p2
        XCTAssertEqual(sum.rawValue, 150)

        let diff = try p1 - p2
        XCTAssertEqual(diff.rawValue, 50)
    }
}
