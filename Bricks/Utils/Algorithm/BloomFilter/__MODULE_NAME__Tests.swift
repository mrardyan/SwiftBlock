import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testBloomFilterNoFalseNegatives() {
        var filter = __MODULE_NAME__<String>(expectedElements: 100, falsePositiveRate: 0.01)

        let inserted = ["user_1", "user_2", "user_3", "admin_root", "session_99"]
        for item in inserted {
            filter.insert(item)
        }

        // All inserted elements MUST return true
        for item in inserted {
            XCTAssertTrue(filter.contains(item))
        }
    }

    func testBloomFilterNonExistentElements() {
        var filter = __MODULE_NAME__<String>(expectedElements: 1000, falsePositiveRate: 0.001)

        for i in 0..<100 {
            filter.insert("key_\(i)")
        }

        var falsePositives = 0
        for i in 1000..<1100 {
            if filter.contains("key_\(i)") {
                falsePositives += 1
            }
        }

        // With p=0.001 and 100 samples, false positive count should be minimal (typically 0)
        XCTAssertLessThanOrEqual(falsePositives, 2)
    }
}
