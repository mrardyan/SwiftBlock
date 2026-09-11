import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __PROJECT_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    var storage: __MODULE_NAME__!

    override func setUp() {
        super.setUp()
        storage = __MODULE_NAME__(service: "com.test.__MODULE_NAME__Tests")
    }

    override func tearDown() {
        storage.remove(forKey: "test_key")
        storage = nil
        super.tearDown()
    }

    func testSaveAndLoadItem() throws {
        struct TestModel: Codable, Equatable {
            let id: String
            let value: Int
        }

        let input = TestModel(id: "123", value: 42)
        try storage.save(input, forKey: "test_key")

        let loaded: TestModel? = try storage.load(forKey: "test_key", as: TestModel.self)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded, input)
    }

    func testRemoveItem() throws {
        try storage.save("secret_data", forKey: "test_key")
        storage.remove(forKey: "test_key")

        let loaded: String? = try storage.load(forKey: "test_key", as: String.self)
        XCTAssertNil(loaded)
    }
}
