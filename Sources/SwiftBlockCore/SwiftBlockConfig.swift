import Foundation

public struct PackagingConfig: Codable, Equatable {
    public var feature: String
    public var core: String

    public init(feature: String = "monolithic", core: String = "spm") {
        self.feature = feature
        self.core = core
    }

    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            self.feature = (try? container.decode(String.self, forKey: .feature)) ?? "monolithic"
            self.core = (try? container.decode(String.self, forKey: .core)) ?? "spm"
        } else if let single = try? decoder.singleValueContainer(),
                  let value = try? single.decode(String.self) {
            self.feature = value
            self.core = value == "spm" ? "spm" : "monolithic"
        } else {
            self.feature = "monolithic"
            self.core = "spm"
        }
    }
}

public struct SwiftBlockConfig: Codable, Equatable {
    public var projectName: String
    public var bundlePrefix: String
    public var packaging: PackagingConfig
    public var organization: String
    public var pathTemplates: [String: String]
    public var overrides: [String: String]
    public var paths: ModulePaths

    enum CodingKeys: String, CodingKey {
        case projectName
        case bundlePrefix
        case packaging
        case organization
        case pathTemplates
        case overrides
        case paths
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.projectName = try container.decode(String.self, forKey: .projectName)
        self.bundlePrefix = (try? container.decode(String.self, forKey: .bundlePrefix)) ?? "com.example"
        self.packaging = (try? container.decode(PackagingConfig.self, forKey: .packaging)) ?? PackagingConfig()
        self.organization = (try? container.decode(String.self, forKey: .organization)) ?? "business-first"
        self.pathTemplates = (try? container.decode([String: String].self, forKey: .pathTemplates)) ?? [
            "feature": "App/Sources/Features/{module}/{block}",
            "core": "Packages/Core/Sources/{block}"
        ]
        self.overrides = (try? container.decode([String: String].self, forKey: .overrides)) ?? [:]
        self.paths = (try? container.decode(ModulePaths.self, forKey: .paths)) ?? ModulePaths()
    }

    public struct ModulePaths: Codable, Equatable {
        private var customPaths: [String: String]

        public init(customPaths: [String: String] = [:]) {
            self.customPaths = customPaths
        }

        public init(from decoder: Decoder) throws {
            if let singleContainer = try? decoder.singleValueContainer(),
               let dict = try? singleContainer.decode([String: String].self) {
                self.customPaths = dict
            } else if let container = try? decoder.container(keyedBy: DynamicCodingKeys.self) {
                var dict: [String: String] = [:]
                for key in container.allKeys {
                    if let val = try? container.decode(String.self, forKey: key) {
                        dict[key.stringValue] = val
                    }
                }
                self.customPaths = dict
            } else {
                self.customPaths = [:]
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(customPaths)
        }

        public func path(for type: ModuleType) -> String {
            if let custom = customPaths[type.rawValue] {
                return custom
            }
            return BlockRegistry.spec(for: type)?.defaultOutputPath ?? "App/Sources/\(type.rawValue.capitalized)"
        }

        public mutating func setPath(_ path: String, for type: ModuleType) {
            customPaths[type.rawValue] = path
        }

        public subscript(type: ModuleType) -> String {
            get { path(for: type) }
            set { setPath(newValue, for: type) }
        }
    }

    public init(
        projectName: String,
        bundlePrefix: String = "com.example",
        packaging: PackagingConfig = PackagingConfig(),
        organization: String = "business-first",
        pathTemplates: [String: String] = [
            "feature": "App/Sources/Features/{module}/{block}",
            "core": "Packages/Core/Sources/{block}"
        ],
        overrides: [String: String] = [:],
        paths: ModulePaths = ModulePaths()
    ) {
        self.projectName = projectName
        self.bundlePrefix = bundlePrefix
        self.packaging = packaging
        self.organization = organization
        self.pathTemplates = pathTemplates
        self.overrides = overrides
        self.paths = paths
    }

    public func resolveOutputPath(for type: ModuleType, moduleName: String) -> String {
        let blockName = type.rawValue.lowercased()

        // Priority 1: Check overrides in .swiftblock
        if let overridePath = overrides[blockName] {
            return BlockDiscoveryEngine.evaluateTokens(in: overridePath, moduleName: moduleName, blockName: blockName)
        }

        // Priority 2: Check pathTemplates in .swiftblock
        let categoryKey = type.category.rawValue
        if let template = pathTemplates[categoryKey] {
            return BlockDiscoveryEngine.evaluateTokens(in: template, moduleName: moduleName, blockName: blockName)
        }

        // Priority 3: Check block.json metadata or fallback
        if let defaultPath = BlockRegistry.spec(for: type)?.defaultOutputPath {
            return BlockDiscoveryEngine.evaluateTokens(in: defaultPath, moduleName: moduleName, blockName: blockName)
        }

        // Priority 4: Standard engine fallback
        return paths.path(for: type)
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

private struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
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
        BlockRegistry.spec(for: self)?.category ?? .feature
    }
}
