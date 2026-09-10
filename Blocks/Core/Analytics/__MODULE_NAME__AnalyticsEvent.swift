import Foundation

/// Identifier representing an analytics service provider backend.
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

/// Abstract contract for trackable analytics events.
public protocol AnalyticsEvent {
    /// Unique event name identifier.
    var name: String { get }

    /// Optional payload metadata dictionary.
    var parameters: [String: Any]? { get }

    /// Optional target provider filter list.
    var targetProviders: [AnalyticsProviderIdentifier]? { get }
}

public extension AnalyticsEvent {
    var targetProviders: [AnalyticsProviderIdentifier]? { nil }
}

/// Default implementation struct for AnalyticsEvent.
public struct DefaultAnalyticsEvent: AnalyticsEvent {
    public let name: String
    public let parameters: [String: Any]?
    public let targetProviders: [AnalyticsProviderIdentifier]?

    /// Initializes a default analytics event.
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

