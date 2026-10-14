import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testMissingKeyReturnsKey() {
        let value = __MODULE_NAME__.localized("missing.key.\(UUID().uuidString)")
        XCTAssertFalse(value.isEmpty)
    }

    func testArgumentsAreFormatted() {
        let value = __MODULE_NAME__.localized("%@ %@", arguments: ["Hello", "World"])
        XCTAssertEqual(value, "Hello World")
    }

    func testCurrentLanguageCodeIsNotEmpty() {
        XCTAssertFalse(__MODULE_NAME__.currentLanguageCode.isEmpty)
    }
}