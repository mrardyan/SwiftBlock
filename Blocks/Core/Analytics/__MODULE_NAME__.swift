import Foundation

/// Protocol defining multi-provider analytics event tracking and user identification.
public protocol AnalyticsTracking {
    /// Tracks an analytics event across all registered analytics providers.
    func track(_ event: AnalyticsEvent)

    /// Tracks an analytics event to a specific list of provider identifiers.
    func track(_ event: AnalyticsEvent, to targetProviders: [AnalyticsProviderIdentifier])

    /// Tracks an analytics event to a single provider identifier.
    func track(_ event: AnalyticsEvent, to targetProvider: AnalyticsProviderIdentifier)

    /// Sets global user identifier across all registered analytics providers.
    func setUserId(_ userId: String?)

    /// Sets custom user property across all registered analytics providers.
    func setUserProperty(key: String, value: String?)

    /// Registers a new analytics provider dynamically.
    func addProvider(_ provider: AnalyticsProvider)
}

/// Centralized analytics engine managing provider routing and event dispatching.
public final class __MODULE_NAME__: AnalyticsTracking {
    private var providers: [AnalyticsProviderIdentifier: AnalyticsProvider] = [:]

    /// Initializes analytics tracker with initial set of providers (defaults to ConsoleAnalyticsProvider).
    public init(providers: [AnalyticsProvider] = [ConsoleAnalyticsProvider()]) {
        for provider in providers {
            self.providers[provider.identifier] = provider
        }
    }

    /// Adds a provider to the active analytics tracker instance.
    public func addProvider(_ provider: AnalyticsProvider) {
        providers[provider.identifier] = provider
    }

    /// Tracks an event across designated or all registered providers.
    public func track(_ event: AnalyticsEvent) {
        if let targets = event.targetProviders {
            track(event, to: targets)
        } else {
            for provider in providers.values {
                provider.track(event)
            }
        }
    }

    /// Dispatches event to specified list of target providers.
    public func track(_ event: AnalyticsEvent, to targetProviders: [AnalyticsProviderIdentifier]) {
        for target in targetProviders {
            providers[target]?.track(event)
        }
    }

    /// Dispatches event to a single target provider.
    public func track(_ event: AnalyticsEvent, to targetProvider: AnalyticsProviderIdentifier) {
        providers[targetProvider]?.track(event)
    }

    /// Sets active user identifier across all registered providers.
    public func setUserId(_ userId: String?) {
        for provider in providers.values {
            provider.setUserId(userId)
        }
    }

    /// Sets custom user attribute across all registered providers.
    public func setUserProperty(key: String, value: String?) {
        for provider in providers.values {
            provider.setUserProperty(key: key, value: value)
        }
    }
}

