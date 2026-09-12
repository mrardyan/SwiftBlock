import XCTest
@testable import __MODULE_NAME__

@MainActor
final class __MODULE_NAME__SceneTests: XCTestCase {
    func testViewModelInitialState() {
        let viewModel = __MODULE_NAME__ViewModel(delayDuration: 0)
        XCTAssertEqual(viewModel.state.status, .idle)
        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertNil(viewModel.state.errorMessage)
    }

    func testViewModelHandleActionLoadsData() async {
        let viewModel = __MODULE_NAME__ViewModel(delayDuration: 0)
        await viewModel.handle(.loadData)

        XCTAssertFalse(viewModel.state.isLoading)
        if case .loaded(let items) = viewModel.state.status {
            XCTAssertFalse(items.isEmpty)
        } else {
            XCTFail("Expected state to be .loaded, got \(viewModel.state.status)")
        }
    }
}
