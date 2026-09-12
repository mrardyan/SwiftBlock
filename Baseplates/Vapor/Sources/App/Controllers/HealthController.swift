import Vapor

public struct HealthController: RouteCollection {
    public init() {}

    public func boot(routes: RoutesBuilder) throws {
        let health = routes.grouped("health")
        health.get(use: check)
    }

    @Sendable
    public func check(req: Request) async throws -> HealthResponse {
        return HealthResponse(
            status: "pass",
            service: "__PROJECT_NAME__",
            timestamp: Date()
        )
    }
}

public struct HealthResponse: Content {
    public let status: String
    public let service: String
    public let timestamp: Date

    public init(status: String, service: String, timestamp: Date) {
        self.status = status
        self.service = service
        self.timestamp = timestamp
    }
}
