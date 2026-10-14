import XCTVapor
@testable import App

final class AppTests: XCTestCase {
    var app: Application!

    override func setUp() async throws {
        app = try await Application.make(.testing)
        try await configure(app)
    }

    override func tearDown() async throws {
        try await app.asyncShutdown()
    }

    func testWelcomeRoute() async throws {
        try await app.test(.GET, "") { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertContains(res.body.string, "__PROJECT_NAME__")
        }
    }

    func testHealthCheckRoute() async throws {
        try await app.test(.GET, "health") { res async in
            XCTAssertEqual(res.status, .ok)
            XCTAssertContains(res.body.string, "pass")
            XCTAssertContains(res.body.string, "__PROJECT_NAME__")
        }
    }
}
