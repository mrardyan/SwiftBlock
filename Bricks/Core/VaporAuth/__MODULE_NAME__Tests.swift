import Foundation
import Testing
@testable import __MODULE_NAME__

struct __MODULE_NAME__Tests {
    @Test func generateAndValidateToken() {
        let auth = __MODULE_NAME__(jwtSecret: "test-secret")
        let token = auth.generateToken(for: "user123")
        #expect(!token.isEmpty)

        let payload = auth.validateToken(token)
        #expect(payload?.subject == "user123")
    }

    @Test func revokeToken() {
        let auth = __MODULE_NAME__(jwtSecret: "test-secret")
        let token = auth.generateToken(for: "user456")
        auth.revokeToken(token)

        let payload = auth.validateToken(token)
        #expect(payload == nil)
    }
}
