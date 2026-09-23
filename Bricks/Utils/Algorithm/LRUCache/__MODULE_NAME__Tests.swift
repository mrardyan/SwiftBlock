import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testLRUCacheCapacityAndEviction() {
        let cache = __MODULE_NAME__<String, Int>(capacity: 2)

        cache.set(1, forKey: "a")
        cache.set(2, forKey: "b")
        XCTAssertEqual(cache.currentCount, 2)

        // Access "a" to make it more recently used
        XCTAssertEqual(cache.get("a"), 1)

        // Add "c" -> should evict "b" (least recently used)
        cache.set(3, forKey: "c")

        XCTAssertEqual(cache.get("a"), 1)
        XCTAssertNil(cache.get("b"))
        XCTAssertEqual(cache.get("c"), 3)
    }

    func testUpdateExistingKey() {
        let cache = __MODULE_NAME__<String, String>(capacity: 2)
        cache.set("old", forKey: "k")
        cache.set("new", forKey: "k")

        XCTAssertEqual(cache.get("k"), "new")
        XCTAssertEqual(cache.currentCount, 1)
    }

    func testRemoveAndRemoveAll() {
        let cache = __MODULE_NAME__<Int, String>(capacity: 5)
        cache.set("one", forKey: 1)
        cache.set("two", forKey: 2)

        XCTAssertEqual(cache.remove(1), "one")
        XCTAssertNil(cache.get(1))
        XCTAssertEqual(cache.currentCount, 1)

        cache.removeAll()
        XCTAssertEqual(cache.currentCount, 0)
    }
}
