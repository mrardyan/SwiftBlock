import Foundation

/// Domain model entity for `__MODULE_NAME__`.
public struct __MODULE_NAME__Entity: Identifiable, Codable, Equatable {
    public let id: String
    public var name: String

    public init(id: String = UUID().uuidString, name: String) {
        self.id = id
        self.name = name
    }
}
