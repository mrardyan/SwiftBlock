import XCTest
@testable import __MODULE_NAME__

private struct UserProfile: Codable, Equatable {
    let id: String
    let name: String
    let age: Int
}

final class __MODULE_NAME__Tests: XCTestCase {
    private var storage: __MODULE_NAME__!

    override func setUp() {
        super.setUp()
        storage = __MODULE_NAME__(defaultLocation: .inMemory)
    }

    override func tearDown() {
        storage.clear(location: .inMemory)
        storage = nil
        super.tearDown()
    }

    func testInMemoryStoreAndRetrieve() throws {
        let profile = UserProfile(id: "usr_101", name: "Alice", age: 28)
        try storage.set(profile, forKey: "profile_key", location: .inMemory)

        let retrieved = try storage.get(UserProfile.self, forKey: "profile_key", location: .inMemory)
        XCTAssertEqual(retrieved, profile)
    }

    func testUserDefaultsStorage() throws {
        let suiteName = "com.test.storage.suite.\(UUID().uuidString)"
        let location = StorageLocation.userDefaults(suiteName: suiteName)

        let testValue = "hello_swiftblock"
        try storage.set(testValue, forKey: "test_key", location: location)

        let retrieved = try storage.get(String.self, forKey: "test_key", location: location)
        XCTAssertEqual(retrieved, testValue)

        storage.remove(forKey: "test_key", location: location)
        let afterRemove = try storage.get(String.self, forKey: "test_key", location: location)
        XCTAssertNil(afterRemove)
    }

    func testKeychainStorage() throws {
        let serviceName = "com.test.storage.keychain.\(UUID().uuidString)"
        let location = StorageLocation.keychain(serviceName: serviceName)

        let secretToken = "super_secret_token_123"
        try storage.set(secretToken, forKey: "token_key", location: location)

        let retrieved = try storage.get(String.self, forKey: "token_key", location: location)
        XCTAssertEqual(retrieved, secretToken)

        storage.remove(forKey: "token_key", location: location)
        let afterRemove = try storage.get(String.self, forKey: "token_key", location: location)
        XCTAssertNil(afterRemove)
    }

    func testClearInMemoryStorage() throws {
        try storage.set("val1", forKey: "k1", location: .inMemory)
        try storage.set("val2", forKey: "k2", location: .inMemory)

        storage.clear(location: .inMemory)

        let k1 = try storage.get(String.self, forKey: "k1", location: .inMemory)
        let k2 = try storage.get(String.self, forKey: "k2", location: .inMemory)

        XCTAssertNil(k1)
        XCTAssertNil(k2)
    }
}
