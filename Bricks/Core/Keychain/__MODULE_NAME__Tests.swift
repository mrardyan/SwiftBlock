import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testSetGetDeleteRoundtrip() throws {
        let keychain = __MODULE_NAME__(defaultService: "com.test.\(UUID().uuidString)")
        let data = "secret-value".data(using: .utf8)!

        try keychain.set(data, forKey: "access_token")
        XCTAssertEqual(try keychain.getData(forKey: "access_token"), data)

        try keychain.delete(forKey: "access_token")
        XCTAssertNil(try keychain.getData(forKey: "access_token"))
    }

    func testMissingItemReturnsNil() throws {
        let keychain = __MODULE_NAME__(defaultService: "com.test.\(UUID().uuidString)")
        XCTAssertNil(try keychain.getData(forKey: "non_existent"))
    }

    func testOverwriteUpdatesValue() throws {
        let keychain = __MODULE_NAME__(defaultService: "com.test.\(UUID().uuidString)")
        try keychain.set(Data("first".utf8), forKey: "k")
        try keychain.set(Data("second".utf8), forKey: "k")
        XCTAssertEqual(try keychain.getData(forKey: "k"), Data("second".utf8))
    }
}