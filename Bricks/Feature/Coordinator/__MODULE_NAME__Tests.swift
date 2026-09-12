import XCTest
@testable import __PROJECT_NAME__

final class __MODULE_NAME__CoordinatorTests: XCTestCase {
    func testCoordinatorNavigation() {
        let coordinator = __MODULE_NAME__Coordinator()
        XCTAssertEqual(coordinator.path.count, 0)
    }
}
