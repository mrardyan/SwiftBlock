import Foundation

/// Data repository interface for `__MODULE_NAME__`.
public protocol __MODULE_NAME__Repository: Sendable {
    func fetch() async throws -> [<#Model#>]
    func save(_ item: <#Model#>) async throws
    func delete(id: <#ID#>) async throws
}
