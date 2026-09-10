import Foundation

// MARK: - Feature Flag Definition & Expiration Metadata

/// A feature toggle with ownership and expiration metadata.
public struct FeatureFlag: Hashable {
    public let key: String
    public let owner: String
    public let description: String
    public let defaultValue: Bool
    public let expirationDate: Date?

    public init(
        key: String,
        owner: String = "Unassigned",
        description: String = "",
        defaultValue: Bool = false,
        expirationDate: Date? = nil
    ) {
        self.key = key
        self.owner = owner
        self.description = description
        self.defaultValue = defaultValue
        self.expirationDate = expirationDate
    }

    /// Indicates whether the flag has passed its expiration date.
    public var isExpired: Bool {
        guard let expirationDate = expirationDate else { return false }
        return Date() > expirationDate
    }
}

// MARK: - Feature Flag Provider & Managing Protocols

/// A remote provider for feature flags (e.g. Firebase Remote Config).
public protocol FeatureFlagProvider {
    func isEnabled(_ flag: FeatureFlag) -> Bool
}

/// Interface for evaluating feature flags and managing local overrides.
public protocol FeatureFlagManaging {
    func isEnabled(_ flag: FeatureFlag) -> Bool
    func setOverride(_ isEnabled: Bool?, for flag: FeatureFlag)
    func checkExpiredFlags() -> [FeatureFlag]
}

// MARK: - Default Manager Implementation

/// Feature flag manager supporting local overrides, remote providers, and expiration audits.
public final class __MODULE_NAME__: FeatureFlagManaging {
    private let remoteProvider: FeatureFlagProvider?
    private var localOverrides: [String: Bool] = [:]
    private let registeredFlags: [FeatureFlag]

    public init(
        remoteProvider: FeatureFlagProvider? = nil,
        registeredFlags: [FeatureFlag] = []
    ) {
        self.remoteProvider = remoteProvider
        self.registeredFlags = registeredFlags
    }

    public func isEnabled(_ flag: FeatureFlag) -> Bool {
        #if DEBUG
        if flag.isExpired {
            print("⚠️ [FeatureFlag Warning] Flag '\(flag.key)' (Owner: \(flag.owner)) EXPIRED on \(flag.expirationDate?.description ?? "N/A"). Time to remove/clean up this flag!")
        }
        #endif

        if let override = localOverrides[flag.key] {
            return override
        }

        if let remote = remoteProvider {
            return remote.isEnabled(flag)
        }

        return flag.defaultValue
    }

    public func setOverride(_ isEnabled: Bool?, for flag: FeatureFlag) {
        if let value = isEnabled {
            localOverrides[flag.key] = value
        } else {
            localOverrides.removeValue(forKey: flag.key)
        }
    }

    public func checkExpiredFlags() -> [FeatureFlag] {
        registeredFlags.filter { $0.isExpired }
    }
}
