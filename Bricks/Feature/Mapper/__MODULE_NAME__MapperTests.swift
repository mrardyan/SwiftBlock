import XCTest
@testable import __APP_MODULE__

final class __MODULE_NAME__MapperTests: XCTestCase {
    func testMapperTransform() {
        let mapper = __MODULE_NAME__Mapper<String, String>(
            toEntity: { $0.uppercased() },
            toDTO: { $0.lowercased() }
        )
        XCTAssertEqual(mapper.mapToEntity("hello"), "HELLO")
        XCTAssertEqual(mapper.mapToDTO("HELLO"), "hello")
    }

    func testMapperArrays() {
        let mapper = __MODULE_NAME__Mapper<Int, String>(
            toEntity: { "\($0)" },
            toDTO: { Int($0) ?? 0 }
        )
        XCTAssertEqual(mapper.mapToEntities([1, 2, 3]), ["1", "2", "3"])
        XCTAssertEqual(mapper.mapToDTOs(["4", "5"]), [4, 5])
    }
}