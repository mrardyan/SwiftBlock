import Foundation

private final class LRUNode<Key: Hashable, Value> {
    let key: Key
    var value: Value
    var prev: LRUNode?
    var next: LRUNode?

    init(key: Key, value: Value) {
        self.key = key
        self.value = value
    }
}

/// Thread-safe $O(1)$ Least Recently Used (LRU) Cache.
///
/// Implemented using a doubly linked list and dictionary mapping for $O(1)$ access and eviction.
public final class __MODULE_NAME__<Key: Hashable & Sendable, Value: Sendable>: @unchecked Sendable {
    public let capacity: Int
    private var count = 0
    private var nodes: [Key: LRUNode<Key, Value>] = [:]
    private var head: LRUNode<Key, Value>? // Most recently used
    private var tail: LRUNode<Key, Value>? // Least recently used
    private let lock = NSLock()

    /// Creates an LRU cache with the specified capacity limit.
    public init(capacity: Int) {
        self.capacity = max(1, capacity)
    }

    /// Retrieves the value for the given key, updating its recency to the head.
    public func get(_ key: Key) -> Value? {
        lock.lock()
        defer { lock.unlock() }

        guard let node = nodes[key] else { return nil }
        moveToHead(node)
        return node.value
    }

    /// Inserts or updates the value for the given key, evicting the oldest item if capacity is exceeded.
    public func set(_ value: Value, forKey key: Key) {
        lock.lock()
        defer { lock.unlock() }

        if let existingNode = nodes[key] {
            existingNode.value = value
            moveToHead(existingNode)
            return
        }

        let newNode = LRUNode(key: key, value: value)
        nodes[key] = newNode
        insertAtHead(newNode)
        count += 1

        if count > capacity {
            evictLRU()
        }
    }

    /// Removes the entry for the specified key.
    @discardableResult
    public func remove(_ key: Key) -> Value? {
        lock.lock()
        defer { lock.unlock() }

        guard let node = nodes.removeValue(forKey: key) else { return nil }
        removeNode(node)
        count -= 1
        return node.value
    }

    /// Clears all entries from the cache.
    public func removeAll() {
        lock.lock()
        defer { lock.unlock() }

        nodes.removeAll()
        head = nil
        tail = nil
        count = 0
    }

    /// Current number of items in cache.
    public var currentCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }

    // MARK: - Linked List Internals

    private func moveToHead(_ node: LRUNode<Key, Value>) {
        guard node !== head else { return }
        removeNode(node)
        insertAtHead(node)
    }

    private func insertAtHead(_ node: LRUNode<Key, Value>) {
        node.next = head
        node.prev = nil
        head?.prev = node
        head = node

        if tail == nil {
            tail = node
        }
    }

    private func removeNode(_ node: LRUNode<Key, Value>) {
        node.prev?.next = node.next
        node.next?.prev = node.prev

        if node === head {
            head = node.next
        }
        if node === tail {
            tail = node.prev
        }

        node.prev = nil
        node.next = nil
    }

    private func evictLRU() {
        guard let lru = tail else { return }
        nodes.removeValue(forKey: lru.key)
        removeNode(lru)
        count -= 1
    }
}
