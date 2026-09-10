import Foundation
import Security

/// Abstract persistence storage interface for saving and loading Codable entities.
public protocol Storage {
    /// Encodes and saves a Codable object under the specified key.
    func save<T: Codable>(_ item: T, forKey key: String) throws

    /// Loads and decodes a Codable object for the given key if present.
    func load<T: Codable>(forKey key: String, as type: T.Type) throws -> T?

    /// Removes the stored item associated with the given key.
    func remove(forKey key: String)
}

/// Secure Keychain-backed local storage implementation.
public final class __MODULE_NAME__: Storage {
    private let service: String

    /// Initializes a Keychain storage manager with specified service identifier.
    /// - Parameter service: Keychain service grouping key (defaults to main bundle identifier).
    public init(service: String = Bundle.main.bundleIdentifier ?? "com.example") {
        self.service = service
    }

    /// Encodes and saves a Codable value into iOS Keychain generic password items.
    public func save<T: Codable>(_ item: T, forKey key: String) throws {
        let data = try JSONEncoder().encode(item)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    /// Retrieves and decodes a Codable value from iOS Keychain generic password items.
    public func load<T: Codable>(forKey key: String, as type: T.Type) throws -> T? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess, let data = dataTypeRef as? Data else {
            throw KeychainError.unhandledError(status: status)
        }

        return try JSONDecoder().decode(type, from: data)
    }

    /// Deletes a value from iOS Keychain associated with the given key.
    public func remove(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

/// Errors thrown by Keychain storage operations.
public enum KeychainError: Error, LocalizedError {
    case unhandledError(status: OSStatus)

    /// Human-readable error description.
    public var errorDescription: String? {
        switch self {
        case .unhandledError(let status):
            return "Keychain operation failed with OSStatus: \(status)."
        }
    }
}
