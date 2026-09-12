import XCTest
@testable import __PROJECT_NAME__

final class __MODULE_NAME__RepositoryTests: XCTestCase {
    func testRepositoryFetch() async throws {
        let repository = Default__MODULE_NAME__Repository()
        let items = try await repository.fetch()
        XCTAssertTrue(items.isEmpty)
    }
}
