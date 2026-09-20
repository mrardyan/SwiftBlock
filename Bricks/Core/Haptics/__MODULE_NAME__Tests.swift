import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testFeedbackCallsDoNotThrow() {
        __MODULE_NAME__.impact(.light)
        __MODULE_NAME__.impact(.medium)
        __MODULE_NAME__.impact(.heavy)
        __MODULE_NAME__.impact(.success)
        __MODULE_NAME__.impact(.warning)
        __MODULE_NAME__.impact(.error)
        __MODULE_NAME__.impact(.selection)
    }
}