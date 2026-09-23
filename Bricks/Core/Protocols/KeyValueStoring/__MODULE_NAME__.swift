import Foundation

/// Universal protocol contract for key-value storage (Memory, Disk, Keychain, Database).
public protocol __MODULE_NAME__: Sendable {
    func get<T: Codable & Sendable>(_ type: T.Type, forKey key: String) throws -> T?
    func set<T: Codable & Sendable>(_ value: T?, forKey key: String) throws
    func remove(forKey key: String) throws
    func removeAll() throws
}

// MARK: - In-Memory Reference Implementation
public final class InMemoryKeyValueStore: __MODULE_NAME__, @unchecked Sendable {
    private var storage: [String: Data] = [:]
    private let lock = NSLock()

    public init() {}

    public func get<T: Codable & Sendable>(_ type: T.Type, forKey key: String) throws -> T? {
        lock.lock()
        defer { lock.unlock() }
        guard let data = storage[key] else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }

    public func set<T: Codable & Sendable>(_ value: T?, forKey key: String) throws {
        lock.lock()
        defer { lock.unlock() }
        guard let value = value else {
            storage.removeValue(forKey: key)
            return
        }
        let data = try JSONEncoder().encode(value)
        storage[key] = data
    }

    public func remove(forKey key: String) throws {
        lock.lock()
        defer { lock.unlock() }
        storage.removeValue(forKey: key)
    }

    public func removeAll() throws {
        lock.lock()
        defer { lock.unlock() }
        storage.removeAll()
    }
}
