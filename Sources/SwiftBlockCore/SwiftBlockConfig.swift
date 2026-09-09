import Foundation

public struct SwiftBlockConfig: Codable {
    public var projectName: String
    public var bundlePrefix: String
    public var paths: ModulePaths

    public struct ModulePaths: Codable {
        public var scene: String
        public var usecase: String
        public var repository: String
        public var service: String
        public var entity: String
        public var coordinator: String
        public var component: String
        public var storage: String
        public var network: String
        public var logger: String
        public var analytics: String

        public init(
            scene: String = "App/Sources/Features",
            usecase: String = "App/Sources/Domain/UseCases",
            repository: String = "App/Sources/Data/Repositories",
            service: String = "App/Sources/Data/Services",
            entity: String = "App/Sources/Domain/Entities",
            coordinator: String = "App/Sources/Presentation/Coordinators",
            component: String = "App/Sources/Presentation/Components",
            storage: String = "App/Sources/Core/Storage",
            network: String = "App/Sources/Core/Network",
            logger: String = "App/Sources/Core/Logger",
            analytics: String = "App/Sources/Core/Analytics"
        ) {
            self.scene = scene
            self.usecase = usecase
            self.repository = repository
            self.service = service
            self.entity = entity
            self.coordinator = coordinator
            self.component = component
            self.storage = storage
            self.network = network
            self.logger = logger
            self.analytics = analytics
        }

        public func path(for type: ModuleType) -> String {
            switch type {
            case .scene: return scene
            case .usecase: return usecase
            case .repository: return repository
            case .service: return service
            case .entity: return entity
            case .coordinator: return coordinator
            case .component: return component
            case .storage: return storage
            case .network: return network
            case .logger: return logger
            case .analytics: return analytics
            }
        }
    }

    public init(
        projectName: String,
        bundlePrefix: String = "com.example",
        paths: ModulePaths = ModulePaths()
    ) {
        self.projectName = projectName
        self.bundlePrefix = bundlePrefix
        self.paths = paths
    }

    public static func load(from directoryPath: String = FileManager.default.currentDirectoryPath) throws -> SwiftBlockConfig {
        let configFilePath = "\(directoryPath)/.swiftblock"
        guard FileManager.default.fileExists(atPath: configFilePath) else {
            throw SwiftBlockConfigError.configNotFound(configFilePath)
        }
        let data = try Data(contentsOf: URL(fileURLWithPath: configFilePath))
        return try JSONDecoder().decode(SwiftBlockConfig.self, from: data)
    }
}

public enum SwiftBlockConfigError: Error, LocalizedError {
    case configNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .configNotFound(let path):
            return "Not a valid SwiftBlock project root (.swiftblock not found at \(path))"
        }
    }
}

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
    case storage
    case network
    case logger
    case analytics

    public var category: ModuleCategory {
        switch self {
        case .scene, .usecase, .repository, .service, .entity, .coordinator, .component:
            return .feature
        case .storage, .network, .logger, .analytics:
            return .core
        }
    }
}


