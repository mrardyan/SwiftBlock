import XCTest
@testable import __APP_MODULE__

@MainActor
final class __MODULE_NAME__FormViewModelTests: XCTestCase {
    func testValidationFailsWhenEmpty() {
        let viewModel = __MODULE_NAME__FormViewModel(fieldNames: ["name"])
        XCTAssertFalse(viewModel.validate())
        XCTAssertNotNil(viewModel.errors["name"])
        XCTAssertFalse(viewModel.isValid)
    }

    func testValidationSucceedsWhenFilled() {
        let viewModel = __MODULE_NAME__FormViewModel(fieldNames: ["name"])
        viewModel.update("name", value: "Ada")
        XCTAssertTrue(viewModel.validate())
        XCTAssertTrue(viewModel.isValid)
        XCTAssertNil(viewModel.errors["name"])
    }

    func testSubmitInvokesCallbackAndSetsFlag() async {
        let viewModel = __MODULE_NAME__FormViewModel(fieldNames: ["name"], onSubmit: { _ in true })
        viewModel.update("name", value: "Ada")
        await viewModel.submit()
        XCTAssertTrue(viewModel.didSubmit)
    }

    func testSubmitBlockedWhenInvalid() async {
        let viewModel = __MODULE_NAME__FormViewModel(fieldNames: ["name"], onSubmit: { _ in true })
        await viewModel.submit()
        XCTAssertFalse(viewModel.didSubmit)
    }
}