import Foundation

public struct SwiftBlockConfig: Codable {
    public var projectName: String
    public var bundlePrefix: String
    public var paths: ModulePaths

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
