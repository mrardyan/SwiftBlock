import Foundation

public struct BlueprintExecutionResult {
    public let blueprintName: String
    public let moduleName: String
    public let generatedBlocks: [ModuleType]

    public init(blueprintName: String, moduleName: String, generatedBlocks: [ModuleType]) {
        self.blueprintName = blueprintName
        self.moduleName = moduleName
        self.generatedBlocks = generatedBlocks
    }
}

/// Execution engine for processing multi-block architecture blueprints.
public class BlueprintEngine {
    private let moduleGenerator: ModuleGenerator

    public init(moduleGenerator: ModuleGenerator = ModuleGenerator()) {
        self.moduleGenerator = moduleGenerator
    }

    /// Resolves and executes a blueprint for a given module name.
    public func executeBlueprint(
        name blueprintName: String,
        moduleName: String,
        config: SwiftBlockConfig,
        templatePath: String = "/usr/local/share/swiftblock/Blocks/Modules",
        projectPath: String = FileManager.default.currentDirectoryPath,
        isDryRun: Bool = false
    ) throws -> BlueprintExecutionResult {
        let normalizedName = blueprintName.lowercased()
        guard let blockNames = config.blueprints[normalizedName] else {
            throw BlueprintEngineError.blueprintNotFound(blueprintName)
        }

        var generatedBlocks: [ModuleType] = []

        for blockName in blockNames {
            let type: ModuleType
            if let spec = BlockRegistry.spec(forCommand: blockName) {
                type = spec.type
            } else if let parsedType = ModuleType(rawValue: blockName.lowercased()) {
                type = parsedType
            } else {
                throw BlueprintEngineError.invalidBlockType(blockName)
            }

            let options = ModuleGeneratorOptions(
                type: type,
                moduleName: moduleName,
                projectRootPath: projectPath,
                modulesTemplatePath: templatePath,
                isDryRun: isDryRun
            )
            _ = try moduleGenerator.generateModule(options: options)
            generatedBlocks.append(type)
        }

        return BlueprintExecutionResult(
            blueprintName: normalizedName,
            moduleName: moduleName,
            generatedBlocks: generatedBlocks
        )
    }
}

public enum BlueprintEngineError: Error, LocalizedError, Equatable {
    case blueprintNotFound(String)
    case invalidBlockType(String)

    public var errorDescription: String? {
        switch self {
        case .blueprintNotFound(let name):
            return "Blueprint '\(name)' is not defined in .swiftblock config."
        case .invalidBlockType(let name):
            return "Block type '\(name)' specified in blueprint is invalid."
        }
    }
}
