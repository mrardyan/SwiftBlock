import Foundation

/// Priority Queue implemented using a binary heap.
///
/// Provides $O(\log n)$ insertion (`enqueue`) and extraction (`dequeue`), and $O(1)$ inspection (`peek`).
public struct __MODULE_NAME__<Element: Sendable>: Sendable {
    private var heap: [Element]
    private let areInIncreasingOrder: @Sendable (Element, Element) -> Bool

    /// Creates an empty PriorityQueue with custom comparator.
    public init(sort: @escaping @Sendable (Element, Element) -> Bool) {
        self.heap = []
        self.areInIncreasingOrder = sort
    }

    /// Number of elements in the queue.
    public var count: Int {
        heap.count
    }

    /// Whether the queue contains no elements.
    public var isEmpty: Bool {
        heap.isEmpty
    }

    /// Top priority element without removing it ($O(1)$).
    public var peek: Element? {
        heap.first
    }

    /// Inserts a new element into the priority queue ($O(\log n)$).
    public mutating func enqueue(_ element: Element) {
        heap.append(element)
        siftUp(heap.count - 1)
    }

    /// Removes and returns the highest priority element ($O(\log n)$).
    @discardableResult
    public mutating func dequeue() -> Element? {
        guard !heap.isEmpty else { return nil }
        if heap.count == 1 {
            return heap.removeLast()
        }
        let top = heap[0]
        heap[0] = heap.removeLast()
        siftDown(0)
        return top
    }

    // MARK: - Binary Heap Sifting

    private mutating func siftUp(_ index: Int) {
        var child = index
        var parent = (child - 1) / 2

        while child > 0 && areInIncreasingOrder(heap[child], heap[parent]) {
            heap.swapAt(child, parent)
            child = parent
            parent = (child - 1) / 2
        }
    }

    private mutating func siftDown(_ index: Int) {
        var parent = index
        let count = heap.count

        while true {
            let leftChild = 2 * parent + 1
            let rightChild = leftChild + 1
            var candidate = parent

            if leftChild < count && areInIncreasingOrder(heap[leftChild], heap[candidate]) {
                candidate = leftChild
            }
            if rightChild < count && areInIncreasingOrder(heap[rightChild], heap[candidate]) {
                candidate = rightChild
            }
            if candidate == parent {
                return
            }

            heap.swapAt(parent, candidate)
            parent = candidate
        }
    }
}

// MARK: - Convenience initializers for Comparable types
extension __MODULE_NAME__ where Element: Comparable {
    /// Creates a Max-Heap Priority Queue (largest value dequeued first).
    public static func maxHeap() -> __MODULE_NAME__<Element> {
        __MODULE_NAME__(sort: >)
    }

    /// Creates a Min-Heap Priority Queue (smallest value dequeued first).
    public static func minHeap() -> __MODULE_NAME__<Element> {
        __MODULE_NAME__(sort: <)
    }
}
