import Vapor

/// Configures the shared server middleware stack (error handling, CORS, security headers).
public enum __MODULE_NAME__ {
    public static func configure(_ app: Application) {
        app.middleware.use(ErrorMiddleware.default(environment: app.environment))

        let corsConfiguration = CORSMiddleware.Configuration(
            allowedOrigin: .all,
            allowedMethods: [.GET, .POST, .PUT, .PATCH, .DELETE, .OPTIONS],
            allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
        )
        app.middleware.use(CORSMiddleware(configuration: corsConfiguration), at: .beginning)
    }
}