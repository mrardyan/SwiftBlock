import XCTest
@testable import __MODULE_NAME__

struct UserToken: Codable, Equatable {
    let accessToken: String
    let expiresAt: Int
}

final class __MODULE_NAME__Tests: XCTestCase {
    var storage: __MODULE_NAME__!

    override func setUp() {
        super.setUp()
        storage = __MODULE_NAME__(serviceName: "com.test.securestorage", useInMemoryMock: true)
    }

    func testStringStorage() throws {
        try storage.set("secret_token_123", forKey: "auth_token")
        let retrieved = try storage.get(forKey: "auth_token")
        XCTAssertEqual(retrieved, "secret_token_123")

        try storage.remove(forKey: "auth_token")
        let afterRemove = try storage.get(forKey: "auth_token")
        XCTAssertNil(afterRemove)
    }

    func testCodableStorage() throws {
        let token = UserToken(accessToken: "abc-def", expiresAt: 3600)
        try storage.set(token, forKey: "user_token")

        let retrieved = try storage.get(UserToken.self, forKey: "user_token")
        XCTAssertEqual(retrieved, token)
    }

    func testClearAll() throws {
        try storage.set("val1", forKey: "key1")
        try storage.set("val2", forKey: "key2")

        try storage.clear()

        XCTAssertNil(try storage.get(forKey: "key1"))
        XCTAssertNil(try storage.get(forKey: "key2"))
    }
}
