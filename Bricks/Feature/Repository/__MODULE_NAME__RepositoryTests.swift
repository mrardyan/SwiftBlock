import XCTest
@testable import __APP_MODULE__

final class __MODULE_NAME__RepositoryTests: XCTestCase {
    func testRepositoryFetch() async throws {
        let repository = Default__MODULE_NAME__Repository()
        let items = try await repository.fetch()
        XCTAssertTrue(items.isEmpty)
    }
}
