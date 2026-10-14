import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testFuzzySearchMatching() {
        let items = ["UserProfileView", "UserAuthService", "NetworkClient", "UserMapper"]
        let results = __MODULE_NAME__.search(query: "usr", in: items, keyPath: { $0 })

        XCTAssertEqual(results.count, 3)
        XCTAssertTrue(results.allSatisfy { $0.item.contains("User") })
    }

    func testScoreRankingPrefixBonus() {
        let items = ["ApplicationConfig", "AppCoordinator"]
        let results = __MODULE_NAME__.search(query: "app", in: items, keyPath: { $0 })

        XCTAssertEqual(results.count, 2)
        XCTAssertGreaterThan(results[0].score, 0)
    }

    func testNoMatchReturnsEmpty() {
        let items = ["Alpha", "Beta", "Gamma"]
        let results = __MODULE_NAME__.search(query: "xyz", in: items, keyPath: { $0 })

        XCTAssertTrue(results.isEmpty)
    }
}
