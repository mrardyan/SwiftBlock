import Foundation
import Security

/// Accessibility rules for keychain items.
public enum SecureStorageAccessibility: Sendable {
    case whenUnlocked
    case whenUnlockedThisDeviceOnly
    case afterFirstUnlock
    case afterFirstUnlockThisDeviceOnly

    #if canImport(Security)
    var rawValue: CFString {
        switch self {
        case .whenUnlocked: return kSecAttrAccessibleWhenUnlocked
        case .whenUnlockedThisDeviceOnly: return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .afterFirstUnlock: return kSecAttrAccessibleAfterFirstUnlock
        case .afterFirstUnlockThisDeviceOnly: return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        }
    }
    #endif
}

/// Errors thrown by SecureStorage operations.
public enum SecureStorageError: Error, Equatable, Sendable {
    case encodingFailed
    case decodingFailed
    case itemNotFound
    case osStatusError(status: Int32)
}

/// Protocol for secure storage operations.
public protocol SecureStorageProtocol: Sendable {
    func set(_ string: String, forKey key: String, accessibility: SecureStorageAccessibility) throws
    func get(forKey key: String) throws -> String?
    func set<T: Encodable>(_ item: T, forKey key: String, accessibility: SecureStorageAccessibility) throws
    func get<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T?
    func remove(forKey key: String) throws
    func clear() throws
}

/// Thread-safe secure storage engine for credentials and sensitive tokens.
public final class __MODULE_NAME__: @unchecked Sendable, SecureStorageProtocol {
    public static let shared = __MODULE_NAME__()

    private let lock = NSLock()
    private let serviceName: String
    private let useInMemoryMock: Bool
    private var inMemoryStore: [String: Data] = [:]

    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

    public init(serviceName: String = Bundle.main.bundleIdentifier ?? "com.app.securestorage", useInMemoryMock: Bool = false) {
        self.serviceName = serviceName
        self.useInMemoryMock = useInMemoryMock
    }

    // MARK: - String API

    public func set(_ string: String, forKey key: String, accessibility: SecureStorageAccessibility = .afterFirstUnlock) throws {
        guard let data = string.data(using: .utf8) else {
            throw SecureStorageError.encodingFailed
        }
        try set(data: data, forKey: key, accessibility: accessibility)
    }

    public func get(forKey key: String) throws -> String? {
        guard let data = try getData(forKey: key) else { return nil }
        guard let string = String(data: data, encoding: .utf8) else {
            throw SecureStorageError.decodingFailed
        }
        return string
    }

    // MARK: - Codable API

    public func set<T: Encodable>(_ item: T, forKey key: String, accessibility: SecureStorageAccessibility = .afterFirstUnlock) throws {
        let data: Data
        do {
            data = try jsonEncoder.encode(item)
        } catch {
            throw SecureStorageError.encodingFailed
        }
        try set(data: data, forKey: key, accessibility: accessibility)
    }

    public func get<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = try getData(forKey: key) else { return nil }
        do {
            return try jsonDecoder.decode(T.self, from: data)
        } catch {
            throw SecureStorageError.decodingFailed
        }
    }

    // MARK: - Raw Data API

    public func set(data: Data, forKey key: String, accessibility: SecureStorageAccessibility = .afterFirstUnlock) throws {
        lock.lock()
        defer { lock.unlock() }

        if useInMemoryMock {
            inMemoryStore[key] = data
            return
        }

        #if canImport(Security)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessibility.rawValue
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SecureStorageError.osStatusError(status: status)
        }
        #else
        inMemoryStore[key] = data
        #endif
    }

    public func getData(forKey key: String) throws -> Data? {
        lock.lock()
        defer { lock.unlock() }

        if useInMemoryMock {
            return inMemoryStore[key]
        }

        #if canImport(Security)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess, let data = item as? Data else {
            throw SecureStorageError.osStatusError(status: status)
        }
        return data
        #else
        return inMemoryStore[key]
        #endif
    }

    public func remove(forKey key: String) throws {
        lock.lock()
        defer { lock.unlock() }

        if useInMemoryMock {
            inMemoryStore.removeValue(forKey: key)
            return
        }

        #if canImport(Security)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw SecureStorageError.osStatusError(status: status)
        }
        #else
        inMemoryStore.removeValue(forKey: key)
        #endif
    }

    public func clear() throws {
        lock.lock()
        defer { lock.unlock() }

        if useInMemoryMock {
            inMemoryStore.removeAll()
            return
        }

        #if canImport(Security)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw SecureStorageError.osStatusError(status: status)
        }
        #else
        inMemoryStore.removeAll()
        #endif
    }
}
