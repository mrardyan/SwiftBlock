import Foundation

/// Interface for dispatching analytics events and managing user properties across providers.
public protocol AnalyticsTracking: Sendable {
{{#if concurrency == 'swift-concurrency'}}
    func track(_ event: any AnalyticsEvent) async
    func track(_ event: any AnalyticsEvent, to targetProviders: [AnalyticsProviderIdentifier]) async
    func track(_ event: any AnalyticsEvent, to targetProvider: AnalyticsProviderIdentifier) async
    func setUserId(_ userId: String?) async
    func setUserProperty(key: String, value: String?) async
    func addProvider(_ provider: any AnalyticsProvider) async
{{else}}
    func track(_ event: any AnalyticsEvent)
    func track(_ event: any AnalyticsEvent, to targetProviders: [AnalyticsProviderIdentifier])
    func track(_ event: any AnalyticsEvent, to targetProvider: AnalyticsProviderIdentifier)
    func setUserId(_ userId: String?)
    func setUserProperty(key: String, value: String?)
    func addProvider(_ provider: any AnalyticsProvider)
{{/if}}
}

{{#if concurrency == 'swift-concurrency'}}
/// Actor-isolated multi-provider analytics engine for Swift Concurrency.
public actor __MODULE_NAME__: AnalyticsTracking {
    private var providers: [AnalyticsProviderIdentifier: any AnalyticsProvider] = [:]

    public init(providers: [any AnalyticsProvider] = [ConsoleAnalyticsProvider()]) {
        for provider in providers {
            self.providers[provider.identifier] = provider
        }
    }

    public func addProvider(_ provider: any AnalyticsProvider) {
        providers[provider.identifier] = provider
    }

    public func track(_ event: any AnalyticsEvent) {
        if let targets = event.targetProviders {
            track(event, to: targets)
        } else {
            for provider in providers.values {
                provider.track(event)
            }
        }
    }

    public func track(_ event: any AnalyticsEvent, to targetProviders: [AnalyticsProviderIdentifier]) {
        for target in targetProviders {
            providers[target]?.track(event)
        }
    }

    public func track(_ event: any AnalyticsEvent, to targetProvider: AnalyticsProviderIdentifier) {
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
{{else}}
/// Thread-safe lock-based multi-provider analytics tracking engine.
public final class __MODULE_NAME__: @unchecked Sendable, AnalyticsTracking {
    private let lock = NSLock()
    private var providers: [AnalyticsProviderIdentifier: any AnalyticsProvider] = [:]

    public init(providers: [any AnalyticsProvider] = [ConsoleAnalyticsProvider()]) {
        for provider in providers {
            self.providers[provider.identifier] = provider
        }
    }

    public func addProvider(_ provider: any AnalyticsProvider) {
        lock.lock()
        defer { lock.unlock() }
        providers[provider.identifier] = provider
    }

    public func track(_ event: any AnalyticsEvent) {
        if let targets = event.targetProviders {
            track(event, to: targets)
        } else {
            lock.lock()
            let providerList = Array(providers.values)
            lock.unlock()
            for provider in providerList {
                provider.track(event)
            }
        }
    }

    public func track(_ event: any AnalyticsEvent, to targetProviders: [AnalyticsProviderIdentifier]) {
        lock.lock()
        let matching = targetProviders.compactMap { providers[$0] }
        lock.unlock()
        for provider in matching {
            provider.track(event)
        }
    }

    public func track(_ event: any AnalyticsEvent, to targetProvider: AnalyticsProviderIdentifier) {
        lock.lock()
        let provider = providers[targetProvider]
        lock.unlock()
        provider?.track(event)
    }

    public func setUserId(_ userId: String?) {
        lock.lock()
        let providerList = Array(providers.values)
        lock.unlock()
        for provider in providerList {
            provider.setUserId(userId)
        }
    }

    public func setUserProperty(key: String, value: String?) {
        lock.lock()
        let providerList = Array(providers.values)
        lock.unlock()
        for provider in providerList {
            provider.setUserProperty(key: key, value: value)
        }
    }
}
{{/if}}
