import Foundation

/// Set collection that maintains unique elements while preserving exact insertion order.
public struct __MODULE_NAME__<Element: Hashable & Sendable>: Sendable, ExpressibleByArrayLiteral, Sequence {
    private var orderedElements: [Element] = []
    private var set: Set<Element> = []

    /// Creates an empty OrderedSet.
    public init() {}

    /// Creates an OrderedSet from an array literal.
    public init(arrayLiteral elements: Element...) {
        for element in elements {
            append(element)
        }
    }

    /// Creates an OrderedSet from a sequence, dropping duplicates while keeping first occurrence order.
    public init<S: Sequence>(_ sequence: S) where S.Element == Element {
        for element in sequence {
            append(element)
        }
    }

    /// Number of elements in the set.
    public var count: Int {
        orderedElements.count
    }

    /// Returns `true` if the set contains no elements.
    public var isEmpty: Bool {
        orderedElements.isEmpty
    }

    /// Appends a new unique element to the set. Returns `true` if inserted, `false` if already present.
    @discardableResult
    public mutating func append(_ element: Element) -> Bool {
        guard !set.contains(element) else { return false }
        set.insert(element)
        orderedElements.append(element)
        return true
    }

    /// Checks if the element exists in the set ($O(1)$).
    public func contains(_ element: Element) -> Bool {
        set.contains(element)
    }

    /// Element at the specified sequential index ($O(1)$).
    public subscript(index: Int) -> Element {
        orderedElements[index]
    }

    /// Removes an element from the set. Returns `true` if removed.
    @discardableResult
    public mutating func remove(_ element: Element) -> Bool {
        guard set.remove(element) != nil else { return false }
        if let index = orderedElements.firstIndex(of: element) {
            orderedElements.remove(at: index)
        }
        return true
    }

    /// Removes all elements.
    public mutating func removeAll() {
        orderedElements.removeAll()
        set.removeAll()
    }

    /// Ordered array representation of elements.
    public var elements: [Element] {
        orderedElements
    }

    // MARK: - Sequence Conformance
    public func makeIterator() -> IndexingIterator<[Element]> {
        orderedElements.makeIterator()
    }
}
