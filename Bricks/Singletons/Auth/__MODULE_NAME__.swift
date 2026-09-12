import Foundation
import Security

/// Authentication state of a user session.
public enum SessionState: Equatable, Sendable {
    case unauthenticated
    case authenticated(userId: String)
}

/// A delegate that receives session state changes.
public protocol SessionDelegate: AnyObject, Sendable {
    func sessionStateDidChange(_ state: SessionState)
}

/// Interface for managing user authentication state and session tokens.
public protocol Authenticatable: Sendable {
    var currentState: SessionState { get }
    var accessToken: String? { get }
    func setSession(accessToken: String, userId: String)
    func clearSession()
}

/// Thread-safe user session state manager with native Keychain persistence.
public final class __MODULE_NAME__: @unchecked Sendable, Authenticatable {
    /// Shared singleton instance.
    public static let shared = __MODULE_NAME__()

    private let lock = NSLock()
    private let serviceName: String

    public private(set) var currentState: SessionState = .unauthenticated
    public private(set) var accessToken: String?
    public weak var delegate: SessionDelegate?

    /// Initializes auth manager and restores existing session from Keychain.
    public init(serviceName: String = Bundle.main.bundleIdentifier ?? "com.swiftblock.auth") {
        self.serviceName = serviceName
        restoreSessionFromKeychain()
    }

    /// Stores access token & userId securely in Keychain and updates session state.
    public func setSession(accessToken: String, userId: String) {
        lock.lock()
        defer { lock.unlock() }

        saveToKeychain(key: "access_token", value: accessToken)
        saveToKeychain(key: "user_id", value: userId)

        self.accessToken = accessToken
        self.currentState = .authenticated(userId: userId)
        delegate?.sessionStateDidChange(currentState)
    }

    /// Clears session tokens from Keychain and resets state to unauthenticated.
    public func clearSession() {
        lock.lock()
        defer { lock.unlock() }

        deleteFromKeychain(key: "access_token")
        deleteFromKeychain(key: "user_id")

        self.accessToken = nil
        self.currentState = .unauthenticated
        delegate?.sessionStateDidChange(.unauthenticated)
    }

    private func restoreSessionFromKeychain() {
        lock.lock()
        defer { lock.unlock() }

        if let token = loadFromKeychain(key: "access_token"),
           let userId = loadFromKeychain(key: "user_id"),
           !token.isEmpty, !userId.isEmpty {
            self.accessToken = token
            self.currentState = .authenticated(userId: userId)
        }
    }

    // MARK: - Native Keychain Helpers

    private func saveToKeychain(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        deleteFromKeychain(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        guard status == errSecSuccess, let data = dataTypeRef as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
