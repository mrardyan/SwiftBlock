import Foundation

/// Disjoint-Set / Union-Find data structure with Path Compression and Union-by-Rank.
///
/// Provides near-constant time $O(\alpha(n))$ operations for element grouping and connectivity checks.
public struct __MODULE_NAME__<Element: Hashable & Sendable>: Sendable {
    private var parent: [Element: Element] = [:]
    private var rank: [Element: Int] = [:]
    private var setCount: Int = 0

    /// Creates an empty UnionFind structure.
    public init() {}

    /// Creates a UnionFind structure initialized with a collection of disjoint elements.
    public init<S: Sequence>(_ elements: S) where S.Element == Element {
        for element in elements {
            add(element)
        }
    }

    /// Adds a new element as an isolated set ($O(1)$).
    public mutating func add(_ element: Element) {
        guard parent[element] == nil else { return }
        parent[element] = element
        rank[element] = 0
        setCount += 1
    }

    /// Finds the canonical representative (root) of the set containing `element` with Path Compression ($O(\alpha(n))$).
    public mutating func find(_ element: Element) -> Element? {
        guard parent[element] != nil else { return nil }

        var root = element
        while let p = parent[root], p != root {
            root = p
        }

        // Path compression: point all ancestors directly to root
        var curr = element
        while let p = parent[curr], p != root {
            parent[curr] = root
            curr = p
        }

        return root
    }

    /// Merges the sets containing `element1` and `element2` using Union by Rank.
    /// Returns `true` if sets were merged, or `false` if they were already in the same set.
    @discardableResult
    public mutating func union(_ element1: Element, _ element2: Element) -> Bool {
        add(element1)
        add(element2)

        guard let root1 = find(element1), let root2 = find(element2) else { return false }
        if root1 == root2 { return false }

        let rank1 = rank[root1] ?? 0
        let rank2 = rank[root2] ?? 0

        if rank1 < rank2 {
            parent[root1] = root2
        } else if rank1 > rank2 {
            parent[root2] = root1
        } else {
            parent[root2] = root1
            rank[root1] = rank1 + 1
        }

        setCount -= 1
        return true
    }

    /// Checks whether two elements belong to the same set ($O(\alpha(n))$).
    public mutating func connected(_ element1: Element, _ element2: Element) -> Bool {
        guard let root1 = find(element1), let root2 = find(element2) else { return false }
        return root1 == root2
    }

    /// Total number of disjoint sets.
    public var count: Int {
        setCount
    }
}
