import Foundation
import Combine

/// Generic, observable UI state manager that provides immediate optimistic local updates,
/// safe journaled rebase rollbacks on failure, and server state reconciliation.
@MainActor
public final class __MODULE_NAME__<State: Sendable & Equatable>: ObservableObject {
    /// The currently active UI state, including any unconfirmed optimistic mutations.
    @Published public private(set) var state: State

    /// The current lifecycle phase of mutations in this store.
    @Published public private(set) var phase: OptimisticPhase<State> = .idle

    /// The authoritative ground-truth state confirmed by the remote server.
    public private(set) var baseServerState: State

    /// Ordered journal of pending optimistic mutations awaiting remote confirmation.
    private var pendingJournal: [OptimisticMutation<State>] = []

    /// Creates an OptimisticStore with an initial state.
    public init(initialState: State) {
        self.state = initialState
        self.baseServerState = initialState
    }

    /// Number of optimistic mutations currently awaiting remote confirmation.
    public var pendingCount: Int {
        pendingJournal.count
    }

    /// Applies an optimistic mutation immediately to local UI state and executes remote sync.
    ///
    /// If the remote operation fails, only this specific mutation is reverted using a
    /// journal rebase, preserving any other independent concurrent mutations.
    ///
    /// - Parameters:
    ///   - id: Unique mutation identifier (defaults to a new UUID).
    ///   - description: Human-readable description of the mutation for debugging.
    ///   - apply: Immediate local state mutation closure.
    ///   - remoteSync: Remote async operation returning authoritative server state.
    /// - Returns: The final reconciled state.
    @discardableResult
    public func mutate(
        id: String = UUID().uuidString,
        description: String = "",
        apply: @escaping @Sendable (inout State) -> Void,
        remoteSync: @escaping @Sendable () async throws -> State
    ) async throws -> State {
        let mutation = OptimisticMutation(id: id, description: description, apply: apply)
        pendingJournal.append(mutation)

        // 1. Optimistic Apply immediately to local state
        apply(&state)
        phase = .optimistic(pendingCount: pendingJournal.count)

        // 2. Execute remote sync operation
        do {
            let serverState = try await remoteSync()

            // 3. Success: Update base server state and rebase remaining mutations
            baseServerState = serverState
            pendingJournal.removeAll { $0.id == id }

            rebaseState()
            phase = .committed(finalState: state)
            return state
        } catch {
            // 4. Failure: Remove ONLY this failed mutation and rebase remaining mutations over base
            pendingJournal.removeAll { $0.id == id }
            rebaseState()

            phase = .rolledBack(revertedState: state, error: error.localizedDescription)
            throw error
        }
    }

    /// Reconciles an out-of-band server update (e.g. from push notifications or background poll)
    /// into the store.
    ///
    /// - Parameters:
    ///   - serverState: The authoritative new state received from the server.
    ///   - strategy: How to resolve conflicts between server state and local pending mutations.
    public func reconcile(
        serverState: State,
        strategy: OptimisticConflictStrategy = .clientRebase
    ) {
        switch strategy {
        case .serverWins:
            pendingJournal.removeAll()
            baseServerState = serverState
            state = serverState
            phase = .idle

        case .clientRebase:
            baseServerState = serverState
            rebaseState()
            if pendingJournal.isEmpty {
                phase = .idle
            }
        }
    }

    /// Reconciles an entity's temporary local identifier with the confirmed server identifier in-place,
    /// updating both baseServerState and current active state.
    ///
    /// - Parameters:
    ///   - localId: The temporary client ID assigned during optimistic creation.
    ///   - serverId: The authoritative ID assigned by the remote server.
    ///   - update: Closure updating identifiers inside the state.
    public func reconcileId(
        localId: String,
        serverId: String,
        update: (inout State, String, String) -> Void
    ) {
        update(&baseServerState, localId, serverId)
        update(&state, localId, serverId)
    }

    /// Applies an optimistic mutation immediately and processes remote synchronization,
    /// reconciling server state and any newly confirmed entity IDs upon success.
    @discardableResult
    public func mutateWithReconciliation(
        id: String = UUID().uuidString,
        description: String = "",
        apply: @escaping @Sendable (inout State) -> Void,
        remoteSync: @escaping @Sendable () async throws -> (serverState: State, reconciliation: IDReconciliation?)
    ) async throws -> State {
        let mutation = OptimisticMutation(id: id, description: description, apply: apply)
        pendingJournal.append(mutation)

        apply(&state)
        phase = .optimistic(pendingCount: pendingJournal.count)

        do {
            let (serverState, _) = try await remoteSync()

            baseServerState = serverState
            pendingJournal.removeAll { $0.id == id }

            rebaseState()
            phase = .committed(finalState: state)
            return state
        } catch {
            pendingJournal.removeAll { $0.id == id }
            rebaseState()

            phase = .rolledBack(revertedState: state, error: error.localizedDescription)
            throw error
        }
    }

    /// Discards all pending optimistic mutations and restores the last confirmed server state.
    public func rollbackAll() {
        pendingJournal.removeAll()
        state = baseServerState
        phase = .idle
    }

    // MARK: - Internal Rebase Engine

    /// Recomputes `state` by starting from `baseServerState` and sequentially replaying
    /// all active mutations in `pendingJournal`.
    private func rebaseState() {
        var recomputed = baseServerState
        for mutation in pendingJournal {
            mutation.apply(&recomputed)
        }
        state = recomputed
    }
}
