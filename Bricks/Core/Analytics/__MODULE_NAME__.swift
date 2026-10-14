import Foundation

/// Interface for dispatching analytics events and managing user properties across providers.
public protocol AnalyticsTracking {
    func track(_ event: AnalyticsEvent)
    func track(_ event: AnalyticsEvent, to targetProviders: [AnalyticsProviderIdentifier])
    func track(_ event: AnalyticsEvent, to targetProvider: AnalyticsProviderIdentifier)
    func setUserId(_ userId: String?)
    func setUserProperty(key: String, value: String?)
    func addProvider(_ provider: AnalyticsProvider)
}

/// Multi-provider analytics tracking engine.
public final class __MODULE_NAME__: AnalyticsTracking {
    private var providers: [AnalyticsProviderIdentifier: AnalyticsProvider] = [:]

    public init(providers: [AnalyticsProvider] = [ConsoleAnalyticsProvider()]) {
        for provider in providers {
            self.providers[provider.identifier] = provider
        }
    }

    public func addProvider(_ provider: AnalyticsProvider) {
        providers[provider.identifier] = provider
    }

    public func track(_ event: AnalyticsEvent) {
        if let targets = event.targetProviders {
            track(event, to: targets)
        } else {
            for provider in providers.values {
                provider.track(event)
            }
        }
    }

    public func track(_ event: AnalyticsEvent, to targetProviders: [AnalyticsProviderIdentifier]) {
        for target in targetProviders {
            providers[target]?.track(event)
        }
    }

    public func track(_ event: AnalyticsEvent, to targetProvider: AnalyticsProviderIdentifier) {
        providers[targetProvider]?.track(event)
    }

    public func setUserId(_ userId: String?) {
        for provider in providers.values {
            provider.setUserId(userId)
        }
    }

    public func setUserProperty(key: String, value: String?) {
        for provider in providers.values {
            provider.setUserProperty(key: key, value: value)
        }
    }
}
