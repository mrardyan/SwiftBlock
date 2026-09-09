import Foundation

public protocol AnalyticsProvider {
    var identifier: AnalyticsProviderIdentifier { get }
    func track(_ event: AnalyticsEvent)
    func setUserId(_ userId: String?)
    func setUserProperty(key: String, value: String?)
}

public final class ConsoleAnalyticsProvider: AnalyticsProvider {
    public let identifier: AnalyticsProviderIdentifier = .console

    public init() {}

    public func track(_ event: AnalyticsEvent) {
        #if DEBUG
        let paramsString = event.parameters?.description ?? "[:]"
        print("📊 [Analytics Event (\(identifier.rawValue))] '\(event.name)' | params: \(paramsString)")
        #endif
    }

    public func setUserId(_ userId: String?) {
        #if DEBUG
        print("👤 [Analytics UserId (\(identifier.rawValue))] \(userId ?? "nil")")
        #endif
    }

    public func setUserProperty(key: String, value: String?) {
        #if DEBUG
        print("🏷️ [Analytics UserProperty (\(identifier.rawValue))] \(key): \(value ?? "nil")")
        #endif
    }
}
