import Foundation

public struct AnalyticsProviderIdentifier: RawRepresentable, Hashable, ExpressibleByStringLiteral, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public static let console: AnalyticsProviderIdentifier = "console"
    public static let firebase: AnalyticsProviderIdentifier = "firebase"
    public static let mixpanel: AnalyticsProviderIdentifier = "mixpanel"
    public static let amplitude: AnalyticsProviderIdentifier = "amplitude"
}

public protocol AnalyticsEvent {
    var name: String { get }
    var parameters: [String: Any]? { get }
    var targetProviders: [AnalyticsProviderIdentifier]? { get }
}

public extension AnalyticsEvent {
    var targetProviders: [AnalyticsProviderIdentifier]? { nil }
}

public struct DefaultAnalyticsEvent: AnalyticsEvent {
    public let name: String
    public let parameters: [String: Any]?
    public let targetProviders: [AnalyticsProviderIdentifier]?

    public init(
        name: String,
        parameters: [String: Any]? = nil,
        targetProviders: [AnalyticsProviderIdentifier]? = nil
    ) {
        self.name = name
        self.parameters = parameters
        self.targetProviders = targetProviders
    }
}
