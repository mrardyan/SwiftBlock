import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __PROJECT_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testDefaultFlagValue() {
        let flag = FeatureFlag(key: "new_ui", defaultValue: true)
        let manager = __MODULE_NAME__()
        XCTAssertTrue(manager.isEnabled(flag))
    }

    func testLocalOverride() {
        let flag = FeatureFlag(key: "dark_mode", defaultValue: false)
        let manager = __MODULE_NAME__()

        manager.setOverride(true, for: flag)
        XCTAssertTrue(manager.isEnabled(flag))

        manager.setOverride(nil, for: flag)
        XCTAssertFalse(manager.isEnabled(flag))
    }

    func testExpiredFlagAudit() {
        let pastDate = Date().addingTimeInterval(-86400)
        let expiredFlag = FeatureFlag(key: "old_experiment", expirationDate: pastDate)
        let activeFlag = FeatureFlag(key: "active_feature", expirationDate: Date().addingTimeInterval(86400))

        let manager = __MODULE_NAME__(registeredFlags: [expiredFlag, activeFlag])
        let expiredList = manager.checkExpiredFlags()

        XCTAssertEqual(expiredList.count, 1)
        XCTAssertEqual(expiredList.first?.key, "old_experiment")
    }
}
