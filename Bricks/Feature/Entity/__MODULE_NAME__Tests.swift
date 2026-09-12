import XCTest
@testable import __PROJECT_NAME__

final class __MODULE_NAME__EntityTests: XCTestCase {
    func testEntityEncodingAndDecoding() throws {
        let entity = __MODULE_NAME__(id: "101", name: "Test Entity")
        let data = try JSONEncoder().encode(entity)
        let decoded = try JSONDecoder().decode(__MODULE_NAME__.self, from: data)
        XCTAssertEqual(entity.id, decoded.id)
        XCTAssertEqual(entity.name, decoded.name)
    }
}
