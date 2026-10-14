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
        let rawParts = cleaned.split(separator: ".", omittingEmptySubsequences: false)
        guard (2...3).contains(rawParts.count) else {
            throw SemanticVersionError.invalidFormat(string)
        }
        var intParts: [Int] = []
        for part in rawParts {
            guard let val = Int(part), val >= 0 else {
                throw SemanticVersionError.invalidFormat(string)
            }
            intParts.append(val)
        }
        self.major = intParts[0]
        self.minor = intParts[1]
        self.patch = intParts.count == 3 ? intParts[2] : 0
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
