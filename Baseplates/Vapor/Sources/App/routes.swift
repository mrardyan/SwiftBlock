import Vapor

public func routes(_ app: Application) throws {
    app.get { _ async in
        "Welcome to __PROJECT_NAME__ Vapor API Server!"
    }

    try app.register(collection: HealthController())
}
