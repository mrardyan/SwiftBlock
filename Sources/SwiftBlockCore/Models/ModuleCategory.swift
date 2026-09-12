import Foundation

public struct ModuleCategory: RawRepresentable, ExpressibleByStringLiteral, Hashable, Codable, CustomStringConvertible {
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

    // Preset Constants
    public static let feature: ModuleCategory = "feature"
    public static let core: ModuleCategory = "core"
    public static let ui: ModuleCategory = "ui"
    public static let domain: ModuleCategory = "domain"
    public static let data: ModuleCategory = "data"
    public static let presentation: ModuleCategory = "presentation"

    public var isSingleton: Bool {
        return self == .core || rawValue == "infrastructure" || rawValue == "singletons"
    }
}
