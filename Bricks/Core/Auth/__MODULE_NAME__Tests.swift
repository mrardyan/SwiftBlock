import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
{{#if concurrency == 'swift-concurrency'}}
    func testInitialStateIsUnauthenticated() async {
        let authManager = __MODULE_NAME__(serviceName: "com.test.auth.\(UUID().uuidString)")
        let state = await authManager.currentState
        let token = await authManager.accessToken
        XCTAssertEqual(state, .unauthenticated)
        XCTAssertNil(token)
    }

    func testSetSessionPersistsInKeychain() async {
        let testToken = "sample_jwt_access_token_123"
        let testUserId = "user_9988"
        let serviceName = "com.test.auth.restore.\(UUID().uuidString)"

        let manager1 = __MODULE_NAME__(serviceName: serviceName)
        await manager1.setSession(accessToken: testToken, userId: testUserId)

        let state1 = await manager1.currentState
        let token1 = await manager1.accessToken
        XCTAssertEqual(state1, .authenticated(userId: testUserId))
        XCTAssertEqual(token1, testToken)

        let manager2 = __MODULE_NAME__(serviceName: serviceName)
        let state2 = await manager2.currentState
        let token2 = await manager2.accessToken
        XCTAssertEqual(state2, .authenticated(userId: testUserId))
        XCTAssertEqual(token2, testToken)

        await manager1.clearSession()
    }

    func testClearSessionRemovesKeychainData() async {
        let serviceName = "com.test.auth.clear.\(UUID().uuidString)"
        let manager = __MODULE_NAME__(serviceName: serviceName)

        await manager.setSession(accessToken: "token", userId: "user")
        await manager.clearSession()

        let state = await manager.currentState
        let token = await manager.accessToken
        XCTAssertEqual(state, .unauthenticated)
        XCTAssertNil(token)

        let managerReopened = __MODULE_NAME__(serviceName: serviceName)
        let stateReopened = await managerReopened.currentState
        let tokenReopened = await managerReopened.accessToken
        XCTAssertEqual(stateReopened, .unauthenticated)
        XCTAssertNil(tokenReopened)
    }
{{else}}
    func testInitialStateIsUnauthenticated() {
        let authManager = __MODULE_NAME__(serviceName: "com.test.auth.\(UUID().uuidString)")
        XCTAssertEqual(authManager.currentState, .unauthenticated)
        XCTAssertNil(authManager.accessToken)
    }

    func testSetSessionPersistsInKeychain() {
        let testToken = "sample_jwt_access_token_123"
        let testUserId = "user_9988"
        let serviceName = "com.test.auth.restore.\(UUID().uuidString)"

        let manager1 = __MODULE_NAME__(serviceName: serviceName)
        manager1.setSession(accessToken: testToken, userId: testUserId)

        XCTAssertEqual(manager1.currentState, .authenticated(userId: testUserId))
        XCTAssertEqual(manager1.accessToken, testToken)

        let manager2 = __MODULE_NAME__(serviceName: serviceName)
        XCTAssertEqual(manager2.currentState, .authenticated(userId: testUserId))
        XCTAssertEqual(manager2.accessToken, testToken)

        manager1.clearSession()
    }

    func testClearSessionRemovesKeychainData() {
        let serviceName = "com.test.auth.clear.\(UUID().uuidString)"
        let manager = __MODULE_NAME__(serviceName: serviceName)

        manager.setSession(accessToken: "token", userId: "user")
        manager.clearSession()

        XCTAssertEqual(manager.currentState, .unauthenticated)
        XCTAssertNil(manager.accessToken)

        let managerReopened = __MODULE_NAME__(serviceName: serviceName)
        XCTAssertEqual(managerReopened.currentState, .unauthenticated)
        XCTAssertNil(managerReopened.accessToken)
    }
{{/if}}
}
