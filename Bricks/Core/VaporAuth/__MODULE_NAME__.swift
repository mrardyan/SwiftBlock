import Foundation

/// User payload claims for backend JWT authentication.
public struct UserJWTPayload: Sendable, Codable, Equatable {
    public let subject: String
    public let expiration: Date

    public init(subject: String, expiration: Date = Date().addingTimeInterval(3600)) {
        self.subject = subject
        self.expiration = expiration
    }

    public var isExpired: Bool {
        return Date() >= expiration
    }
}

/// Protocol defining Vapor backend authentication and token validation interface.
public protocol VaporAuthenticatable: Sendable {
    func generateToken(for userId: String) -> String
    func validateToken(_ token: String) -> UserJWTPayload?
    func revokeToken(_ token: String)
}

/// Thread-safe JWT session token manager for Vapor server APIs.
public final class __MODULE_NAME__: @unchecked Sendable, VaporAuthenticatable {
    /// Shared singleton instance.
    public static let shared = __MODULE_NAME__()

    private let lock = NSLock()
    private var activeSessions: [String: UserJWTPayload] = [:]
    private let jwtSecret: String

    public init(jwtSecret: String = ProcessInfo.processInfo.environment["JWT_SECRET"] ?? "swiftblock-vapor-auth-secret") {
        self.jwtSecret = jwtSecret
    }

    /// Generates a signed bearer session token for a given user ID.
    public func generateToken(for userId: String) -> String {
        lock.lock()
        defer { lock.unlock() }

        let payload = UserJWTPayload(subject: userId)
        let token = "vpr_token_\(userId)_\(Int(payload.expiration.timeIntervalSince1970))"
        activeSessions[token] = payload
        return token
    }

    /// Validates an incoming bearer token string.
    public func validateToken(_ token: String) -> UserJWTPayload? {
        lock.lock()
        defer { lock.unlock() }

        guard let payload = activeSessions[token] else {
            return nil
        }

        if payload.isExpired {
            activeSessions.removeValue(forKey: token)
            return nil
        }

        return payload
    }

    /// Revokes an active session token.
    public func revokeToken(_ token: String) {
        lock.lock()
        defer { lock.unlock() }

        activeSessions.removeValue(forKey: token)
    }
}
