import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    struct UpperCaseFormatter: __MODULE_NAME__ {
        func format(_ value: String) -> String {
            value.uppercased()
        }
    }

    func testOptionalValueFormatting() {
        let formatter = UpperCaseFormatter().optional(fallback: "N/A")

        XCTAssertEqual(formatter.format("hello"), "HELLO")
        XCTAssertEqual(formatter.format(nil), "N/A")
    }
}
