import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

private final class MockRefreshProvider: TokenRefreshProvider, @unchecked Sendable {
    private let lock = NSLock()
    private var _refreshCallCount = 0
    var shouldFail = false

    var refreshCallCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _refreshCallCount
    }

    func refresh(using refreshToken: String) async throws -> AuthTokens {
        // Add small artificial delay to test concurrency single-flight
        try await Task.sleep(nanoseconds: 50_000_000)

        lock.lock()
        _refreshCallCount += 1
        lock.unlock()

        if shouldFail {
            throw TokenRefreshError.sessionExpired
        }

        return AuthTokens(
            accessToken: "new_access_token_\(UUID().uuidString)",
            refreshToken: "new_refresh_token",
            expiresInSeconds: 3600
        )
    }
}

final class __MODULE_NAME__Tests: XCTestCase {
    func testValidAccessTokenReturnsExistingWhenValid() async throws {
        let storage = InMemoryTokenStorage(
            initialTokens: AuthTokens(accessToken: "valid_token_123", refreshToken: "ref_123", expiresInSeconds: 3600)
        )
        let provider = MockRefreshProvider()
        let manager = __MODULE_NAME__(storage: storage, provider: provider)

        let token = try await manager.validAccessToken(bufferSeconds: 60)
        XCTAssertEqual(token, "valid_token_123")
        XCTAssertEqual(provider.refreshCallCount, 0)
    }

    func testValidAccessTokenRefreshesWhenExpired() async throws {
        let expiredTokens = AuthTokens(
            accessToken: "old_token",
            refreshToken: "valid_refresh",
            expiresAt: Date().addingTimeInterval(-10) // expired 10s ago
        )
        let storage = InMemoryTokenStorage(initialTokens: expiredTokens)
        let provider = MockRefreshProvider()
        let manager = __MODULE_NAME__(storage: storage, provider: provider)

        let token = try await manager.validAccessToken(bufferSeconds: 60)
        XCTAssertTrue(token.hasPrefix("new_access_token_"))
        XCTAssertEqual(provider.refreshCallCount, 1)
    }

    func testSingleFlightConcurrentRefreshDeduplication() async throws {
        let expiredTokens = AuthTokens(
            accessToken: "old_token",
            refreshToken: "valid_refresh",
            expiresAt: Date().addingTimeInterval(-10)
        )
        let storage = InMemoryTokenStorage(initialTokens: expiredTokens)
        let provider = MockRefreshProvider()
        let manager = __MODULE_NAME__(storage: storage, provider: provider)

        // Launch 10 simultaneous concurrent calls
        try await withThrowingTaskGroup(of: String.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    try await manager.validAccessToken(bufferSeconds: 60)
                }
            }

            var tokens: [String] = []
            for try await token in group {
                tokens.append(token)
            }

            // All 10 callers must receive the EXACT same new token from single-flight execution
            XCTAssertEqual(tokens.count, 10)
            XCTAssertEqual(Set(tokens).count, 1)
        }

        // Must only invoke remote network refresh ONCE
        XCTAssertEqual(provider.refreshCallCount, 1)
    }

    func testAdaptInjectsAuthorizationHeader() async throws {
        let storage = InMemoryTokenStorage(
            initialTokens: AuthTokens(accessToken: "bearer_xyz", refreshToken: "ref", expiresInSeconds: 1200)
        )
        let manager = __MODULE_NAME__(storage: storage)

        let request = URLRequest(url: URL(string: "https://api.example.com/data")!)
        let adapted = await manager.adapt(request)

        XCTAssertEqual(adapted.value(forHTTPHeaderField: "Authorization"), "Bearer bearer_xyz")
    }

    func testOnSessionExpiredCallback() async throws {
        let expiredTokens = AuthTokens(accessToken: "bad_token", refreshToken: "bad_ref", expiresAt: Date().addingTimeInterval(-100))
        let storage = InMemoryTokenStorage(initialTokens: expiredTokens)
        let provider = MockRefreshProvider()
        provider.shouldFail = true

        let manager = __MODULE_NAME__(storage: storage, provider: provider)

        let expectation = expectation(description: "onSessionExpired called")
        await manager.setOnSessionExpired {
            expectation.fulfill()
        }

        do {
            _ = try await manager.validAccessToken()
            XCTFail("Expected token refresh to throw")
        } catch {
            XCTAssertTrue(true)
        }

        await fulfillment(of: [expectation], timeout: 2.0)
    }

    func testJWTPayloadAutoExtraction() {
        // Sample JWT with payload: {"sub":"user_123","exp":1893456000,"iss":"auth.mycompany.com"}
        let header = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
        let payload = "eyJzdWIiOiJ1c2VyXzEyMyIsImV4cCI6MTg5MzQ1NjAwMCwiaXNzIjoiYXV0aC5teWNvbXBhbnkuY29tIn0"
        let signature = "signature"
        let jwt = "\(header).\(payload).\(signature)"

        let tokens = AuthTokens(accessToken: jwt, refreshToken: "ref")
        XCTAssertNotNil(tokens.jwtClaims)
        XCTAssertEqual(tokens.jwtClaims?.sub, "user_123")
        XCTAssertEqual(tokens.jwtClaims?.iss, "auth.mycompany.com")
        XCTAssertEqual(tokens.expiresAt, Date(timeIntervalSince1970: 1893456000))
        XCTAssertFalse(tokens.isExpired(bufferSeconds: 60))
    }
}

