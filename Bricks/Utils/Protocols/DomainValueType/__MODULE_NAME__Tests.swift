import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    struct Username: __MODULE_NAME__ {
        typealias RawValue = String
        let rawValue: String

        init?(rawValue: String) {
            guard Self.isValid(rawValue) else { return nil }
            self.rawValue = rawValue
        }

        static func isValid(_ rawValue: String) -> Bool {
            rawValue.count >= 3 && rawValue.count <= 20
        }
    }

    func testDomainValueTypeValidation() {
        XCTAssertNotNil(Username(rawValue: "alice"))
        XCTAssertNil(Username(rawValue: "ab")) // Too short
        XCTAssertEqual(Username(rawValue: "bob")?.description, "bob")
    }
}
