import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testParsingAndComparison() throws {
        let v1 = try __MODULE_NAME__(string: "v1.2.3")
        XCTAssertEqual(v1.major, 1)
        XCTAssertEqual(v1.minor, 2)
        XCTAssertEqual(v1.patch, 3)
        XCTAssertEqual(v1.description, "1.2.3")

        let v2: __MODULE_NAME__ = "2.0.0"
        XCTAssertTrue(v1 < v2)
        XCTAssertFalse(v1.isCompatible(with: v2))

        let v1_3 = try __MODULE_NAME__(string: "1.3.0")
        XCTAssertTrue(v1.isCompatible(with: v1_3))
    }

    func testInvalidFormat() {
        XCTAssertThrowsError(try __MODULE_NAME__(string: "invalid.version.number.extra"))
    }
}
