import XCTest
@testable import __PROJECT_NAME__

final class __MODULE_NAME__ComponentTests: XCTestCase {
    func testComponentInitialization() {
        let component = __MODULE_NAME__Component(title: "Hello World")
        XCTAssertEqual(component.title, "Hello World")
    }
}
