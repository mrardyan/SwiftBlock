import Foundation

public protocol AnalyticsProvider {
    func track(_ event: AnalyticsEvent)
    func setUserId(_ userId: String?)
    func setUserProperty(key: String, value: String?)
}

public final class ConsoleAnalyticsProvider: AnalyticsProvider {
    public init() {}

    public func track(_ event: AnalyticsEvent) {
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
