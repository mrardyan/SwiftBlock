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
{{#if concurrency == 'swift-concurrency'}}
    var currentState: SessionState { get async }
    var accessToken: String? { get async }
    func setSession(accessToken: String, userId: String) async
    func clearSession() async
{{else}}
    var currentState: SessionState { get }
    var accessToken: String? { get }
    func setSession(accessToken: String, userId: String)
    func clearSession()
{{/if}}
}

{{#if concurrency == 'swift-concurrency'}}
/// Actor-isolated user session state manager with native Keychain persistence.
public actor __MODULE_NAME__: Authenticatable {
    /// Shared singleton instance.
    public static let shared = __MODULE_NAME__()

    private let serviceName: String

    private var _currentState: SessionState = .unauthenticated
    private var _accessToken: String?
    public weak var delegate: SessionDelegate?

    public var currentState: SessionState { _currentState }
    public var accessToken: String? { _accessToken }

    /// Initializes auth manager and restores existing session from Keychain.
    public init(serviceName: String = Bundle.main.bundleIdentifier ?? "com.swiftblock.auth") {
        self.serviceName = serviceName
        restoreSessionFromKeychain()
    }

    /// Stores access token & userId securely in Keychain and updates session state.
    public func setSession(accessToken: String, userId: String) {
        saveToKeychain(key: "access_token", value: accessToken)
        saveToKeychain(key: "user_id", value: userId)

        self._accessToken = accessToken
        let newState = SessionState.authenticated(userId: userId)
        self._currentState = newState
        delegate?.sessionStateDidChange(newState)
    }

    /// Clears session tokens from Keychain and resets state to unauthenticated.
    public func clearSession() {
        deleteFromKeychain(key: "access_token")
        deleteFromKeychain(key: "user_id")

        self._accessToken = nil
        self._currentState = .unauthenticated
        delegate?.sessionStateDidChange(.unauthenticated)
    }

    private func restoreSessionFromKeychain() {
        if let token = loadFromKeychain(key: "access_token"),
           let userId = loadFromKeychain(key: "user_id"),
           !token.isEmpty, !userId.isEmpty {
            self._accessToken = token
            self._currentState = .authenticated(userId: userId)
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
{{else}}
/// Thread-safe user session state manager with native Keychain persistence.
public final class __MODULE_NAME__: @unchecked Sendable, Authenticatable {
    /// Shared singleton instance.
    public static let shared = __MODULE_NAME__()

    private let lock = NSLock()
    private let serviceName: String

    private var _currentState: SessionState = .unauthenticated
    private var _accessToken: String?
    private weak var _delegate: SessionDelegate?

    public var currentState: SessionState {
        lock.lock()
        defer { lock.unlock() }
        return _currentState
    }

    public var accessToken: String? {
        lock.lock()
        defer { lock.unlock() }
        return _accessToken
    }

    public var delegate: SessionDelegate? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _delegate
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _delegate = newValue
        }
    }

    /// Initializes auth manager and restores existing session from Keychain.
    public init(serviceName: String = Bundle.main.bundleIdentifier ?? "com.swiftblock.auth") {
        self.serviceName = serviceName
        restoreSessionFromKeychain()
    }

    /// Stores access token & userId securely in Keychain and updates session state.
    public func setSession(accessToken: String, userId: String) {
        saveToKeychain(key: "access_token", value: accessToken)
        saveToKeychain(key: "user_id", value: userId)

        let delegateToNotify: SessionDelegate?
        let newState = SessionState.authenticated(userId: userId)

        lock.lock()
        self._accessToken = accessToken
        self._currentState = newState
        delegateToNotify = self._delegate
        lock.unlock()

        delegateToNotify?.sessionStateDidChange(newState)
    }

    /// Clears session tokens from Keychain and resets state to unauthenticated.
    public func clearSession() {
        deleteFromKeychain(key: "access_token")
        deleteFromKeychain(key: "user_id")

        let delegateToNotify: SessionDelegate?
        let newState = SessionState.unauthenticated

        lock.lock()
        self._accessToken = nil
        self._currentState = newState
        delegateToNotify = self._delegate
        lock.unlock()

        delegateToNotify?.sessionStateDidChange(newState)
    }

    private func restoreSessionFromKeychain() {
        if let token = loadFromKeychain(key: "access_token"),
           let userId = loadFromKeychain(key: "user_id"),
           !token.isEmpty, !userId.isEmpty {
            lock.lock()
            self._accessToken = token
            self._currentState = .authenticated(userId: userId)
            lock.unlock()
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
{{/if}}
