import Foundation

/// Represents a set of authentication tokens with optional expiration metadata.
public struct AuthTokens: Codable, Equatable, Sendable {
    public let accessToken: String
    public let refreshToken: String?
    public let tokenType: String
    public let expiresAt: Date?

    public init(
        accessToken: String,
        refreshToken: String? = nil,
        tokenType: String = "Bearer",
        expiresAt: Date? = nil
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenType = tokenType
        if let expiresAt {
            self.expiresAt = expiresAt
        } else if let claims = JWTClaims.decode(from: accessToken), let exp = claims.exp {
            self.expiresAt = Date(timeIntervalSince1970: exp)
        } else {
            self.expiresAt = nil
        }
    }

    /// Convenience initializer with lifetime in seconds from now.
    public init(
        accessToken: String,
        refreshToken: String? = nil,
        tokenType: String = "Bearer",
        expiresInSeconds: TimeInterval
    ) {
        self.init(
            accessToken: accessToken,
            refreshToken: refreshToken,
            tokenType: tokenType,
            expiresAt: Date().addingTimeInterval(expiresInSeconds)
        )
    }

    /// Returns parsed JWT claims if the access token is a valid JWT format.
    public var jwtClaims: JWTClaims? {
        JWTClaims.decode(from: accessToken)
    }

    /// Checks whether the token is expired or about to expire within the buffer window.
    public func isExpired(bufferSeconds: TimeInterval = 60) -> Bool {
        guard let expiresAt else { return false }
        return Date().addingTimeInterval(bufferSeconds) >= expiresAt
    }
}

/// Standard JWT claims parsed from an access token payload.
public struct JWTClaims: Codable, Equatable, Sendable {
    public let exp: TimeInterval?
    public let iat: TimeInterval?
    public let sub: String?
    public let iss: String?
    public let aud: String?

    public init(
        exp: TimeInterval? = nil,
        iat: TimeInterval? = nil,
        sub: String? = nil,
        iss: String? = nil,
        aud: String? = nil
    ) {
        self.exp = exp
        self.iat = iat
        self.sub = sub
        self.iss = iss
        self.aud = aud
    }

    /// Decodes standard JWT payload claims from a base64url-encoded JWT string.
    public static func decode(from jwt: String) -> JWTClaims? {
        let parts = jwt.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        var base64 = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64.append("=")
        }
        guard let data = Data(base64Encoded: base64) else { return nil }
        return try? JSONDecoder().decode(JWTClaims.self, from: data)
    }
}

/// Errors that can occur during token management and refreshing.
public enum TokenRefreshError: Error, LocalizedError, Sendable {
    case unauthenticated
    case missingRefreshToken
    case refreshFailed(underlying: any Error)
    case sessionExpired
    case networkError(String)

    public var errorDescription: String? {
        switch self {
        case .unauthenticated:
            return "No active session tokens found."
        case .missingRefreshToken:
            return "Cannot refresh session: refresh token is missing."
        case let .refreshFailed(underlying):
            return "Token refresh failed: \(underlying.localizedDescription)"
        case .sessionExpired:
            return "The user session has expired and cannot be renewed. Please log in again."
        case let .networkError(message):
            return "Network error during token refresh: \(message)"
        }
    }
}

/// Protocol implemented by the network service or auth client to exchange a refresh token for new tokens.
public protocol TokenRefreshProvider: Sendable {
    func refresh(using refreshToken: String) async throws -> AuthTokens
}

/// Protocol for secure persistent storage of authentication credentials.
public protocol TokenStorageProtocol: Sendable {
    func loadTokens() async throws -> AuthTokens?
    func saveTokens(_ tokens: AuthTokens) async throws
    func clearTokens() async throws
}
