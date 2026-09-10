import Foundation
import Security

public protocol Storage {
    func save<T: Codable>(_ item: T, forKey key: String) throws
    func load<T: Codable>(forKey key: String, as type: T.Type) throws -> T?
    func remove(forKey key: String)
}

public final class __MODULE_NAME__: Storage {
    private let service: String

    public init(service: String = Bundle.main.bundleIdentifier ?? "com.example") {
        self.service = service
    }

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

    public func remove(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

public enum KeychainError: Error, LocalizedError {
    case unhandledError(status: OSStatus)

    public var errorDescription: String? {
        switch self {
        case .unhandledError(let status):
            return "Keychain operation failed with OSStatus: \(status)."
        }
    }
}
