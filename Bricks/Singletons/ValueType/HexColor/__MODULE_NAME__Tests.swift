import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testHexParsingAndComponents() throws {
        let color = try __MODULE_NAME__(hex: "#FF5733")
        XCTAssertEqual(color.rgb.r, 255)
        XCTAssertEqual(color.rgb.g, 87)
        XCTAssertEqual(color.rgb.b, 51)
        XCTAssertEqual(color.hexString, "#FF5733")
    }

    func testHexWithAlpha() throws {
        let color = try __MODULE_NAME__(hex: "#FF573380")
        XCTAssertEqual(color.alpha, 128.0 / 255.0, accuracy: 0.01)
    }

    func testInvalidHexThrows() {
        XCTAssertThrowsError(try __MODULE_NAME__(hex: "ZZZZZZ")) { error in
            XCTAssertEqual(error as? HexColorError, HexColorError.invalidHexString("ZZZZZZ"))
        }
    }
}
