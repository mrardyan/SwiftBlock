import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testLevenshteinDistance() {
        XCTAssertEqual(__MODULE_NAME__.distance("kitten", "sitting"), 3)
        XCTAssertEqual(__MODULE_NAME__.distance("swift", "swift"), 0)
        XCTAssertEqual(__MODULE_NAME__.distance("", "abc"), 3)
        XCTAssertEqual(__MODULE_NAME__.distance("abc", ""), 3)
        XCTAssertEqual(__MODULE_NAME__.distance("flaw", "lawn"), 2)
    }

    func testSimilarityScore() {
        XCTAssertEqual(__MODULE_NAME__.similarity("apple", "apple"), 1.0)
        XCTAssertEqual(__MODULE_NAME__.similarity("", ""), 1.0)

        let similarity = __MODULE_NAME__.similarity("kitten", "sitting")
        XCTAssertEqual(similarity, 1.0 - (3.0 / 7.0), accuracy: 0.001)
    }
}
