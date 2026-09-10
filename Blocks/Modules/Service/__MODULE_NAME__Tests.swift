import XCTest
@testable import __PROJECT_NAME__

final class __MODULE_NAME__ServiceTests: XCTestCase {
    func testServiceFetchRemoteData() async throws {
        let service = Default__MODULE_NAME__Service()
        let response = try await service.fetchRemoteData()
        XCTAssertNotNil(response)
    }
}
