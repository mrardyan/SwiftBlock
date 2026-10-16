import Foundation
import XCTest
@testable import __APP_MODULE__

final class __MODULE_NAME__Tests: XCTestCase {
    struct TestState: Equatable, Sendable {
        var count: Int
        var title: String
    }

    @MainActor
    func testImmediateOptimisticApplyAndCommit() async throws {
        let initial = TestState(count: 0, title: "Initial")
        let store = __MODULE_NAME__(initialState: initial)

        XCTAssertEqual(store.state.count, 0)

        // Mutate with successful remote sync
        let result = try await store.mutate(
            apply: { state in
                state.count = 10
            },
            remoteSync: {
                TestState(count: 10, title: "Confirmed")
            }
        )

        XCTAssertEqual(result.count, 10)
        XCTAssertEqual(store.state.title, "Confirmed")
        XCTAssertEqual(store.baseServerState.title, "Confirmed")
        if case .committed = store.phase {
            // Expected
        } else {
            XCTFail("Store phase should be committed")
        }
    }

    @MainActor
    func testRebaseRollbackPreservesConcurrentMutations() async {
        let initial = TestState(count: 0, title: "Initial")
        let store = __MODULE_NAME__(initialState: initial)

        // Mutation 1: Fails remotely
        do {
            try await store.mutate(
                id: "mut_fail",
                apply: { state in
                    state.count = 99
                },
                remoteSync: {
                    throw URLError(.timedOut)
                }
            )
            XCTFail("Mutation should have thrown error")
        } catch {
            // Mutation 1 failed and was rolled back
            XCTAssertEqual(store.state.count, 0, "Failed mutation must roll back")
            if case .rolledBack = store.phase {
                // Expected
            } else {
                XCTFail("Phase should be rolledBack")
            }
        }

        // Mutation 2: Succeeds
        do {
            try await store.mutate(
                id: "mut_success",
                apply: { state in
                    state.title = "Updated"
                },
                remoteSync: {
                    TestState(count: 0, title: "Updated")
                }
            )
            XCTAssertEqual(store.state.title, "Updated")
            XCTAssertEqual(store.state.count, 0)
        } catch {
            XCTFail("Mutation 2 should have succeeded")
        }
    }

    @MainActor
    func testServerReconciliation() {
        let initial = TestState(count: 0, title: "Old")
        let store = __MODULE_NAME__(initialState: initial)

        let serverPush = TestState(count: 5, title: "PushFromCloud")
        store.reconcile(serverState: serverPush, strategy: .serverWins)

        XCTAssertEqual(store.state.count, 5)
        XCTAssertEqual(store.state.title, "PushFromCloud")
        XCTAssertEqual(store.baseServerState, serverPush)
    }

    @MainActor
    func testRollbackAll() async {
        let initial = TestState(count: 1, title: "Base")
        let store = __MODULE_NAME__(initialState: initial)

        store.reconcile(serverState: initial, strategy: .serverWins)
        store.rollbackAll()

        XCTAssertEqual(store.state, initial)
    }

    @MainActor
    func testLocalIdToServerIdReconciliation() {
        struct ItemState: Equatable, Sendable {
            var id: String
            var name: String
        }

        let store = __MODULE_NAME__(initialState: ItemState(id: "local-123", name: "Draft Task"))

        store.reconcileId(localId: "local-123", serverId: "srv-999") { state, local, server in
            if state.id == local {
                state.id = server
            }
        }

        XCTAssertEqual(store.state.id, "srv-999")
        XCTAssertEqual(store.baseServerState.id, "srv-999")
    }

    @MainActor
    func testMutateWithReconciliation() async throws {
        let initial = TestState(count: 0, title: "Initial")
        let store = __MODULE_NAME__(initialState: initial)

        let result = try await store.mutateWithReconciliation(
            apply: { state in
                state.count = 42
            },
            remoteSync: {
                (serverState: TestState(count: 42, title: "ServerSynced"), reconciliation: IDReconciliation(localId: "loc-1", serverId: "srv-1"))
            }
        )

        XCTAssertEqual(result.count, 42)
        XCTAssertEqual(store.state.title, "ServerSynced")
    }
}
