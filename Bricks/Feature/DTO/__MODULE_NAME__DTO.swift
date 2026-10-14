import Vapor

/// Validated request payload for `__MODULE_NAME__`.
public struct __MODULE_NAME__Request: Content, Validatable, Sendable {
    public let name: String

    public init(name: String) {
        self.name = name
    }

    public static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty)
    }
}

/// Response payload for `__MODULE_NAME__`.
public struct __MODULE_NAME__Response: Content, Sendable {
    public let id: UUID
    public let name: String

    public init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }
}