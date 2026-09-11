import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __PROJECT_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testEnvironmentBaseURLResolution() {
        let devConfig = __MODULE_NAME__(environment: .development)
        XCTAssertEqual(devConfig.baseURL.absoluteString, "https://dev-api.example.com")

        let stgConfig = __MODULE_NAME__(environment: .staging)
        XCTAssertEqual(stgConfig.baseURL.absoluteString, "https://staging-api.example.com")

        let prodConfig = __MODULE_NAME__(environment: .production)
        XCTAssertEqual(prodConfig.baseURL.absoluteString, "https://api.example.com")
    }

    func testFeatureFlags() {
        let config = __MODULE_NAME__(
            environment: .development,
            featureFlags: ["new_checkout": true, "beta_banner": false]
        )

        XCTAssertTrue(config.isFeatureEnabled("new_checkout"))
        XCTAssertFalse(config.isFeatureEnabled("beta_banner"))
        XCTAssertFalse(config.isFeatureEnabled("unknown_flag"))
    }
}
