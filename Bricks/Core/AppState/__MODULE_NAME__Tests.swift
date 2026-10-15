import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
{{#if concurrency == 'swift-concurrency'}}
    func testLifecycleTransitions() async {
        let appState = __MODULE_NAME__(initialState: .active)
        let isActive = await appState.isActive
        let isBackground = await appState.isBackground
        XCTAssertTrue(isActive)
        XCTAssertFalse(isBackground)

        await appState.transitionTo(.background)
        let isNowActive = await appState.isActive
        let isNowBackground = await appState.isBackground
        let current = await appState.currentState
        XCTAssertFalse(isNowActive)
        XCTAssertTrue(isNowBackground)
        XCTAssertEqual(current, .background)

        await appState.transitionTo(.inactive)
        let finalState = await appState.currentState
        XCTAssertEqual(finalState, .inactive)
    }
{{else}}
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
{{/if}}
}
