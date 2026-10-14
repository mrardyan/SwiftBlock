import XCTest
import Vapor
@testable import __APP_MODULE__

final class __MODULE_NAME__DTOTests: XCTestCase {
    func testRequestCodableRoundtrip() throws {
        let original = __MODULE_NAME__Request(name: "Ada")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(__MODULE_NAME__Request.self, from: data)
        XCTAssertEqual(decoded.name, "Ada")
    }

    func testResponseCodableRoundtrip() throws {
        let original = __MODULE_NAME__Response(id: UUID(), name: "Ada")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(__MODULE_NAME__Response.self, from: data)
        XCTAssertEqual(decoded.name, "Ada")
        XCTAssertNotEqual(decoded.id, UUID())
    }
}