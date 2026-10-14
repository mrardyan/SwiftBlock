import Foundation

/// Thread-safe, actor-isolated token refresh manager with single-flight concurrency deduplication.
public actor __MODULE_NAME__ {
    public static let shared = __MODULE_NAME__()

    private let storage: TokenStorageProtocol
    private var provider: (any TokenRefreshProvider)?
    private var currentTokens: AuthTokens?
    private var isInitialized = false

    /// Single-flight task tracker to deduplicate multiple concurrent refresh requests.
    private var activeRefreshTask: Task<AuthTokens, any Error>?

    /// Callback triggered when session expires and cannot be refreshed (e.g. prompt login).
    public var onSessionExpired: (@Sendable () -> Void)?

    public init(
        storage: TokenStorageProtocol = KeychainTokenStorage(),
        provider: (any TokenRefreshProvider)? = nil
    ) {
        self.storage = storage
        self.provider = provider
    }

    /// Sets or updates the remote token refresh provider.
    public func setProvider(_ provider: any TokenRefreshProvider) {
        self.provider = provider
    }

    /// Sets the callback triggered when session expires and cannot be renewed.
    public func setOnSessionExpired(_ callback: (@Sendable () -> Void)?) {
        self.onSessionExpired = callback
    }

    /// Stores a new set of authentication tokens securely.
    public func updateTokens(_ tokens: AuthTokens) async throws {
        self.currentTokens = tokens
        try await storage.saveTokens(tokens)
    }

    /// Clears tokens from memory and secure storage (logout).
    public func clearTokens() async throws {
        self.currentTokens = nil
        self.activeRefreshTask?.cancel()
        self.activeRefreshTask = nil
        try await storage.clearTokens()
    }

    /// Retrieves a valid access token, automatically refreshing it if it is expired or close to expiring.
    public func validAccessToken(bufferSeconds: TimeInterval = 60) async throws -> String {
        try await ensureInitialized()

        guard let tokens = currentTokens else {
            throw TokenRefreshError.unauthenticated
        }

        if tokens.isExpired(bufferSeconds: bufferSeconds) {
            let refreshed = try await refreshToken()
            return refreshed.accessToken
        }

        return tokens.accessToken
    }

    /// Explicitly refreshes the session token with single-flight concurrency lock.
    @discardableResult
    public func refreshToken() async throws -> AuthTokens {
        try await ensureInitialized()

        // 1. If a refresh is already in flight, reuse the ongoing task
        if let existingTask = activeRefreshTask {
            return try await existingTask.value
        }

        guard let refreshToken = currentTokens?.refreshToken, !refreshToken.isEmpty else {
            notifySessionExpired()
            throw TokenRefreshError.missingRefreshToken
        }

        guard let provider = self.provider else {
            throw TokenRefreshError.networkError("TokenRefreshProvider is not configured.")
        }

        // 2. Spawn single-flight task
        let task = Task<AuthTokens, any Error> {
            do {
                let newTokens = try await provider.refresh(using: refreshToken)
                return newTokens
            } catch {
                throw error
            }
        }

        self.activeRefreshTask = task

        do {
            let refreshedTokens = try await task.value
            try await updateTokens(refreshedTokens)
            self.activeRefreshTask = nil
            return refreshedTokens
        } catch {
            self.activeRefreshTask = nil
            notifySessionExpired()
            throw TokenRefreshError.refreshFailed(underlying: error)
        }
    }

    // MARK: - HTTP Request Adaptation & Retry Interceptor

    /// Injects the Authorization header into an outgoing URLRequest.
    public func adapt(_ request: URLRequest, bufferSeconds: TimeInterval = 60) async -> URLRequest {
        var mutableRequest = request
        if let token = try? await validAccessToken(bufferSeconds: bufferSeconds) {
            let tokenType = currentTokens?.tokenType ?? "Bearer"
            mutableRequest.setValue("\(tokenType) \(token)", forHTTPHeaderField: "Authorization")
        }
        return mutableRequest
    }

    /// Intercepts an HTTP 401 response, refreshes the token, and returns a new URLRequest with updated credentials.
    public func retryOnUnauthorized(request: URLRequest) async throws -> (URLRequest, AuthTokens) {
        let newTokens = try await refreshToken()
        var updatedRequest = request
        updatedRequest.setValue("\(newTokens.tokenType) \(newTokens.accessToken)", forHTTPHeaderField: "Authorization")
        return (updatedRequest, newTokens)
    }

    // MARK: - Private Helpers

    private func ensureInitialized() async throws {
        guard !isInitialized else { return }
        if let stored = try await storage.loadTokens() {
            self.currentTokens = stored
        }
        self.isInitialized = true
    }

    private func notifySessionExpired() {
        onSessionExpired?()
    }
}
