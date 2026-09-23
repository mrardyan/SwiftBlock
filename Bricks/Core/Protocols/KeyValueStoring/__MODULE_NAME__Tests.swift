import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    struct UserProfile: Codable, Equatable, Sendable {
        let name: String
        let age: Int
    }

    func testKeyValueStoreOperations() throws {
        let store: __MODULE_NAME__ = InMemoryKeyValueStore()

        let user = UserProfile(name: "Alice", age: 28)
        try store.set(user, forKey: "user_alice")

        let retrieved = try store.get(UserProfile.self, forKey: "user_alice")
        XCTAssertEqual(retrieved, user)

        try store.remove(forKey: "user_alice")
        let deleted = try store.get(UserProfile.self, forKey: "user_alice")
        XCTAssertNil(deleted)
    }
}
