import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testSKUNormalizationAndValidation() throws {
        let sku = try __MODULE_NAME__(rawValue: "  prod-123-abc  ")
        XCTAssertEqual(sku.rawValue, "PROD-123-ABC")
        XCTAssertEqual(sku.description, "PROD-123-ABC")

        let literal: __MODULE_NAME__ = "ITEM-001"
        XCTAssertEqual(literal.rawValue, "ITEM-001")
    }

    func testInvalidSKU() {
        XCTAssertThrowsError(try __MODULE_NAME__(rawValue: ""))
        XCTAssertThrowsError(try __MODULE_NAME__(rawValue: "AB")) // too short
        XCTAssertThrowsError(try __MODULE_NAME__(rawValue: "PROD@123!")) // invalid chars
    }
}
