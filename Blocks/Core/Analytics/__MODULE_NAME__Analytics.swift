import Foundation

public protocol __MODULE_NAME__Analytics {
    func track(_ event: AnalyticsEvent)
    func setUserId(_ userId: String?)
    func setUserProperty(key: String, value: String?)
    func addProvider(_ provider: AnalyticsProvider)
}

public final class Default__MODULE_NAME__Analytics: __MODULE_NAME__Analytics {
    private var providers: [AnalyticsProvider]

    public init(providers: [AnalyticsProvider] = [ConsoleAnalyticsProvider()]) {
        self.providers = providers
    }

    public func addProvider(_ provider: AnalyticsProvider) {
        providers.append(provider)
    }

    public func track(_ event: AnalyticsEvent) {
        for provider in providers {
            provider.track(event)
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
