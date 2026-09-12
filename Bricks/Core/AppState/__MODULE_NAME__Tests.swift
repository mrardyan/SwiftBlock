import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    func testLifecycleTransitions() {
        let appState = __MODULE_NAME__(initialState: .active)
        XCTAssertTrue(appState.isActive)
        XCTAssertFalse(appState.isBackground)

        appState.transitionTo(.background)
        XCTAssertFalse(appState.isActive)
        XCTAssertTrue(appState.isBackground)
        XCTAssertEqual(appState.currentState, .background)

        appState.transitionTo(.inactive)
        XCTAssertEqual(appState.currentState, .inactive)
    }
}
