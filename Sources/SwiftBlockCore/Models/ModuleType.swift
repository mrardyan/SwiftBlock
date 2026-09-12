import Foundation

public enum ModuleCategory: String, Codable {
    case feature
    case core
}

public enum ModuleType: String, CaseIterable, Codable {
    case scene
    case usecase
    case repository
    case service
    case entity
    case coordinator
    case component
    case mapper
    case validator
    case storage
    case network
    case logger
    case analytics
    case config
    case auth
    case featureflag

    public var category: ModuleCategory {
        BlockRegistry.spec(for: self)?.category ?? .feature
    }
}
