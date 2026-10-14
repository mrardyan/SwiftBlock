import Foundation

/// Data repository interface for `__MODULE_NAME__`.
public protocol __MODULE_NAME__Repository: Sendable {
    func fetch() async throws -> [__MODULE_NAME__Item]
    func save(_ item: __MODULE_NAME__Item) async throws
    func delete(id: String) async throws
}

/// Canonical model managed by the `__MODULE_NAME__` repository.
public struct __MODULE_NAME__Item: Codable, Equatable, Sendable {
    public let id: String
    public let name: String

    public init(id: String = UUID().uuidString, name: String) {
        self.id = id
        self.name = name
    }
}