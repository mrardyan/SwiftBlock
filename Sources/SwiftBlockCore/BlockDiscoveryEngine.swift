import Foundation

public struct BlockMetadata: Codable {
    public let title: String?
    public let description: String?
    public let defaultOutputPath: String?

    public init(title: String? = nil, description: String? = nil, defaultOutputPath: String? = nil) {
        self.title = title
        self.description = description
        self.defaultOutputPath = defaultOutputPath
    }
}

public struct BlockDiscoveryEngine {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// Discovers all block specs inside a base template directory (e.g. /usr/local/share/swiftblock/Blocks)
    public func discoverBlocks(in baseTemplatePath: String, category: ModuleCategory) -> [BlockSpec] {
        let subfolder = category == .feature ? "Modules" : "Core"
        let categoryDir = "\(baseTemplatePath)/\(subfolder)"

        guard fileManager.fileExists(atPath: categoryDir),
              let folderNames = try? fileManager.contentsOfDirectory(atPath: categoryDir) else {
            return fallbackSpecs(for: category)
        }

        var specs: [BlockSpec] = []

        for folderName in folderNames.sorted() {
            let fullPath = "\(categoryDir)/\(folderName)"
            var isDir: ObjCBool = false
            guard fileManager.fileExists(atPath: fullPath, isDirectory: &isDir), isDir.boolValue else {
                continue
            }

            // Level-1 folder directly under category is the Block Root
            let commandName = folderName.lowercased()
            let metadataPath = "\(fullPath)/block.json"
            var metadata: BlockMetadata? = nil

            if fileManager.fileExists(atPath: metadataPath),
               let data = try? Data(contentsOf: URL(fileURLWithPath: metadataPath)) {
                metadata = try? JSONDecoder().decode(BlockMetadata.self, from: data)
            }

            let title = metadata?.title ?? folderName
            let description = metadata?.description ?? "\(folderName) Block"
            let defaultOutputPath = metadata?.defaultOutputPath ?? (category == .feature ? "App/Sources/Features/{module}/\(folderName)" : "App/Sources/Core/\(folderName)")
            let moduleType = ModuleType(rawValue: commandName) ?? .scene

            let spec = BlockSpec(
                type: moduleType,
                commandName: commandName,
                title: title,
                description: description,
                category: category,
                defaultOutputPath: defaultOutputPath,
                defaultTemplateSubpath: "\(subfolder)/\(folderName)"
            )
            specs.append(spec)
        }

        return specs.isEmpty ? fallbackSpecs(for: category) : specs
    }

    /// Replaces tokens `{module}` and `{block}` in path templates
    public static func evaluateTokens(
        in pathTemplate: String,
        moduleName: String,
        blockName: String
    ) -> String {
        let moduleLower = moduleName.lowercased()
        let blockLower = blockName.lowercased()

        return pathTemplate
            .replacingOccurrences(of: "{module}", with: moduleLower)
            .replacingOccurrences(of: "{block}", with: blockLower)
    }

    private func fallbackSpecs(for category: ModuleCategory) -> [BlockSpec] {
        BlockRegistry.allBlocks.filter { $0.category == category }
    }
}
