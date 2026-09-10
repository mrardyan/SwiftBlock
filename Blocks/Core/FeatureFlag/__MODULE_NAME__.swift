import Foundation

// MARK: - Feature Flag Definition & Expiration Metadata

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

    /// Checks if the feature flag has passed its intended expiration date
    public var isExpired: Bool {
        guard let expirationDate = expirationDate else { return false }
        return Date() > expirationDate
    }
}

// MARK: - Feature Flag Provider & Managing Protocols

public protocol FeatureFlagProvider {
    func isEnabled(_ flag: FeatureFlag) -> Bool
}

public protocol FeatureFlagManaging {
    func isEnabled(_ flag: FeatureFlag) -> Bool
    func setOverride(_ isEnabled: Bool?, for flag: FeatureFlag)
    func checkExpiredFlags() -> [FeatureFlag]
}

// MARK: - Default Manager Implementation

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
