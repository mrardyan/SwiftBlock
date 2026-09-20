import Vapor

/// RESTful controller exposing CRUD routes for `__MODULE_NAME__`.
public struct __MODULE_NAME__Controller: RouteCollection, Sendable {
    public init() {}

    public func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped("{{moduleName.lowercased()}}")
        group.get(use: index)
        group.post(use: create)
        group.group(":id") { item in
            item.get(use: show)
            item.put(use: update)
            item.delete(use: delete)
        }
    }

    @Sendable
    public func index(req: Request) async throws -> [__MODULE_NAME__Payload] {
        return []
    }

    @Sendable
    public func create(req: Request) async throws -> __MODULE_NAME__Payload {
        let payload = try req.content.decode(__MODULE_NAME__Payload.self)
        return __MODULE_NAME__Payload(id: UUID(), name: payload.name)
    }

    @Sendable
    public func show(req: Request) async throws -> __MODULE_NAME__Payload {
        let id = req.parameters.get("id") ?? "unknown"
        return __MODULE_NAME__Payload(id: UUID(), name: id)
    }

    @Sendable
    public func update(req: Request) async throws -> __MODULE_NAME__Payload {
        let payload = try req.content.decode(__MODULE_NAME__Payload.self)
        return __MODULE_NAME__Payload(id: UUID(), name: payload.name)
    }

    @Sendable
    public func delete(req: Request) async throws -> HTTPStatus {
        return .noContent
    }
}

/// Transport payload for `__MODULE_NAME__` create/update requests.
public struct __MODULE_NAME__Payload: Content, Sendable {
    public var id: UUID?
    public var name: String

    public init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}