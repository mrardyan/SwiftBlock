import XCTest
@testable import __PROJECT_NAME__

final class __MODULE_NAME__RepositoryTests: XCTestCase {
    func testRepositoryFetchData() async throws {
        let repository = Default__MODULE_NAME__Repository()
        let data = try await repository.fetchData()
        XCTAssertNotNil(data)
    }
}
