import Foundation

public struct SwiftBlockConfig: Codable, Equatable {
    public static let defaultKits: [String: [String]] = [
        "clean-feature": ["scene", "usecase", "repository", "service"],
        "feature": ["scene", "usecase", "repository", "mapper"],
        "simple": ["scene", "service"],
        "data": ["repository", "service", "entity"]
    ]

    public var projectName: String
    public var bundlePrefix: String
    public var packaging: PackagingConfig
    public var organization: String
    public var generatorTool: ProjectGeneratorTool
    public var guardrails: GuardrailsConfig
    public var cicd: CICDConfig
    public var toolVersions: [String: String]
    public var coreBlocks: [Brick]
    public var gitInit: Bool
    public var pathTemplates: [String: String]
    public var overrides: [String: String]
    public var paths: ModulePaths
    public var kits: [String: [String]]

    enum CodingKeys: String, CodingKey {
        case projectName
        case bundlePrefix
        case packaging
        case organization
        case generatorTool
        case guardrails
        case cicd
        case toolVersions
        case coreBlocks
        case gitInit
        case pathTemplates
        case overrides
        case paths
        case kits
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.projectName = try container.decode(String.self, forKey: .projectName)
        self.bundlePrefix = (try? container.decode(String.self, forKey: .bundlePrefix)) ?? "com.company"
        self.packaging = (try? container.decode(PackagingConfig.self, forKey: .packaging)) ?? PackagingConfig()
        let decodedOrg = (try? container.decode(String.self, forKey: .organization)) ?? "feature-first"
        self.organization = (decodedOrg == "business-first") ? "feature-first" : decodedOrg
        self.generatorTool = (try? container.decode(ProjectGeneratorTool.self, forKey: .generatorTool)) ?? .tuist
        self.guardrails = (try? container.decode(GuardrailsConfig.self, forKey: .guardrails)) ?? GuardrailsConfig.all
        self.cicd = (try? container.decode(CICDConfig.self, forKey: .cicd)) ?? CICDConfig()
        self.toolVersions = (try? container.decode([String: String].self, forKey: .toolVersions)) ?? [:]
        self.coreBlocks = (try? container.decode([Brick].self, forKey: .coreBlocks)) ?? [.storage, .network, .logger, .config]
        self.gitInit = (try? container.decode(Bool.self, forKey: .gitInit)) ?? true
        self.pathTemplates = (try? container.decode([String: String].self, forKey: .pathTemplates)) ?? [
            "feature": "App/Sources/Features/{module}/{block}",
            "core": "Packages/Core/Sources/Core/{block}"
        ]
        self.overrides = (try? container.decode([String: String].self, forKey: .overrides)) ?? [:]
        self.paths = (try? container.decode(ModulePaths.self, forKey: .paths)) ?? ModulePaths()
        self.kits = (try? container.decode([String: [String]].self, forKey: .kits)) ?? SwiftBlockConfig.defaultKits
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(projectName, forKey: .projectName)
        try container.encode(bundlePrefix, forKey: .bundlePrefix)
        try container.encode(packaging, forKey: .packaging)
        try container.encode(organization, forKey: .organization)
        try container.encode(generatorTool, forKey: .generatorTool)
        try container.encode(guardrails, forKey: .guardrails)
        try container.encode(cicd, forKey: .cicd)
        try container.encode(toolVersions, forKey: .toolVersions)
        try container.encode(coreBlocks, forKey: .coreBlocks)
        try container.encode(gitInit, forKey: .gitInit)
        try container.encode(pathTemplates, forKey: .pathTemplates)
        try container.encode(overrides, forKey: .overrides)
        try container.encode(paths, forKey: .paths)
        try container.encode(kits, forKey: .kits)
    }

    public struct ModulePaths: Codable, Equatable {
        private var customPaths: [String: String]

        public var allCustomPaths: [String: String] {
            return customPaths
        }

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

        public func path(for type: Brick) -> String {
            if let custom = customPaths[type.rawValue] {
                return custom
            }
            return BrickRegistry.spec(for: type)?.defaultOutputPath ?? "App/Sources/\(type.rawValue.capitalized)"
        }

        public mutating func setPath(_ path: String, for type: Brick) {
            customPaths[type.rawValue] = path
        }

        public subscript(type: Brick) -> String {
            get { path(for: type) }
            set { setPath(newValue, for: type) }
        }
    }

    public typealias BrickPaths = ModulePaths

    public init(
        projectName: String,
        bundlePrefix: String = "com.company",
        packaging: PackagingConfig = PackagingConfig(),
        organization: String = "feature-first",
        generatorTool: ProjectGeneratorTool = .tuist,
        guardrails: GuardrailsConfig = .all,
        cicd: CICDConfig = CICDConfig(),
        toolVersions: [String: String] = [:],
        coreBlocks: [Brick] = [.storage, .network, .logger, .config],
        gitInit: Bool = true,
        pathTemplates: [String: String] = [
            "feature": "App/Sources/Features/{module}/{block}",
            "core": "Packages/Core/Sources/Core/{block}"
        ],
        overrides: [String: String] = [:],
        paths: ModulePaths = ModulePaths(),
        kits: [String: [String]] = SwiftBlockConfig.defaultKits
    ) {
        self.projectName = projectName
        self.bundlePrefix = bundlePrefix
        self.packaging = packaging
        self.organization = organization
        self.generatorTool = generatorTool
        self.guardrails = guardrails
        self.cicd = cicd
        self.toolVersions = toolVersions
        self.coreBlocks = coreBlocks
        self.gitInit = gitInit
        self.pathTemplates = pathTemplates
        self.overrides = overrides
        self.paths = paths
        self.kits = kits
    }

    public func resolveOutputPath(for type: Brick, moduleName: String) -> String {
        let blockName = type.rawValue.lowercased()

        // Priority 1: Check overrides in .swiftblock
        if let overridePath = overrides[blockName] {
            return BrickDiscoveryEngine.evaluateTokens(in: overridePath, moduleName: moduleName, blockName: blockName)
        }

        // Priority 2: Check pathTemplates in .swiftblock
        let categoryKey = type.category.rawValue
        if let template = pathTemplates[categoryKey] {
            return BrickDiscoveryEngine.evaluateTokens(in: template, moduleName: moduleName, blockName: blockName)
        }

        // Priority 3: Check block.json metadata or fallback
        if let defaultPath = BrickRegistry.spec(for: type)?.defaultOutputPath {
            return BrickDiscoveryEngine.evaluateTokens(in: defaultPath, moduleName: moduleName, blockName: blockName)
        }

        // Priority 4: Standard engine fallback
        return paths.path(for: type)
    }

    public static func findProjectRoot(from startPath: String = FileManager.default.currentDirectoryPath) -> String? {
        let fileManager = FileManager.default
        var current = (startPath as NSString).standardizingPath

        while !current.isEmpty && current != "/" {
            let yml = "\(current)/.swiftblock/config.yml"
            let yaml = "\(current)/.swiftblock/config.yaml"
            let dotConfig = "\(current)/.swiftblock"
            if fileManager.fileExists(atPath: yml) || fileManager.fileExists(atPath: yaml) || fileManager.fileExists(atPath: dotConfig) {
                return current
            }
            let parent = (current as NSString).deletingLastPathComponent
            if parent == current { break }
            current = parent
        }
        return nil
    }

    public static func load(from directoryPath: String = FileManager.default.currentDirectoryPath) throws -> SwiftBlockConfig {
        let fileManager = FileManager.default
        let resolvedDirectory = findProjectRoot(from: directoryPath) ?? directoryPath
        let ymlConfigPath = "\(resolvedDirectory)/.swiftblock/config.yml"
        let yamlConfigPath = "\(resolvedDirectory)/.swiftblock/config.yaml"
        let rootConfigPath = "\(resolvedDirectory)/.swiftblock"
        
        var targetPath: String?
        if fileManager.fileExists(atPath: ymlConfigPath) {
            targetPath = ymlConfigPath
        } else if fileManager.fileExists(atPath: yamlConfigPath) {
            targetPath = yamlConfigPath
        } else if fileManager.fileExists(atPath: rootConfigPath) {
            targetPath = rootConfigPath
        }
        
        guard let finalPath = targetPath else {
            throw SwiftBlockConfigError.configNotFound("\(directoryPath)/.swiftblock/config.yml")
        }
        
        let data = try Data(contentsOf: URL(fileURLWithPath: finalPath))
        if let config = try? JSONDecoder().decode(SwiftBlockConfig.self, from: data) {
            return config
        }
        
        if let content = String(data: data, encoding: .utf8) {
            let parsed = SimpleYAMLParser.parse(content)
            let name = (parsed["projectName"] as? String) ?? "App"
            let prefix = (parsed["bundlePrefix"] as? String) ?? "com.company"
            let toolStr = (parsed["generatorTool"] as? String) ?? "tuist"
            let tool = ProjectGeneratorTool(rawValue: toolStr.lowercased()) ?? .tuist
            let org = (parsed["organization"] as? String) ?? "feature-first"
            
            var pkg = PackagingConfig()
            if let pkgDict = parsed["packaging"] as? [String: Any] {
                pkg.feature = (pkgDict["feature"] as? String) ?? "monolithic"
                pkg.core = (pkgDict["core"] as? String) ?? "spm"
            }
            
            var cicdCfg = CICDConfig()
            if let cicdDict = parsed["cicd"] as? [String: Any],
               let providerStr = cicdDict["provider"] as? String,
               let prov = CICDProvider(rawValue: providerStr) {
                cicdCfg.provider = prov
            }
            
            var customPaths: [String: String] = [:]
            if let pathsDict = parsed["paths"] as? [String: Any] {
                for (k, v) in pathsDict {
                    if let str = v as? String { customPaths[k] = str }
                }
            }
            
            var overridesDict: [String: String] = [:]
            if let ovDict = parsed["overrides"] as? [String: Any] {
                for (k, v) in ovDict {
                    if let str = v as? String { overridesDict[k] = str }
                }
            }
            
            var kitsDict: [String: [String]] = SwiftBlockConfig.defaultKits
            if let kDict = parsed["kits"] as? [String: [String]] {
                kitsDict = kDict
            }
            
            return SwiftBlockConfig(
                projectName: name,
                bundlePrefix: prefix,
                packaging: pkg,
                organization: org,
                generatorTool: tool,
                cicd: cicdCfg,
                overrides: overridesDict,
                paths: ModulePaths(customPaths: customPaths),
                kits: kitsDict
            )
        }
        
        throw SwiftBlockConfigError.configNotFound(finalPath)
    }

    public func save(to directoryPath: String = FileManager.default.currentDirectoryPath) throws {
        let fileManager = FileManager.default
        let folderPath = "\(directoryPath)/.swiftblock"
        var isDir: ObjCBool = false
        if fileManager.fileExists(atPath: folderPath, isDirectory: &isDir) {
            if !isDir.boolValue {
                try? fileManager.removeItem(atPath: folderPath)
                try fileManager.createDirectory(atPath: folderPath, withIntermediateDirectories: true)
            }
        } else {
            try fileManager.createDirectory(atPath: folderPath, withIntermediateDirectories: true)
        }
        
        let configFilePath = "\(folderPath)/config.yml"
        
        var yaml = """
        # SwiftBlock Project Configuration (.swiftblock/config.yml)
        projectName: \(projectName)
        bundlePrefix: \(bundlePrefix)
        organization: \(organization)
        generatorTool: \(generatorTool.rawValue)

        packaging:
          feature: \(packaging.feature)
          core: \(packaging.core)

        cicd:
          provider: \(cicd.provider.rawValue)

        paths:
        """
        
        let allPaths = paths.allCustomPaths
        if allPaths.isEmpty {
            yaml += "\n  scene: App/Sources/Features\n  network: App/Sources/Core/Network"
        } else {
            for (key, val) in allPaths.sorted(by: { $0.key < $1.key }) {
                yaml += "\n  \(key): \(val)"
            }
        }
        
        if !overrides.isEmpty {
            yaml += "\n\noverrides:"
            for (key, val) in overrides.sorted(by: { $0.key < $1.key }) {
                yaml += "\n  \(key): \(val)"
            }
        }
        
        yaml += "\n\nkits:"
        for (kitName, bricksList) in kits.sorted(by: { $0.key < $1.key }) {
            yaml += "\n  \(kitName):"
            for b in bricksList {
                yaml += "\n    - \(b)"
            }
        }
        
        yaml += "\n"
        try yaml.write(toFile: configFilePath, atomically: true, encoding: .utf8)
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
    case encodingFailed

    public var errorDescription: String? {
        switch self {
        case .configNotFound(let path):
            return "Not a valid SwiftBlock project root (.swiftblock not found at \(path))"
        case .encodingFailed:
            return "Failed to encode SwiftBlock configuration to JSON."
        }
    }
}
