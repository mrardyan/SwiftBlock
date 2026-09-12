import Foundation

public struct KitExecutionResult {
    public let kitName: String
    public let moduleName: String
    public let generatedBricks: [Brick]

    public init(kitName: String, moduleName: String, generatedBricks: [Brick]) {
        self.kitName = kitName
        self.moduleName = moduleName
        self.generatedBricks = generatedBricks
    }
}

/// Execution engine for processing multi-brick composition kits.
public class KitEngine {
    private let brickGenerator: BrickGenerator

    public init(brickGenerator: BrickGenerator = BrickGenerator()) {
        self.brickGenerator = brickGenerator
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

        var generatedBricks: [Brick] = []

        for brickName in brickNames {
            let type: Brick
            if let spec = BrickRegistry.spec(forCommand: brickName) {
                type = spec.type
            } else {
                type = Brick(rawValue: brickName.lowercased())
            }

            let options = BrickGeneratorOptions(
                type: type,
                name: moduleName,
                projectRootPath: projectPath,
                modulesTemplatePath: templatePath,
                isDryRun: isDryRun
            )
            _ = try brickGenerator.generateBrick(options: options)
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
