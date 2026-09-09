import Foundation

public protocol AnalyticsProviderProtocol {
    func logEvent(_ event: AnalyticsEventProtocol)
    func setUserId(_ userId: String?)
    func setUserProperty(key: String, value: String?)
}

public final class ConsoleAnalyticsProvider: AnalyticsProviderProtocol {
    public init() {}

    public func logEvent(_ event: AnalyticsEventProtocol) {
        #if DEBUG
        let paramsString = event.parameters?.description ?? "[:]"
        print("📊 [Analytics Event] '\(event.name)' | params: \(paramsString)")
        #endif
    }

    public func setUserId(_ userId: String?) {
        #if DEBUG
        print("👤 [Analytics UserId] \(userId ?? "nil")")
        #endif
    }

    public func setUserProperty(key: String, value: String?) {
        #if DEBUG
        print("🏷️ [Analytics UserProperty] \(key): \(value ?? "nil")")
        #endif
    }
}
