import Foundation

/// Type-safe identifier using phantom typing to prevent mixing IDs of different domain entities at compile time.
public struct __MODULE_NAME__<Tag, RawValue: Hashable & Codable & Sendable>: Codable, Equatable, Hashable, Sendable, RawRepresentable, CustomStringConvertible {
    public let rawValue: RawValue

    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: RawValue) {
        self.rawValue = rawValue
    }

    public var description: String {
        String(describing: rawValue)
    }
}

extension __MODULE_NAME__: ExpressibleByUnicodeScalarLiteral where RawValue == String {
    public init(unicodeScalarLiteral value: String) {
        self.rawValue = value
    }
}

extension __MODULE_NAME__: ExpressibleByExtendedGraphemeClusterLiteral where RawValue == String {
    public init(extendedGraphemeClusterLiteral value: String) {
        self.rawValue = value
    }
}

extension __MODULE_NAME__: ExpressibleByStringLiteral where RawValue == String {
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

extension __MODULE_NAME__: ExpressibleByIntegerLiteral where RawValue == Int {
    public init(integerLiteral value: Int) {
        self.rawValue = value
    }
}

/// Convenient typealias for phantom ID
public typealias ID<Tag> = __MODULE_NAME__<Tag, String>
