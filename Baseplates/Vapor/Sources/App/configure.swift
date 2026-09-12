import Vapor

/// Called to configure your application.
public func configure(_ app: Application) async throws {
    // Serves files from `Public/` directory if present
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // Register routes
    try routes(app)
}
