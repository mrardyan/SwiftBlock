import Foundation

/// First-In-First-Out (FIFO) Queue implemented with two stacks for amortized $O(1)$ operations.
public struct __MODULE_NAME__<Element: Sendable>: Sendable, ExpressibleByArrayLiteral, Sequence {
    private var inStack: [Element] = []
    private var outStack: [Element] = []

    /// Creates an empty Queue.
    public init() {}

    /// Creates a Queue from an array literal.
    public init(arrayLiteral elements: Element...) {
        self.inStack = elements
    }

    /// Creates a Queue from a sequence.
    public init<S: Sequence>(_ sequence: S) where S.Element == Element {
        self.inStack = Array(sequence)
    }

    /// Number of elements in the queue.
    public var count: Int {
        inStack.count + outStack.count
    }

    /// Returns `true` if the queue is empty.
    public var isEmpty: Bool {
        inStack.isEmpty && outStack.isEmpty
    }

    /// Inspects the front of the queue without removing it ($O(1)$).
    public var peek: Element? {
        outStack.last ?? inStack.first
    }

    /// Enqueues an element to the back of the queue ($O(1)$).
    public mutating func enqueue(_ element: Element) {
        inStack.append(element)
    }

    /// Dequeues and returns the front element (amortized $O(1)$).
    @discardableResult
    public mutating func dequeue() -> Element? {
        if outStack.isEmpty {
            outStack = inStack.reversed()
            inStack.removeAll()
        }
        return outStack.popLast()
    }

    /// Clears all elements from the queue.
    public mutating func clear() {
        inStack.removeAll()
        outStack.removeAll()
    }

    // MARK: - Sequence Conformance
    public func makeIterator() -> IndexingIterator<[Element]> {
        let allElements = outStack.reversed() + inStack
        return allElements.makeIterator()
    }
}
