import Foundation

/// Errors thrown by semantic version parsing.
public enum SemanticVersionError: Error, Equatable, Sendable {
    case invalidFormat(String)
}

/// Type-safe representation of semantic versioning (major.minor.patch).
public struct __MODULE_NAME__: Codable, Equatable, Hashable, Sendable, Comparable, CustomStringConvertible, ExpressibleByStringLiteral {
    public let major: Int
    public let minor: Int
    public let patch: Int

    public init(major: Int, minor: Int, patch: Int = 0) {
        self.major = max(0, major)
        self.minor = max(0, minor)
        self.patch = max(0, patch)
    }

    public init(string: String) throws {
        let cleaned = string.hasPrefix("v") ? String(string.dropFirst()) : string
        let parts = cleaned.split(separator: ".").compactMap { Int($0) }
        guard (2...3).contains(parts.count) else {
            throw SemanticVersionError.invalidFormat(string)
        }
        self.major = parts[0]
        self.minor = parts[1]
        self.patch = parts.count == 3 ? parts[2] : 0
    }

    public init(stringLiteral value: String) {
        try! self.init(string: value)
    }

    public var description: String {
        "\(major).\(minor).\(patch)"
    }

    public var formatted: String {
        description
    }

    /// Whether this version is compatible with another (same major version).
    public func isCompatible(with other: __MODULE_NAME__) -> Bool {
        major == other.major
    }

    public static func < (lhs: __MODULE_NAME__, rhs: __MODULE_NAME__) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        return lhs.patch < rhs.patch
    }
}
