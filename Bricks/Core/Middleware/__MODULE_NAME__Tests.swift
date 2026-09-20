import XCTest
import Vapor
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testConfigureDoesNotThrow() async throws {
        let app = try await Application.make(.testing)
        __MODULE_NAME__.configure(app)
        try await app.asyncShutdown()
    }
}