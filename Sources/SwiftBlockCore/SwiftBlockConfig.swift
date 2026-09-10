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
        public var mapper: String
        public var validator: String
        public var storage: String
        public var network: String
        public var logger: String
        public var analytics: String
        public var config: String
        public var auth: String
        public var featureflag: String

        public init(
            scene: String = BlockRegistry.spec(for: .scene)?.defaultOutputPath ?? "App/Sources/Features",
            usecase: String = BlockRegistry.spec(for: .usecase)?.defaultOutputPath ?? "App/Sources/Domain/UseCases",
            repository: String = BlockRegistry.spec(for: .repository)?.defaultOutputPath ?? "App/Sources/Data/Repositories",
            service: String = BlockRegistry.spec(for: .service)?.defaultOutputPath ?? "App/Sources/Data/Services",
            entity: String = BlockRegistry.spec(for: .entity)?.defaultOutputPath ?? "App/Sources/Domain/Entities",
            coordinator: String = BlockRegistry.spec(for: .coordinator)?.defaultOutputPath ?? "App/Sources/Presentation/Coordinators",
            component: String = BlockRegistry.spec(for: .component)?.defaultOutputPath ?? "App/Sources/Presentation/Components",
            mapper: String = BlockRegistry.spec(for: .mapper)?.defaultOutputPath ?? "App/Sources/Domain/Mappers",
            validator: String = BlockRegistry.spec(for: .validator)?.defaultOutputPath ?? "App/Sources/Presentation/Validators",
            storage: String = BlockRegistry.spec(for: .storage)?.defaultOutputPath ?? "App/Sources/Core/Storage",
            network: String = BlockRegistry.spec(for: .network)?.defaultOutputPath ?? "App/Sources/Core/Network",
            logger: String = BlockRegistry.spec(for: .logger)?.defaultOutputPath ?? "App/Sources/Core/Logger",
            analytics: String = BlockRegistry.spec(for: .analytics)?.defaultOutputPath ?? "App/Sources/Core/Analytics",
            config: String = BlockRegistry.spec(for: .config)?.defaultOutputPath ?? "App/Sources/Core/Config",
            auth: String = BlockRegistry.spec(for: .auth)?.defaultOutputPath ?? "App/Sources/Core/Auth",
            featureflag: String = BlockRegistry.spec(for: .featureflag)?.defaultOutputPath ?? "App/Sources/Core/FeatureFlag"
        ) {
            self.scene = scene
            self.usecase = usecase
            self.repository = repository
            self.service = service
            self.entity = entity
            self.coordinator = coordinator
            self.component = component
            self.mapper = mapper
            self.validator = validator
            self.storage = storage
            self.network = network
            self.logger = logger
            self.analytics = analytics
            self.config = config
            self.auth = auth
            self.featureflag = featureflag
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
            case .mapper: return mapper
            case .validator: return validator
            case .storage: return storage
            case .network: return network
            case .logger: return logger
            case .analytics: return analytics
            case .config: return config
            case .auth: return auth
            case .featureflag: return featureflag
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
        switch self {
        case .scene, .usecase, .repository, .service, .entity, .coordinator, .component, .mapper, .validator:
            return .feature
        case .storage, .network, .logger, .analytics, .config, .auth, .featureflag:
            return .core
        }
    }
}



