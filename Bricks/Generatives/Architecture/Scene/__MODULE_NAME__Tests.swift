import XCTest
@testable import __PROJECT_NAME__

final class __MODULE_NAME__SceneTests: XCTestCase {
    func testViewModelInitialState() {
        let viewModel = __MODULE_NAME__ViewModel()
        XCTAssertFalse(viewModel.state.isLoading)
        XCTAssertNil(viewModel.state.errorMessage)
    }

    func testViewModelHandleAction() async {
        let viewModel = __MODULE_NAME__ViewModel()
        await viewModel.handle(.loadData)
        XCTAssertFalse(viewModel.state.isLoading)
    }
}
