import XCTest
@testable import __APP_MODULE__

@MainActor
final class __MODULE_NAME__CoordinatorTests: XCTestCase {
    func testCoordinatorNavigation() {
        let coordinator = Default__MODULE_NAME__Coordinator()
        XCTAssertFalse(coordinator.isPresented)

        coordinator.start()
        XCTAssertTrue(coordinator.isPresented)

        coordinator.dismiss()
        XCTAssertFalse(coordinator.isPresented)
    }
}