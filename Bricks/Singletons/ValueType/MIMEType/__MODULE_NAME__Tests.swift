import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testMIMETypeParsingAndCategories() throws {
        let mime = try __MODULE_NAME__(string: "image/png")
        XCTAssertEqual(mime.type, "image")
        XCTAssertEqual(mime.subtype, "png")
        XCTAssertTrue(mime.isImage)
        XCTAssertFalse(mime.isAudio)
        XCTAssertEqual(mime.rawValue, "image/png")

        let json: __MODULE_NAME__ = "application/json"
        XCTAssertTrue(json.isApplication)
        XCTAssertEqual(json, __MODULE_NAME__.json)
    }

    func testInvalidMIMEType() {
        XCTAssertThrowsError(try __MODULE_NAME__(string: "invalid-format"))
    }
}
