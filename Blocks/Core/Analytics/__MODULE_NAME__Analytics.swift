import Foundation

public protocol __MODULE_NAME__AnalyticsProtocol {
    func logEvent(_ event: AnalyticsEventProtocol)
    func setUserId(_ userId: String?)
    func setUserProperty(key: String, value: String?)
    func addProvider(_ provider: AnalyticsProviderProtocol)
}

public final class __MODULE_NAME__Analytics: __MODULE_NAME__AnalyticsProtocol {
    private var providers: [AnalyticsProviderProtocol]

    public init(providers: [AnalyticsProviderProtocol] = [ConsoleAnalyticsProvider()]) {
        self.providers = providers
    }

    public func addProvider(_ provider: AnalyticsProviderProtocol) {
        providers.append(provider)
    }

    public func logEvent(_ event: AnalyticsEventProtocol) {
        for provider in providers {
            provider.logEvent(event)
        }
    }

    public func setUserId(_ userId: String?) {
        for provider in providers {
            provider.setUserId(userId)
        }
    }

    public func setUserProperty(key: String, value: String?) {
        for provider in providers {
            provider.setUserProperty(key: key, value: value)
        }
    }
}
