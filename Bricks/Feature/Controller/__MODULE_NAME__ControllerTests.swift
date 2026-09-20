import XCTest
import XCTVapor
@testable import __APP_MODULE__

final class __MODULE_NAME__ControllerTests: XCTestCase {
    func testIndexRouteRespondsOk() async throws {
        let app = try await Application.make(.testing)
        try app.register(collection: __MODULE_NAME__Controller())

        try await app.test(.GET, "{{moduleName.lowercased()}}") { res async in
            XCTAssertEqual(res.status, .ok)
        }

        try await app.asyncShutdown()
    }
}