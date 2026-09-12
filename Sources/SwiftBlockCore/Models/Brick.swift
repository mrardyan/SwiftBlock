import Foundation

/// Pure String-backed Value Object representing a brick identifier.
public struct Brick: RawRepresentable, ExpressibleByStringLiteral, Hashable, Codable, CustomStringConvertible, LosslessStringConvertible {
    public let rawValue: String

    public init(rawValue: String) {
        let clean = rawValue.contains("/") ? String(rawValue.split(separator: "/").last!) :
                    (rawValue.contains(".") ? String(rawValue.split(separator: ".").last!) : rawValue)
        self.rawValue = clean.lowercased()
    }

    public init(_ description: String) {
        self.init(rawValue: description)
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }

    public var description: String {
        return rawValue
    }

    public var category: Brick.Category {
        BrickRegistry.spec(for: self)?.category ?? .feature
    }
}

extension Brick {
    /// Pure String-backed Value Object representing an architectural layer / category.
    public struct Category: RawRepresentable, ExpressibleByStringLiteral, Hashable, Codable, CustomStringConvertible {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue.lowercased()
        }

        public init(stringLiteral value: String) {
            self.rawValue = value.lowercased()
        }

        public var description: String {
            return rawValue
        }
    }
}
