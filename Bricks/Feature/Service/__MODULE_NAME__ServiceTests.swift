import XCTest
@testable import __APP_MODULE__

final class __MODULE_NAME__ServiceTests: XCTestCase {
    func testServiceRequest() async throws {
        let service = Default__MODULE_NAME__Service()
        try await service.request()
    }
}