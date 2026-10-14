import Foundation

/// Default implementation of `__MODULE_NAME__Repository`.
public final class Default__MODULE_NAME__Repository: @unchecked Sendable, __MODULE_NAME__Repository {
{{#if strategy == 'offline-first'}}
    private let lock = NSLock()
    private var cache: [__MODULE_NAME__Item] = []

    public init() {}

    private func getCachedItems() -> [__MODULE_NAME__Item] {
        lock.lock()
        defer { lock.unlock() }
        return cache
    }

    private func saveCachedItem(_ item: __MODULE_NAME__Item) {
        lock.lock()
        defer { lock.unlock() }
        if let idx = cache.firstIndex(where: { $0.id == item.id }) {
            cache[idx] = item
        } else {
            cache.append(item)
        }
    }

    private func deleteCachedItem(id: String) {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAll(where: { $0.id == id })
    }

    public func fetch() async throws -> [__MODULE_NAME__Item] {
        return getCachedItems()
    }

    public func save(_ item: __MODULE_NAME__Item) async throws {
        saveCachedItem(item)
    }

    public func delete(id: String) async throws {
        deleteCachedItem(id: id)
    }
{{else}}
    public init() {}

    public func fetch() async throws -> [__MODULE_NAME__Item] {
        // Fetch logic here
        return []
    }

    public func save(_ item: __MODULE_NAME__Item) async throws {
        // Save logic here
    }

    public func delete(id: String) async throws {
        // Delete logic here
    }
{{/if}}
}