import Foundation

// MARK: - Feature Flag Definition & Expiration Metadata

/// Represents a feature flag definition with owner and expiration metadata.
public struct FeatureFlag: Hashable {
    /// Unique feature flag key identifier.
    public let key: String

    /// Team or developer owner of the feature flag.
    public let owner: String

    /// Description of the feature toggle functionality.
    public let description: String

    /// Fallback default value when remote or override values are absent.
    public let defaultValue: Bool

    /// Target expiration date for flag cleanup.
    public let expirationDate: Date?

    /// Initializes a feature flag definition.
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

    /// Checks if the feature flag has passed its intended expiration date.
    public var isExpired: Bool {
        guard let expirationDate = expirationDate else { return false }
        return Date() > expirationDate
    }
}

// MARK: - Feature Flag Provider & Managing Protocols

/// Protocol for remote feature flag providers (e.g. Firebase Remote Config, LaunchDarkly).
public protocol FeatureFlagProvider {
    /// Determines whether a flag is enabled on the remote provider.
    func isEnabled(_ flag: FeatureFlag) -> Bool
}

/// Interface for feature flag evaluation and local override management.
public protocol FeatureFlagManaging {
    /// Evaluates if a feature flag is enabled considering local overrides, remote providers, and defaults.
    func isEnabled(_ flag: FeatureFlag) -> Bool

    /// Sets or removes an in-memory local override for a feature flag.
    func setOverride(_ isEnabled: Bool?, for flag: FeatureFlag)

    /// Audits registered flags and returns all flags that have passed their expiration date.
    func checkExpiredFlags() -> [FeatureFlag]
}

// MARK: - Default Manager Implementation

/// Default feature flag manager supporting local overrides, remote providers, and expiration warnings.
public final class __MODULE_NAME__: FeatureFlagManaging {
    private let remoteProvider: FeatureFlagProvider?
    private var localOverrides: [String: Bool] = [:]
    private let registeredFlags: [FeatureFlag]

    /// Initializes manager with remote provider and registered flag definitions.
    public init(
        remoteProvider: FeatureFlagProvider? = nil,
        registeredFlags: [FeatureFlag] = []
    ) {
        self.remoteProvider = remoteProvider
        self.registeredFlags = registeredFlags
    }

    /// Evaluates whether the given feature flag is active.
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

    /// Configures or resets a local debug override value for a flag.
    public func setOverride(_ isEnabled: Bool?, for flag: FeatureFlag) {
        if let value = isEnabled {
            localOverrides[flag.key] = value
        } else {
            localOverrides.removeValue(forKey: flag.key)
        }
    }

    /// Returns a list of all flags that are past their expiration date.
    public func checkExpiredFlags() -> [FeatureFlag] {
        registeredFlags.filter { $0.isExpired }
    }
}

