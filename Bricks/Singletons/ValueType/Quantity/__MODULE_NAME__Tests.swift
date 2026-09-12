import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testQuantityValidInitialization() throws {
        let q = try __MODULE_NAME__(value: 5)
        XCTAssertEqual(q.rawValue, 5)
        XCTAssertFalse(q.isZero)
    }

    func testNegativeQuantityThrows() {
        XCTAssertThrowsError(try __MODULE_NAME__(value: -3)) { error in
            XCTAssertEqual(error as? QuantityError, QuantityError.negativeQuantity(-3))
        }
    }

    func testIntegerLiteralClamping() {
        let q: __MODULE_NAME__ = 10
        XCTAssertEqual(q.rawValue, 10)

        let negativeQ: __MODULE_NAME__ = -5
        XCTAssertEqual(negativeQ.rawValue, 0)
        XCTAssertTrue(negativeQ.isZero)
    }

    func testQuantityArithmetic() throws {
        let q1: __MODULE_NAME__ = 5
        let q2: __MODULE_NAME__ = 3

        let sum = q1 + q2
        XCTAssertEqual(sum.rawValue, 8)

        let diff = try q1 - q2
        XCTAssertEqual(diff.rawValue, 2)
    }
}
