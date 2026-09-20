import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testRequestReviewDoesNotThrow() {
        __MODULE_NAME__.requestReview()
    }
}