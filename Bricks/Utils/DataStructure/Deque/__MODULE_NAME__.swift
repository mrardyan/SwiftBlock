import Foundation

/// High-performance, double-ended queue supporting amortized $O(1)$ insertions and removals at both ends.
public struct __MODULE_NAME__<Element: Sendable>: Sendable, ExpressibleByArrayLiteral {
    private var frontStack: [Element]
    private var backStack: [Element]

    /// Creates an empty Deque.
    public init() {
        self.frontStack = []
        self.backStack = []
    }

    /// Creates a Deque from an array literal.
    public init(arrayLiteral elements: Element...) {
        self.frontStack = []
        self.backStack = elements
    }

    /// Creates a Deque from a sequence.
    public init<S: Sequence>(_ sequence: S) where S.Element == Element {
        self.frontStack = []
        self.backStack = Array(sequence)
    }

    /// Total number of elements in the deque.
    public var count: Int {
        frontStack.count + backStack.count
    }

    /// Returns `true` if the deque contains no elements.
    public var isEmpty: Bool {
        frontStack.isEmpty && backStack.isEmpty
    }

    /// First element of the deque ($O(1)$).
    public var first: Element? {
        frontStack.last ?? backStack.first
    }

    /// Last element of the deque ($O(1)$).
    public var last: Element? {
        backStack.last ?? frontStack.first
    }

    /// Appends an element to the back of the deque (amortized $O(1)$).
    public mutating func append(_ element: Element) {
        backStack.append(element)
    }

    /// Prepends an element to the front of the deque (amortized $O(1)$).
    public mutating func prepend(_ element: Element) {
        frontStack.append(element)
    }

    /// Removes and returns the first element of the deque (amortized $O(1)$).
    @discardableResult
    public mutating func popFirst() -> Element? {
        if frontStack.isEmpty {
            balance()
        }
        return frontStack.popLast()
    }

    /// Removes and returns the last element of the deque (amortized $O(1)$).
    @discardableResult
    public mutating func popLast() -> Element? {
        if backStack.isEmpty {
            balanceReversed()
        }
        return backStack.popLast()
    }

    /// Removes all elements from the deque.
    public mutating func removeAll() {
        frontStack.removeAll()
        backStack.removeAll()
    }

    // MARK: - Rebalancing

    private mutating func balance() {
        guard !backStack.isEmpty else { return }
        let mid = backStack.count / 2
        let frontPart = backStack[..<mid]
        let backPart = backStack[mid...]

        frontStack = frontPart.reversed()
        backStack = Array(backPart)
        if frontStack.isEmpty && !backStack.isEmpty {
            frontStack = [backStack.removeFirst()]
        }
    }

    private mutating func balanceReversed() {
        guard !frontStack.isEmpty else { return }
        let mid = frontStack.count / 2
        let backPart = frontStack[..<mid]
        let frontPart = frontStack[mid...]

        backStack = backPart.reversed()
        frontStack = Array(frontPart)
        if backStack.isEmpty && !frontStack.isEmpty {
            backStack = [frontStack.removeFirst()]
        }
    }
}
