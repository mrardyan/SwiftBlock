import XCTest
@testable import __PROJECT_NAME__

final class __MODULE_NAME__MapperTests: XCTestCase {
    func testMapperTransform() {
        let mapper = Default__MODULE_NAME__Mapper()
        let entity = mapper.map(input: "test_input")
        XCTAssertNotNil(entity)
    }
}
