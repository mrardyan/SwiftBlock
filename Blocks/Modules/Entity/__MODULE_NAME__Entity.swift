import Foundation

/// Domain model entity representing __MODULE_NAME__.
public struct __MODULE_NAME__Entity: Identifiable, Codable, Equatable {
    /// Unique entity identifier.
    public let id: String

    /// Entity display name property.
    public var name: String

    /// Initializes a new entity instance.
    public init(id: String = UUID().uuidString, name: String) {
        self.id = id
        self.name = name
    }
}
