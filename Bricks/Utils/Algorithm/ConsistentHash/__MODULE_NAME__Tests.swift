import XCTest
#if canImport(Core)
@testable import Core
#endif
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    struct CacheNode: Hashable, CustomStringConvertible, Sendable {
        let name: String
        var description: String { name }
    }

    func testConsistentHashNodeAssignment() {
        let node1 = CacheNode(name: "redis-1")
        let node2 = CacheNode(name: "redis-2")
        let node3 = CacheNode(name: "redis-3")

        var ring = __MODULE_NAME__<CacheNode>(virtualReplicas: 50, nodes: [node1, node2, node3])
        XCTAssertEqual(ring.nodeCount, 3)

        let targetNodeA = ring.getNode(for: "user_session_12345")
        let targetNodeB = ring.getNode(for: "user_session_12345")
        XCTAssertNotNil(targetNodeA)
        XCTAssertEqual(targetNodeA, targetNodeB, "Consistent hash should map identical keys to the same node deterministically")
    }

    func testNodeRemovalGracefulRebalancing() {
        let node1 = CacheNode(name: "node-A")
        let node2 = CacheNode(name: "node-B")

        var ring = __MODULE_NAME__<CacheNode>(virtualReplicas: 50, nodes: [node1, node2])
        ring.removeNode(node1)

        XCTAssertEqual(ring.nodeCount, 1)
        XCTAssertEqual(ring.getNode(for: "some-key"), node2)
    }
}
