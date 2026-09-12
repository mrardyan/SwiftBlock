import XCTest
@testable import __MODULE_NAME__

private enum UserTag {}
private enum ProductTag {}

private typealias UserID = __MODULE_NAME__<UserTag, String>
private typealias ProductID = __MODULE_NAME__<ProductTag, Int>

final class __MODULE_NAME__Tests: XCTestCase {
    func testStringIdentifierLiteralAndEquality() {
        let id1: UserID = "usr_101"
        let id2: UserID = __MODULE_NAME__("usr_101")

        XCTAssertEqual(id1, id2)
        XCTAssertEqual(id1.rawValue, "usr_101")
        XCTAssertEqual(id1.description, "usr_101")
    }

    func testIntIdentifierLiteralAndEquality() {
        let id1: ProductID = 505
        let id2: ProductID = __MODULE_NAME__(505)

        XCTAssertEqual(id1, id2)
        XCTAssertEqual(id1.rawValue, 505)
        XCTAssertEqual(id1.description, "505")
    }

    func testCodableEncodingDecoding() throws {
        let userId: UserID = "usr_999"

        let encoder = JSONEncoder()
        let data = try encoder.encode(userId)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(UserID.self, from: data)

        XCTAssertEqual(decoded, userId)
    }
}
