import Foundation

/// Pure String-backed Value Object representing a brick identifier.
public struct Brick: RawRepresentable, ExpressibleByStringLiteral, Hashable, Codable, CustomStringConvertible, LosslessStringConvertible {
    public let rawValue: String

    public init(rawValue: String) {
        var clean = rawValue
        if clean.contains("/") {
            clean = String(clean.split(separator: "/").last ?? Substring(clean))
        } else if clean.contains(".") {
            clean = String(clean.split(separator: ".").last ?? Substring(clean))
        }
        self.rawValue = clean.lowercased()
    }

    public init(_ description: String) {
        self.init(rawValue: description)
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    public var description: String {
        rawValue
    }

    public var category: Brick.Category {
        BrickRegistry.spec(for: self)?.category ?? .feature
    }
}

public extension Brick {
    /// Pure String-backed Value Object representing an architectural layer / category.
    struct Category: RawRepresentable, ExpressibleByStringLiteral, Hashable, Codable, CustomStringConvertible {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue.lowercased()
        }

        public init(stringLiteral value: String) {
            rawValue = value.lowercased()
        }

        public var description: String {
            rawValue
        }
    }
}
