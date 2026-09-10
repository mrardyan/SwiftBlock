import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __PROJECT_NAME__

private final class MockSessionDelegate: SessionDelegate {
    var lastState: SessionState?

    func sessionStateDidChange(_ state: SessionState) {
        lastState = state
    }
}

final class __MODULE_NAME__Tests: XCTestCase {
    func testInitialUnauthenticatedState() {
        let auth = __MODULE_NAME__()
        XCTAssertEqual(auth.currentState, .unauthenticated)
        XCTAssertNil(auth.accessToken)
    }

    func testSetSession() {
        let auth = __MODULE_NAME__()
        let delegate = MockSessionDelegate()
        auth.delegate = delegate

        auth.setSession(accessToken: "token_abc123", userId: "user_456")

        XCTAssertEqual(auth.currentState, .authenticated(userId: "user_456"))
        XCTAssertEqual(auth.accessToken, "token_abc123")
        XCTAssertEqual(delegate.lastState, .authenticated(userId: "user_456"))
    }

    func testClearSession() {
        let auth = __MODULE_NAME__()
        let delegate = MockSessionDelegate()
        auth.delegate = delegate

        auth.setSession(accessToken: "token_abc123", userId: "user_456")
        auth.clearSession()

        XCTAssertEqual(auth.currentState, .unauthenticated)
        XCTAssertNil(auth.accessToken)
        XCTAssertEqual(delegate.lastState, .unauthenticated)
    }
}
