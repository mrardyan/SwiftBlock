import Foundation
import Security

public enum KeychainError: Error, LocalizedError, Sendable {
    case unhandledError(status: OSStatus)
    case itemNotFound

    public var errorDescription: String? {
        switch self {
        case .unhandledError(let status):
            return "Keychain operation failed with status \(status)."
        case .itemNotFound:
            return "Keychain item not found."
        }
    }
}

/// Protocol for Keychain-backed secure storage operations.
public protocol KeychainProtocol: Sendable {
    func set(_ data: Data, forKey key: String, service: String?) throws
    func getData(forKey key: String, service: String?) throws -> Data?
    func delete(forKey key: String, service: String?) throws
}

/// Secure credential and token storage backed by the system Keychain.
public final class __MODULE_NAME__: @unchecked Sendable, KeychainProtocol {
    public static let shared = __MODULE_NAME__()

    private let defaultService: String
    private let accessGroup: String?

    public init(
        defaultService: String = Bundle.main.bundleIdentifier ?? "com.swiftblock.keychain",
        accessGroup: String? = nil
    ) {
        self.defaultService = defaultService
        self.accessGroup = accessGroup
    }

    public func set(_ data: Data, forKey key: String, service: String? = nil) throws {
        var query = baseQuery(forKey: key, service: service)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem {
            let updateStatus = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.unhandledError(status: updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.unhandledError(status: status)
        }
    }

    public func getData(forKey key: String, service: String? = nil) throws -> Data? {
        var query = baseQuery(forKey: key, service: service)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
        return result as? Data
    }

    public func delete(forKey key: String, service: String? = nil) throws {
        let status = SecItemDelete(baseQuery(forKey: key, service: service) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    private func baseQuery(forKey key: String, service: String?) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service ?? defaultService,
            kSecAttrAccount as String: key
        ]
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        return query
    }
}