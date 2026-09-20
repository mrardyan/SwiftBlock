import XCTest
import XCTVapor
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testBlocksRequestsBeyondLimit() async throws {
        let app = try await Application.make(.testing)
        app.middleware.use(__MODULE_NAME__(maxRequests: 2, windowDuration: 60))
        app.get("ping") { _ async in "pong" }

        try await app.test(.GET, "ping") { res async in
            XCTAssertEqual(res.status, .ok)
        }
        try await app.test(.GET, "ping") { res async in
            XCTAssertEqual(res.status, .ok)
        }
        try await app.test(.GET, "ping") { res async in
            XCTAssertEqual(res.status, .tooManyRequests)
        }

        try await app.asyncShutdown()
    }
}