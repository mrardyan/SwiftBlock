import Foundation

/// Dictionary structure maintaining strict key insertion order while retaining $O(1)$ key-based lookups.
public struct __MODULE_NAME__<Key: Hashable & Sendable, Value: Sendable>: Sendable, ExpressibleByDictionaryLiteral, Sequence {
    public typealias Element = (key: Key, value: Value)

    private var orderedKeys: [Key] = []
    private var values: [Key: Value] = [:]

    /// Creates an empty OrderedDictionary.
    public init() {}

    /// Creates an OrderedDictionary from a dictionary literal.
    public init(dictionaryLiteral elements: (Key, Value)...) {
        for (key, value) in elements {
            self[key] = value
        }
    }

    /// Number of key-value pairs stored.
    public var count: Int {
        orderedKeys.count
    }

    /// Returns `true` if the dictionary contains no entries.
    public var isEmpty: Bool {
        orderedKeys.isEmpty
    }

    /// Ordered array of all keys.
    public var keys: [Key] {
        orderedKeys
    }

    /// Ordered array of all values.
    public var elementsList: [Value] {
        orderedKeys.compactMap { values[$0] }
    }

    /// Accesses the value associated with the given key for reading and writing.
    public subscript(key: Key) -> Value? {
        get {
            values[key]
        }
        set {
            if let newValue = newValue {
                if values[key] == nil {
                    orderedKeys.append(key)
                }
                values[key] = newValue
            } else {
                removeValue(forKey: key)
            }
        }
    }

    /// Accesses the key-value pair at the specified sequential index ($O(1)$).
    public subscript(index: Int) -> Element {
        let key = orderedKeys[index]
        return (key, values[key]!)
    }

    /// Removes and returns the value associated with the specified key.
    @discardableResult
    public mutating func removeValue(forKey key: Key) -> Value? {
        guard let value = values.removeValue(forKey: key) else { return nil }
        if let idx = orderedKeys.firstIndex(of: key) {
            orderedKeys.remove(at: idx)
        }
        return value
    }

    /// Removes all key-value pairs.
    public mutating func removeAll() {
        orderedKeys.removeAll()
        values.removeAll()
    }

    // MARK: - Sequence Conformance
    public func makeIterator() -> IndexingIterator<[Element]> {
        let pairs = orderedKeys.compactMap { key -> Element? in
            guard let val = values[key] else { return nil }
            return (key, val)
        }
        return pairs.makeIterator()
    }
}
