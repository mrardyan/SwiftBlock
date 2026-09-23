import Foundation

/// Last-In-First-Out (LIFO) Stack data structure.
public struct __MODULE_NAME__<Element: Sendable>: Sendable, ExpressibleByArrayLiteral, Sequence {
    private var storage: [Element] = []

    /// Creates an empty Stack.
    public init() {}

    /// Creates a Stack from an array literal.
    public init(arrayLiteral elements: Element...) {
        self.storage = elements
    }

    /// Creates a Stack from a sequence.
    public init<S: Sequence>(_ sequence: S) where S.Element == Element {
        self.storage = Array(sequence)
    }

    /// Number of elements currently in the stack.
    public var count: Int {
        storage.count
    }

    /// Returns `true` if the stack is empty.
    public var isEmpty: Bool {
        storage.isEmpty
    }

    /// Inspects top element without removing it ($O(1)$).
    public var top: Element? {
        storage.last
    }

    /// Pushes a new element onto the top of the stack ($O(1)$).
    public mutating func push(_ element: Element) {
        storage.append(element)
    }

    /// Removes and returns the top element of the stack ($O(1)$).
    @discardableResult
    public mutating func pop() -> Element? {
        storage.popLast()
    }

    /// Removes all elements from the stack.
    public mutating func clear() {
        storage.removeAll()
    }

    // MARK: - Sequence Conformance
    public func makeIterator() -> IndexingIterator<[Element]> {
        storage.reversed().makeIterator()
    }
}
