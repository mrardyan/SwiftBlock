import Foundation
import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    func testGenerateAndValidateToken() {
        let auth = __MODULE_NAME__(jwtSecret: "test-secret")
        let token = auth.generateToken(for: "user123")
        XCTAssertFalse(token.isEmpty)

        let payload = auth.validateToken(token)
        XCTAssertEqual(payload?.subject, "user123")
    }

    func testRevokeToken() {
        let auth = __MODULE_NAME__(jwtSecret: "test-secret")
        let token = auth.generateToken(for: "user456")
        auth.revokeToken(token)

        let payload = auth.validateToken(token)
        XCTAssertNil(payload)
    }
}
