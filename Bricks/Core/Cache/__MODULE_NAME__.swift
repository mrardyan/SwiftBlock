import Foundation

private struct CacheEntry<Value: Sendable>: Sendable {
    let value: Value
    let expirationDate: Date?

    var isExpired: Bool {
        guard let expirationDate = expirationDate else { return false }
        return Date() > expirationDate
    }
}

/// Protocol for in-memory caching operations.
public protocol CacheProtocol: Sendable {
    func set<T: Sendable>(_ value: T, forKey key: String, timeToLive: TimeInterval?)
    func get<T: Sendable>(_ type: T.Type, forKey key: String) -> T?
    func remove(forKey key: String)
    func removeAll()
}

/// Thread-safe in-memory caching engine with LRU eviction and expiration policies.
public final class __MODULE_NAME__: @unchecked Sendable, CacheProtocol {
    public static let shared = __MODULE_NAME__()

    private let lock = NSLock()
    private var storage: [String: Any] = [:]
    private var keyOrder: [String] = []
    private let defaultTTL: TimeInterval?
    private let maxCount: Int?

    public init(defaultTTL: TimeInterval? = nil, maxCount: Int? = 100) {
        self.defaultTTL = defaultTTL
        self.maxCount = maxCount
    }

    public func set<T: Sendable>(_ value: T, forKey key: String, timeToLive: TimeInterval? = nil) {
        lock.lock()
        defer { lock.unlock() }

        let ttl = timeToLive ?? defaultTTL
        let expiration = ttl.map { Date().addingTimeInterval($0) }
        let entry = CacheEntry(value: value, expirationDate: expiration)

        if let index = keyOrder.firstIndex(of: key) {
            keyOrder.remove(at: index)
        } else if let max = maxCount, storage.count >= max, !keyOrder.isEmpty {
            let evictedKey = keyOrder.removeFirst()
            storage.removeValue(forKey: evictedKey)
        }

        keyOrder.append(key)
        storage[key] = entry
    }

    public func get<T: Sendable>(_ type: T.Type, forKey key: String) -> T? {
        lock.lock()
        defer { lock.unlock() }

        guard let entry = storage[key] as? CacheEntry<T> else {
            return nil
        }

        if entry.isExpired {
            storage.removeValue(forKey: key)
            if let index = keyOrder.firstIndex(of: key) {
                keyOrder.remove(at: index)
            }
            return nil
        }

        // Move to back (most recently used)
        if let index = keyOrder.firstIndex(of: key) {
            keyOrder.remove(at: index)
            keyOrder.append(key)
        }

        return entry.value
    }

    public func remove(forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        storage.removeValue(forKey: key)
        if let index = keyOrder.firstIndex(of: key) {
            keyOrder.remove(at: index)
        }
    }

    public func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        storage.removeAll()
        keyOrder.removeAll()
    }
}
