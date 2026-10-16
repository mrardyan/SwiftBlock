import Foundation

/// Current lifecycle phase of the optimistic state store.
public enum OptimisticPhase<State: Sendable>: Sendable {
    /// No mutations are currently pending.
    case idle

    /// One or more optimistic mutations are applied locally and pending remote synchronization.
    case optimistic(pendingCount: Int)

    /// Remote sync succeeded and the state is committed with server confirmation.
    case committed(finalState: State)

    /// A remote sync failed and the mutation was rolled back via journal rebase.
    case rolledBack(revertedState: State, error: String)
}

/// A recorded optimistic mutation in the journal.
public struct OptimisticMutation<State: Sendable>: Identifiable, Sendable {
    public let id: String
    public let description: String
    public let timestamp: Date
    public let apply: @Sendable (inout State) -> Void

    public init(
        id: String = UUID().uuidString,
        description: String = "",
        timestamp: Date = Date(),
        apply: @escaping @Sendable (inout State) -> Void
    ) {
        self.id = id
        self.description = description
        self.timestamp = timestamp
        self.apply = apply
    }
}

/// Strategy for resolving conflicts when incoming server state diverges from local state.
public enum OptimisticConflictStrategy: Sendable {
    /// Server state is authoritative and overwrites diverging local state.
    case serverWins

    /// Client optimistic mutation is rebased and applied on top of the new server state.
    case clientRebase
}

/// Reconciliation payload returned after a server confirms an entity creation or update,
/// mapping a temporary local ID to an authoritative server ID and sync cursor.
public struct IDReconciliation: Sendable, Equatable {
    public let localId: String
    public let serverId: String
    public let syncCursor: String?

    public init(localId: String, serverId: String, syncCursor: String? = nil) {
        self.localId = localId
        self.serverId = serverId
        self.syncCursor = syncCursor
    }
}
