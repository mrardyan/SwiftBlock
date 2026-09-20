import XCTest
@testable import __APP_MODULE__

final class __MODULE_NAME__EntityTests: XCTestCase {
    func testEntityEncodingAndDecoding() throws {
        let entity = __MODULE_NAME__Entity(id: "101", name: "Test Entity")
        let data = try JSONEncoder().encode(entity)
        let decoded = try JSONDecoder().decode(__MODULE_NAME__Entity.self, from: data)
        XCTAssertEqual(entity.id, decoded.id)
        XCTAssertEqual(entity.name, decoded.name)
    }
}