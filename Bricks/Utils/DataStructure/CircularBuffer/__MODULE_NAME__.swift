import Foundation

/// Fixed-capacity FIFO Ring / Circular Buffer.
///
/// Automatically overwrites the oldest element when writing to a full buffer ($O(1)$ read and write).
public struct __MODULE_NAME__<Element: Sendable>: Sendable, Sequence {
    public let capacity: Int
    private var buffer: [Element?]
    private var readIndex: Int = 0
    private var writeIndex: Int = 0
    private var elementsCount: Int = 0

    /// Creates a circular buffer with fixed maximum capacity.
    public init(capacity: Int) {
        self.capacity = max(1, capacity)
        self.buffer = Array(repeating: nil, count: self.capacity)
    }

    /// Current number of stored elements.
    public var count: Int {
        elementsCount
    }

    /// Whether the buffer contains no elements.
    public var isEmpty: Bool {
        elementsCount == 0
    }

    /// Whether the buffer has reached its maximum capacity.
    public var isFull: Bool {
        elementsCount == capacity
    }

    /// Appends an element into the buffer, overwriting the oldest element if full.
    public mutating func write(_ element: Element) {
        buffer[writeIndex] = element
        writeIndex = (writeIndex + 1) % capacity

        if isFull {
            readIndex = (readIndex + 1) % capacity
        } else {
            elementsCount += 1
        }
    }

    /// Reads and removes the oldest element from the buffer ($O(1)$).
    public mutating func read() -> Element? {
        guard !isEmpty else { return nil }

        let element = buffer[readIndex]
        buffer[readIndex] = nil
        readIndex = (readIndex + 1) % capacity
        elementsCount -= 1
        return element
    }

    /// Inspects the oldest element without removing it ($O(1)$).
    public var peek: Element? {
        guard !isEmpty else { return nil }
        return buffer[readIndex]
    }

    /// Removes all elements and resets read/write pointers.
    public mutating func clear() {
        buffer = Array(repeating: nil, count: capacity)
        readIndex = 0
        writeIndex = 0
        elementsCount = 0
    }

    /// Returns all elements in chronological order from oldest to newest.
    public var elements: [Element] {
        var result: [Element] = []
        result.reserveCapacity(elementsCount)
        var idx = readIndex
        for _ in 0..<elementsCount {
            if let el = buffer[idx] {
                result.append(el)
            }
            idx = (idx + 1) % capacity
        }
        return result
    }

    // MARK: - Sequence Conformance
    public func makeIterator() -> IndexingIterator<[Element]> {
        elements.makeIterator()
    }
}
