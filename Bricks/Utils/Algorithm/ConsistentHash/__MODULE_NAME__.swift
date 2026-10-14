import Foundation

/// Consistent Hash Ring algorithm with virtual node replicas.
///
/// Minimizes re-mapping of keys when nodes are added or removed in distributed caching
/// or database sharding topologies.
public struct __MODULE_NAME__<Node: Hashable & CustomStringConvertible & Sendable>: Sendable {
    public let virtualReplicas: Int
    private var ring: [UInt32: Node] = [:]
    private var sortedKeys: [UInt32] = []

    /// Creates a consistent hash ring.
    /// - Parameter virtualReplicas: Number of virtual points on the ring per physical node (default: 100).
    public init(virtualReplicas: Int = 100, nodes: [Node] = []) {
        self.virtualReplicas = max(1, virtualReplicas)
        for node in nodes {
            addNode(node)
        }
    }

    /// Adds a physical node to the ring, generating virtual points.
    public mutating func addNode(_ node: Node) {
        for i in 0..<virtualReplicas {
            let key = "\(node.description)-vnode-\(i)"
            let hash = fnv1aHash(key)
            ring[hash] = node
        }
        sortedKeys = ring.keys.sorted()
    }

    /// Removes a physical node and its virtual points from the ring.
    public mutating func removeNode(_ node: Node) {
        for i in 0..<virtualReplicas {
            let key = "\(node.description)-vnode-\(i)"
            let hash = fnv1aHash(key)
            ring.removeValue(forKey: hash)
        }
        sortedKeys = ring.keys.sorted()
    }

    /// Resolves the corresponding physical node for a given item key.
    public func getNode(for key: String) -> Node? {
        guard !sortedKeys.isEmpty else { return nil }

        let hash = fnv1aHash(key)
        let targetIndex = binarySearchFirstGreaterOrEqual(in: sortedKeys, target: hash)

        let ringIndex = targetIndex < sortedKeys.count ? targetIndex : 0
        let ringKey = sortedKeys[ringIndex]
        return ring[ringKey]
    }

    /// Number of distinct physical nodes currently on the ring.
    public var nodeCount: Int {
        Set(ring.values).count
    }

    // MARK: - Internals

    private func fnv1aHash(_ string: String) -> UInt32 {
        var hash: UInt32 = 0x811c9dc5
        for byte in string.utf8 {
            hash ^= UInt32(byte)
            hash = hash &* 0x01000193
        }
        return hash
    }

    private func binarySearchFirstGreaterOrEqual(in array: [UInt32], target: UInt32) -> Int {
        var low = 0
        var high = array.count

        while low < high {
            let mid = low + (high - low) / 2
            if array[mid] < target {
                low = mid + 1
            } else {
                high = mid
            }
        }
        return low
    }
}
