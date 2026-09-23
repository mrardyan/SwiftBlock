import Foundation

/// Universal protocol contract standardizing domain value objects (primitives).
public protocol __MODULE_NAME__: Codable, Hashable, Sendable, CustomStringConvertible {
    associatedtype RawValue: Sendable, Codable, Hashable

    /// Underlying primitive raw value.
    var rawValue: RawValue { get }

    /// Failable initializer validating raw value rules.
    init?(rawValue: RawValue)

    /// Validates raw value validity without instantiation.
    static func isValid(_ rawValue: RawValue) -> Bool
}

public extension __MODULE_NAME__ {
    var description: String {
        "\(rawValue)"
    }
}
