import Foundation

public enum AppEnvironment: String, CaseIterable {
    case development
    case staging
    case production

    /// Automatically resolves active environment from Info.plist (APP_ENVIRONMENT) or compiler flags
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

public protocol __MODULE_NAME__Configuring {
    var environment: AppEnvironment { get }
    var baseURL: URL { get }
    var apiKey: String { get }
    func isFeatureEnabled(_ key: String) -> Bool
    func value(for key: String) -> String?
}

/// Production implementation reading configuration safely from Bundle Info.plist / .xcconfig
public final class Bundle__MODULE_NAME__Configuration: __MODULE_NAME__Configuring {
    public let environment: AppEnvironment
    private let bundle: Bundle
    private var featureFlags: [String: Bool]

    public init(
        environment: AppEnvironment = AppEnvironment.current,
        bundle: Bundle = .main,
        featureFlags: [String: Bool] = [:]
    ) {
        self.environment = environment
        self.bundle = bundle
        self.featureFlags = featureFlags
    }

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

    public var apiKey: String {
        value(for: "API_KEY") ?? ""
    }

    public func isFeatureEnabled(_ key: String) -> Bool {
        featureFlags[key] ?? false
    }

    public func value(for key: String) -> String? {
        guard let object = bundle.object(forInfoDictionaryKey: key) else { return nil }
        return (object as? String)?.replacingOccurrences(of: "\\", with: "")
    }
}
