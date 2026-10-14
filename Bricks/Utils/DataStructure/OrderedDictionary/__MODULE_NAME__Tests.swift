import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testOrderedDictionaryPreservesInsertionOrder() {
        var dict: __MODULE_NAME__<String, Int> = [:]
        dict["z"] = 1
        dict["a"] = 2
        dict["m"] = 3

        XCTAssertEqual(dict.keys, ["z", "a", "m"])
        XCTAssertEqual(dict["a"], 2)

        // Update value of existing key should not change key order
        dict["z"] = 100
        XCTAssertEqual(dict.keys, ["z", "a", "m"])
        XCTAssertEqual(dict["z"], 100)
    }

    func testRemoveValue() {
        var dict: __MODULE_NAME__<Int, String> = [1: "one", 2: "two", 3: "three"]
        XCTAssertEqual(dict.removeValue(forKey: 2), "two")
        XCTAssertEqual(dict.keys, [1, 3])
        XCTAssertEqual(dict.count, 2)
    }
}
