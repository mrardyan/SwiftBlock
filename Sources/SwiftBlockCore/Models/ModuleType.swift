import Foundation

public struct ModuleType: RawRepresentable, ExpressibleByStringLiteral, Hashable, Codable, CustomStringConvertible, LosslessStringConvertible {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue.lowercased()
    }

    public init(_ description: String) {
        self.rawValue = description.lowercased()
    }

    public init(stringLiteral value: String) {
        self.rawValue = value.lowercased()
    }

    public var description: String {
        return rawValue
    }

    // Built-in Standard Presets
    public static let scene: ModuleType = "scene"
    public static let usecase: ModuleType = "usecase"
    public static let repository: ModuleType = "repository"
    public static let service: ModuleType = "service"
    public static let entity: ModuleType = "entity"
    public static let coordinator: ModuleType = "coordinator"
    public static let component: ModuleType = "component"
    public static let mapper: ModuleType = "mapper"
    public static let validator: ModuleType = "validator"

    public static let storage: ModuleType = "storage"
    public static let network: ModuleType = "network"
    public static let logger: ModuleType = "logger"
    public static let analytics: ModuleType = "analytics"
    public static let config: ModuleType = "config"
    public static let auth: ModuleType = "auth"
    public static let featureflag: ModuleType = "featureflag"

    public static var allCases: [ModuleType] {
        [
            .scene, .usecase, .repository, .service, .entity,
            .coordinator, .component, .mapper, .validator,
            .storage, .network, .logger, .analytics, .config, .auth, .featureflag
        ]
    }

    public var category: ModuleCategory {
        BlockRegistry.spec(for: self)?.category ?? .feature
    }
}
