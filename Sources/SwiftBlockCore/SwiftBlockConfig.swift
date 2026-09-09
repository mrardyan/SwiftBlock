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

        public init(
            scene: String = "App/Sources/Features",
            usecase: String = "App/Sources/Domain/UseCases",
            repository: String = "App/Sources/Data/Repositories",
            service: String = "App/Sources/Data/Services"
        ) {
            self.scene = scene
            self.usecase = usecase
            self.repository = repository
            self.service = service
        }

        public func path(for type: ModuleType) -> String {
            switch type {
            case .scene: return scene
            case .usecase: return usecase
            case .repository: return repository
            case .service: return service
            }
        }
    }

    public init(
        projectName: String,
        bundlePrefix: String = "io.ardyan",
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

public enum ModuleType: String, CaseIterable {
    case scene
    case usecase
    case repository
    case service
}
