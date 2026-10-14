import Foundation
import Security

/// Keychain-backed secure storage for authentication tokens.
public final class KeychainTokenStorage: TokenStorageProtocol {
    private let serviceName: String
    private let accountKey: String

    public init(
        serviceName: String = Bundle.main.bundleIdentifier ?? "com.swiftblock.tokens",
        accountKey: String = "auth_tokens"
    ) {
        self.serviceName = serviceName
        self.accountKey = accountKey
    }

    public func loadTokens() async throws -> AuthTokens? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }

        return try JSONDecoder().decode(AuthTokens.self, from: data)
    }

    public func saveTokens(_ tokens: AuthTokens) async throws {
        let data = try JSONEncoder().encode(tokens)
        try await clearTokens()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess || status == errSecDuplicateItem else {
            throw TokenRefreshError.networkError("Failed to store tokens in Keychain (OSStatus: \(status))")
        }
    }

    public func clearTokens() async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountKey
        ]
        SecItemDelete(query as CFDictionary)
    }
}

/// In-memory storage useful for unit testing, previews, and guest sessions.
public actor InMemoryTokenStorage: TokenStorageProtocol {
    private var tokens: AuthTokens?

    public init(initialTokens: AuthTokens? = nil) {
        self.tokens = initialTokens
    }

    public func loadTokens() async throws -> AuthTokens? {
        tokens
    }

    public func saveTokens(_ tokens: AuthTokens) async throws {
        self.tokens = tokens
    }

    public func clearTokens() async throws {
        self.tokens = nil
    }
}
