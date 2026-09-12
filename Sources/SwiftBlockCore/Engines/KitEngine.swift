import Foundation

public struct KitExecutionResult {
    public let kitName: String
    public let moduleName: String
    public let generatedBricks: [ModuleType]

    public init(kitName: String, moduleName: String, generatedBricks: [ModuleType]) {
        self.kitName = kitName
        self.moduleName = moduleName
        self.generatedBricks = generatedBricks
    }
}

/// Execution engine for processing multi-brick composition kits.
public class KitEngine {
    private let moduleGenerator: ModuleGenerator

    public init(moduleGenerator: ModuleGenerator = ModuleGenerator()) {
        self.moduleGenerator = moduleGenerator
    }

    /// Resolves and executes a composition kit for a given module name.
    public func executeKit(
        name kitName: String,
        moduleName: String,
        config: SwiftBlockConfig,
        templatePath: String? = nil,
        projectPath: String = FileManager.default.currentDirectoryPath,
        isDryRun: Bool = false
    ) throws -> KitExecutionResult {
        let normalizedName = kitName.lowercased()
        guard let brickNames = config.kits[normalizedName] else {
            throw KitEngineError.kitNotFound(kitName)
        }

        var generatedBricks: [ModuleType] = []

        for brickName in brickNames {
            let type: ModuleType
            if let spec = BlockRegistry.spec(forCommand: brickName) {
                type = spec.type
            } else {
                type = ModuleType(rawValue: brickName.lowercased())
            }

            let options = ModuleGeneratorOptions(
                type: type,
                moduleName: moduleName,
                projectRootPath: projectPath,
                modulesTemplatePath: templatePath,
                isDryRun: isDryRun
            )
            _ = try moduleGenerator.generateModule(options: options)
            generatedBricks.append(type)
        }

        return KitExecutionResult(
            kitName: normalizedName,
            moduleName: moduleName,
            generatedBricks: generatedBricks
        )
    }
}

public enum KitEngineError: Error, LocalizedError, Equatable {
    case kitNotFound(String)
    case invalidBrickType(String)

    public var errorDescription: String? {
        switch self {
        case .kitNotFound(let name):
            return "Kit '\(name)' is not defined in .swiftblock/config.yml."
        case .invalidBrickType(let name):
            return "Brick type '\(name)' specified in kit is invalid."
        }
    }
}
