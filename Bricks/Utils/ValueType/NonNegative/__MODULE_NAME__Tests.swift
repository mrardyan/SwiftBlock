import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testValidNonNegativeInt() throws {
        let val = try NonNegativeInt(value: 42)
        XCTAssertEqual(val.value, 42)
    }

    func testNegativeIntThrows() {
        XCTAssertThrowsError(try NonNegativeInt(value: -10)) { error in
            XCTAssertEqual(error as? NonNegativeError<Int>, NonNegativeError<Int>.valueIsNegative(-10))
        }
    }

    func testClampedInitializer() {
        let clamped = NonNegativeDouble(clamped: -15.5)
        XCTAssertEqual(clamped.value, 0.0)

        let validClamped = NonNegativeDouble(clamped: 25.5)
        XCTAssertEqual(validClamped.value, 25.5)
    }
}
