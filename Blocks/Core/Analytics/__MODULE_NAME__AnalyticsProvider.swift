import Foundation

/// Protocol defining interface for individual analytics destination providers.
public protocol AnalyticsProvider {
    /// Provider identifier key.
    var identifier: AnalyticsProviderIdentifier { get }

    /// Tracks event on provider SDK.
    func track(_ event: AnalyticsEvent)

    /// Sets user identifier on provider SDK.
    func setUserId(_ userId: String?)

    /// Sets user property on provider SDK.
    func setUserProperty(key: String, value: String?)
}

/// Debug console output analytics provider implementation.
public final class ConsoleAnalyticsProvider: AnalyticsProvider {
    public let identifier: AnalyticsProviderIdentifier = .console

    public init() {}

    /// Logs event tracking to Xcode console in debug builds.
    public func track(_ event: AnalyticsEvent) {
        #if DEBUG
        let paramsString = event.parameters?.description ?? "[:]"
        print("📊 [Analytics Event (\(identifier.rawValue))] '\(event.name)' | params: \(paramsString)")
        #endif
    }

    /// Logs user identification updates to Xcode console in debug builds.
    public func setUserId(_ userId: String?) {
        #if DEBUG
        print("👤 [Analytics UserId (\(identifier.rawValue))] \(userId ?? "nil")")
        #endif
    }

    /// Logs user property updates to Xcode console in debug builds.
    public func setUserProperty(key: String, value: String?) {
        #if DEBUG
        print("🏷️ [Analytics UserProperty (\(identifier.rawValue))] \(key): \(value ?? "nil")")
        #endif
    }
}
