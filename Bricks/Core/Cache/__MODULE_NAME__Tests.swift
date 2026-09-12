import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testSetAndGet() {
        let cache = __MODULE_NAME__()
        cache.set("hello", forKey: "greeting")
        XCTAssertEqual(cache.get(String.self, forKey: "greeting"), "hello")
    }

    func testExpiration() {
        let cache = __MODULE_NAME__()
        cache.set("temp_value", forKey: "temp", timeToLive: -1) // Already expired
        XCTAssertNil(cache.get(String.self, forKey: "temp"))
    }

    func testMaxCountEviction() {
        let cache = __MODULE_NAME__(maxCount: 2)
        cache.set(1, forKey: "k1")
        cache.set(2, forKey: "k2")
        cache.set(3, forKey: "k3") // Should evict k1

        XCTAssertNil(cache.get(Int.self, forKey: "k1"))
        XCTAssertEqual(cache.get(Int.self, forKey: "k2"), 2)
        XCTAssertEqual(cache.get(Int.self, forKey: "k3"), 3)
    }

    func testRemoveAll() {
        let cache = __MODULE_NAME__()
        cache.set("a", forKey: "k1")
        cache.set("b", forKey: "k2")

        cache.removeAll()
        XCTAssertNil(cache.get(String.self, forKey: "k1"))
        XCTAssertNil(cache.get(String.self, forKey: "k2"))
    }
}
