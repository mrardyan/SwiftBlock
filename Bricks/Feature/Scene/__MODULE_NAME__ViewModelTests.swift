import XCTest
@testable import {{PROJECT_NAME}}

final class {{MODULE_NAME}}ViewModelTests: XCTestCase {
{{#if stateStyle == 'combine'}}
    func testInitialStateCombine() {
        let viewModel = {{MODULE_NAME}}ViewModel()
        XCTAssertEqual(viewModel.state, .idle)
    }

    func testStateTransitionCombine() {
        let viewModel = {{MODULE_NAME}}ViewModel()
        viewModel.handle(action: .load)
        XCTAssertEqual(viewModel.state, .loading)
    }
{{else}}
    func testInitialStateObservable() {
        let viewModel = {{MODULE_NAME}}ViewModel()
        XCTAssertEqual(viewModel.state, .idle)
    }

    func testStateTransitionObservable() {
        let viewModel = {{MODULE_NAME}}ViewModel()
        viewModel.handle(action: .load)
        XCTAssertEqual(viewModel.state, .loading)
    }
{{/if}}
}
