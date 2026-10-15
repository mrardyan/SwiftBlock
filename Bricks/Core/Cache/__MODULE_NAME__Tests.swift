import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
{{#if concurrency == 'swift-concurrency'}}
    func testSetAndGet() async {
        let cache = __MODULE_NAME__()
        await cache.set("hello", forKey: "greeting")
        let result = await cache.get(String.self, forKey: "greeting")
        XCTAssertEqual(result, "hello")
    }

    func testExpiration() async {
        let cache = __MODULE_NAME__()
        await cache.set("temp_value", forKey: "temp", timeToLive: -1) // Already expired
        let result = await cache.get(String.self, forKey: "temp")
        XCTAssertNil(result)
    }

    func testMaxCountEviction() async {
        let cache = __MODULE_NAME__(maxCount: 2)
        await cache.set(1, forKey: "k1")
        await cache.set(2, forKey: "k2")
        await cache.set(3, forKey: "k3") // Should evict k1

        let k1 = await cache.get(Int.self, forKey: "k1")
        let k2 = await cache.get(Int.self, forKey: "k2")
        let k3 = await cache.get(Int.self, forKey: "k3")

        XCTAssertNil(k1)
        XCTAssertEqual(k2, 2)
        XCTAssertEqual(k3, 3)
    }

    func testRemoveAll() async {
        let cache = __MODULE_NAME__()
        await cache.set("a", forKey: "k1")
        await cache.set("b", forKey: "k2")

        await cache.removeAll()
        let k1 = await cache.get(String.self, forKey: "k1")
        let k2 = await cache.get(String.self, forKey: "k2")

        XCTAssertNil(k1)
        XCTAssertNil(k2)
    }
{{else}}
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
{{/if}}
}
