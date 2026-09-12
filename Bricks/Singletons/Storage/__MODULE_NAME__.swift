import Foundation
import Security

/// Represents the target persistent storage location.
public enum StorageLocation: Sendable {
    case userDefaults(suiteName: String? = nil)
    case keychain(serviceName: String? = nil)
    case inMemory
}

/// Errors thrown by the storage engine.
public enum StorageError: Error, Equatable, Sendable {
    case encodingFailed
    case decodingFailed
    case itemNotFound
    case keychainError(status: Int32)
}

/// Interface for key-value persistence operations.
public protocol StorageProtocol: Sendable {
    func set<T: Encodable>(_ item: T, forKey key: String, location: StorageLocation) throws
    func get<T: Decodable>(_ type: T.Type, forKey key: String, location: StorageLocation) throws -> T?
    func remove(forKey key: String, location: StorageLocation)
    func clear(location: StorageLocation)
}

/// Unified, thread-safe persistence engine supporting UserDefaults, Keychain, and In-Memory storage.
public final class __MODULE_NAME__: @unchecked Sendable, StorageProtocol {
    /// Shared singleton instance.
    public static let shared = __MODULE_NAME__()

    private let lock = NSLock()
    private let defaultLocation: StorageLocation
    private var inMemoryStore: [String: Data] = [:]

    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

    /// Initializes storage instance with a default fallback location.
    public init(defaultLocation: StorageLocation = .userDefaults()) {
        self.defaultLocation = defaultLocation
    }

    /// Save an Encodable item to specified storage location.
    public func set<T: Encodable>(_ item: T, forKey key: String, location: StorageLocation? = nil) throws {
        lock.lock()
        defer { lock.unlock() }

        let data: Data
        do {
            data = try jsonEncoder.encode(item)
        } catch {
            throw StorageError.encodingFailed
        }

        let targetLocation = location ?? defaultLocation
        switch targetLocation {
        case .userDefaults(let suiteName):
            let defaults = suiteName.flatMap { UserDefaults(suiteName: $0) } ?? UserDefaults.standard
            defaults.set(data, forKey: key)

        case .keychain(let serviceName):
            let service = serviceName ?? Bundle.main.bundleIdentifier ?? "com.swiftblock.storage"
            saveToKeychain(key: key, data: data, service: service)

        case .inMemory:
            inMemoryStore[key] = data
        }
    }

    /// Retrieve a Decodable item from specified storage location.
    public func get<T: Decodable>(_ type: T.Type, forKey key: String, location: StorageLocation? = nil) throws -> T? {
        lock.lock()
        defer { lock.unlock() }

        let targetLocation = location ?? defaultLocation
        let data: Data?

        switch targetLocation {
        case .userDefaults(let suiteName):
            let defaults = suiteName.flatMap { UserDefaults(suiteName: $0) } ?? UserDefaults.standard
            data = defaults.data(forKey: key)

        case .keychain(let serviceName):
            let service = serviceName ?? Bundle.main.bundleIdentifier ?? "com.swiftblock.storage"
            data = loadFromKeychain(key: key, service: service)

        case .inMemory:
            data = inMemoryStore[key]
        }

        guard let data = data else { return nil }

        do {
            return try jsonDecoder.decode(type, from: data)
        } catch {
            throw StorageError.decodingFailed
        }
    }

    /// Protocol conformance requirement for non-optional location parameter.
    public func set<T: Encodable>(_ item: T, forKey key: String, location: StorageLocation) throws {
        try set(item, forKey: key, location: Optional(location))
    }

    /// Protocol conformance requirement for non-optional location parameter.
    public func get<T: Decodable>(_ type: T.Type, forKey key: String, location: StorageLocation) throws -> T? {
        return try get(type, forKey: key, location: Optional(location))
    }

    /// Removes an item associated with key from storage location.
    public func remove(forKey key: String, location: StorageLocation? = nil) {
        lock.lock()
        defer { lock.unlock() }

        let targetLocation = location ?? defaultLocation
        switch targetLocation {
        case .userDefaults(let suiteName):
            let defaults = suiteName.flatMap { UserDefaults(suiteName: $0) } ?? UserDefaults.standard
            defaults.removeObject(forKey: key)

        case .keychain(let serviceName):
            let service = serviceName ?? Bundle.main.bundleIdentifier ?? "com.swiftblock.storage"
            deleteFromKeychain(key: key, service: service)

        case .inMemory:
            inMemoryStore.removeValue(forKey: key)
        }
    }

    public func remove(forKey key: String, location: StorageLocation) {
        remove(forKey: key, location: Optional(location))
    }

    /// Clears data stored in target location.
    public func clear(location: StorageLocation? = nil) {
        lock.lock()
        defer { lock.unlock() }

        let targetLocation = location ?? defaultLocation
        switch targetLocation {
        case .userDefaults(let suiteName):
            let defaults = suiteName.flatMap { UserDefaults(suiteName: $0) } ?? UserDefaults.standard
            let dictionary = defaults.dictionaryRepresentation()
            for key in dictionary.keys {
                defaults.removeObject(forKey: key)
            }

        case .keychain(let serviceName):
            let service = serviceName ?? Bundle.main.bundleIdentifier ?? "com.swiftblock.storage"
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service
            ]
            SecItemDelete(query as CFDictionary)

        case .inMemory:
            inMemoryStore.removeAll()
        }
    }

    public func clear(location: StorageLocation) {
        clear(location: Optional(location))
    }

    // MARK: - Native Keychain Helpers

    private func saveToKeychain(key: String, data: Data, service: String) {
        deleteFromKeychain(key: key, service: service)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadFromKeychain(key: String, service: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        guard status == errSecSuccess, let data = dataTypeRef as? Data else {
            return nil
        }
        return data
    }

    private func deleteFromKeychain(key: String, service: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
