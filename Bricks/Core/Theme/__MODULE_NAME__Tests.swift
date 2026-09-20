import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testSharedThemeHasDefaultValues() {
        let theme = __MODULE_NAME__.shared
        XCTAssertEqual(theme.cornerRadius, 12)
        XCTAssertEqual(theme.spacing, 16)
        XCTAssertEqual(theme.cornerRadiusSmall, 6)
        XCTAssertEqual(theme.spacingLarge, 24)
    }

    func testCustomThemeOverrides() {
        let theme = __MODULE_NAME__(primaryColor: .red, spacing: 20)
        XCTAssertEqual(theme.primaryColor, .red)
        XCTAssertEqual(theme.spacing, 20)
    }
}