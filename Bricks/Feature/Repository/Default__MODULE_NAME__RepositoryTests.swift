import XCTest
@testable import {{PROJECT_NAME}}

final class Default{{MODULE_NAME}}RepositoryTests: XCTestCase {
{{#if strategy == 'offline-first'}}
    func testOfflineFirstRepositoryFetch() async throws {
        let repository = Default{{MODULE_NAME}}Repository()
        let result = try await repository.fetch(id: "test-123")
        XCTAssertEqual(result.id, "test-123")
    }
{{else}}
{{#if strategy == 'local-only'}}
    func testLocalOnlyRepositoryFetch() async throws {
        let repository = Default{{MODULE_NAME}}Repository()
        let result = try await repository.fetch(id: "test-local")
        XCTAssertEqual(result.id, "test-local")
    }
{{else}}
    func testRemoteOnlyRepositoryFetch() async throws {
        let repository = Default{{MODULE_NAME}}Repository()
        let result = try await repository.fetch(id: "test-remote")
        XCTAssertEqual(result.id, "test-remote")
    }
{{/if}}
{{/if}}
}
