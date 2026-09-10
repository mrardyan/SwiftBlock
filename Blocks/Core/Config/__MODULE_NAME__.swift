import Foundation

/// Application execution environment configurations.
public enum AppEnvironment: String, CaseIterable {
    case development
    case staging
    case production

    /// Automatically resolves active environment from Info.plist (APP_ENVIRONMENT) or compiler flags.
    public static var current: AppEnvironment {
        guard let envString = Bundle.main.object(forInfoDictionaryKey: "APP_ENVIRONMENT") as? String,
              let env = AppEnvironment(rawValue: envString.lowercased()) else {
            #if DEBUG
            return .development
            #else
            return .production
            #endif
        }
        return env
    }
}

/// Protocol defining application configuration requirements.
public protocol Configuring {
    /// Active execution environment.
    var environment: AppEnvironment { get }

    /// Base URL for API network requests.
    var baseURL: URL { get }

    /// Primary API Key for remote authorization.
    var apiKey: String { get }

    /// Checks whether a local feature flag toggle is enabled.
    func isFeatureEnabled(_ key: String) -> Bool

    /// Retrieves an environment value by key from Info.plist or configuration.
    func value(for key: String) -> String?
}

/// Production implementation reading configuration safely from Bundle Info.plist / .xcconfig.
public final class __MODULE_NAME__: Configuring {
    public let environment: AppEnvironment
    private let bundle: Bundle
    private var featureFlags: [String: Bool]

    /// Initializes configuration with specified environment, bundle, and feature flag overrides.
    public init(
        environment: AppEnvironment = AppEnvironment.current,
        bundle: Bundle = .main,
        featureFlags: [String: Bool] = [:]
    ) {
        self.environment = environment
        self.bundle = bundle
        self.featureFlags = featureFlags
    }

    /// Base URL resolved dynamically based on environment or Info.plist configuration.
    public var baseURL: URL {
        guard let urlString = value(for: "BASE_URL"), let url = URL(string: urlString) else {
            switch environment {
            case .development: return URL(string: "https://dev-api.example.com")!
            case .staging:     return URL(string: "https://staging-api.example.com")!
            case .production:  return URL(string: "https://api.example.com")!
            }
        }
        return url
    }

    /// API key retrieved from configuration value store.
    public var apiKey: String {
        value(for: "API_KEY") ?? ""
    }

    /// Checks if feature flag is active in feature flags dictionary.
    public func isFeatureEnabled(_ key: String) -> Bool {
        featureFlags[key] ?? false
    }

    /// Reads configuration string value for specified key.
    public func value(for key: String) -> String? {
        guard let object = bundle.object(forInfoDictionaryKey: key) else { return nil }
        return (object as? String)?.replacingOccurrences(of: "\\", with: "")
    }
}
