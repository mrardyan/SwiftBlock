import XCTest
@testable import __MODULE_NAME__

final class __MODULE_NAME__Tests: XCTestCase {
    private var authManager: __MODULE_NAME__!

    override func setUp() {
        super.setUp()
        authManager = __MODULE_NAME__(serviceName: "com.test.auth.\(UUID().uuidString)")
    }

    override func tearDown() {
        authManager.clearSession()
        authManager = nil
        super.tearDown()
    }

    func testInitialStateIsUnauthenticated() {
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
}
