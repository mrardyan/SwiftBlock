import Foundation

public struct KitBrickSpec: Codable, Equatable {
    public var name: String
    public var flavors: [String: String]
    public var optionalDeps: [String]
    public var variables: [String: String]

    public init(
        name: String,
        flavors: [String: String] = [:],
        optionalDeps: [String] = [],
        variables: [String: String] = [:]
    ) {
        self.name = name
        self.flavors = flavors
        self.optionalDeps = optionalDeps
        self.variables = variables
    }

    /// Parses entries like:
    /// - "scene"
    /// - "scene(stateStyle=combine)"
    /// - "repository(strategy=offline-first)[storage,logger]"
    /// - "usecase[exponentialbackoff]"
    public static func parse(_ entry: String) -> KitBrickSpec {
        var clean = entry.trimmingCharacters(in: .whitespaces)
        var flavors: [String: String] = [:]
        var optionals: [String] = []
        let variables: [String: String] = [:]

        // Extract [optional1, optional2]
        if let optStart = clean.firstIndex(of: "["), let optEnd = clean.firstIndex(of: "]"), optStart < optEnd {
            let depsStr = clean[clean.index(after: optStart) ..< optEnd]
            optionals = depsStr.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            clean.removeSubrange(optStart ... optEnd)
            clean = clean.trimmingCharacters(in: .whitespaces)
        }

        // Extract (flavor1=val1, flavor2=val2)
        if let flavStart = clean.firstIndex(of: "("), let flavEnd = clean.firstIndex(of: ")"), flavStart < flavEnd {
            let flavStr = clean[clean.index(after: flavStart) ..< flavEnd]
            for pair in flavStr.split(separator: ",") {
                let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
                if parts.count == 2 {
                    let k = parts[0].trimmingCharacters(in: .whitespaces)
                    let v = parts[1].trimmingCharacters(in: .whitespaces)
                    flavors[k] = v
                }
            }
            clean.removeSubrange(flavStart ... flavEnd)
            clean = clean.trimmingCharacters(in: .whitespaces)
        }

        // Gracefully handle unclosed brackets by dropping the dangling suffix.
        if let strayOpen = clean.firstIndex(of: "[") {
            clean = String(clean[..<strayOpen]).trimmingCharacters(in: .whitespaces)
        }
        if let strayOpen = clean.firstIndex(of: "(") {
            clean = String(clean[..<strayOpen]).trimmingCharacters(in: .whitespaces)
        }

        return KitBrickSpec(name: clean, flavors: flavors, optionalDeps: optionals, variables: variables)
    }
}

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
        guard let brickEntries = config.kits[normalizedName] ?? SwiftBlockConfig.defaultKits[normalizedName] else {
            throw KitEngineError.kitNotFound(kitName)
        }

        let discoveryEngine = BrickDiscoveryEngine()
        let depResolver = DependencyResolverEngine(discoveryEngine: discoveryEngine)
        let baseDir = templatePath ?? FileManager.default.currentDirectoryPath

        var generatedBricks: [Brick] = []

        for entry in brickEntries {
            let spec = KitBrickSpec.parse(entry)
            let brickName = spec.name

            let type: Brick = if let curated = BrickRegistry.spec(forCommand: brickName) {
                curated.type
            } else {
                Brick(rawValue: brickName.lowercased())
            }

            var resolvedVars = spec.variables

            if let resolvedPath = discoveryEngine.resolveBrickPath(named: brickName, in: baseDir),
               let manifest = BrickManifest.load(fromPath: resolvedPath)
            {
                var selectedOpts = Set(spec.optionalDeps)

                // Apply flavors
                let flavorResult = FlavorResolver.resolve(
                    manifest: manifest,
                    selections: spec.flavors,
                    variables: resolvedVars,
                    selectedOptionalDeps: selectedOpts
                )
                resolvedVars = flavorResult.variables
                selectedOpts = flavorResult.selectedOptionalDeps

                // Resolve dependencies
                if let plan = try? depResolver.resolve(
                    targetBrickName: brickName,
                    baseTemplatePath: baseDir,
                    projectRootPath: projectPath,
                    selectedOptionalDeps: selectedOpts
                ) {
                    for node in plan.executionOrder where node.name.lowercased() != manifest.name.lowercased() {
                        let depType = Brick(rawValue: (node.templatePath as NSString).lastPathComponent)
                        let depInstanceName = node.manifest.instantiation == .generative ? moduleName : node.manifest.defaultInstanceName
                        let depOptions = BrickGeneratorOptions(
                            type: depType,
                            name: depInstanceName,
                            projectRootPath: projectPath,
                            modulesTemplatePath: node.templatePath,
                            isDryRun: isDryRun,
                            variables: resolvedVars
                        )
                        _ = try brickGenerator.generateBrick(options: depOptions)
                    }
                }

                let instanceName = manifest.instantiation == .generative ? moduleName : manifest.defaultInstanceName
                let targetTemplateDir = templatePath ?? resolvedPath
                let options = BrickGeneratorOptions(
                    type: type,
                    name: instanceName,
                    projectRootPath: projectPath,
                    modulesTemplatePath: targetTemplateDir,
                    isDryRun: isDryRun,
                    variables: resolvedVars
                )
                _ = try brickGenerator.generateBrick(options: options)
                generatedBricks.append(type)
            } else {
                let options = BrickGeneratorOptions(
                    type: type,
                    name: moduleName,
                    projectRootPath: projectPath,
                    modulesTemplatePath: templatePath ?? baseDir,
                    isDryRun: isDryRun,
                    variables: resolvedVars
                )
                _ = try brickGenerator.generateBrick(options: options)
                generatedBricks.append(type)
            }
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
            case let .kitNotFound(name):
                "Kit '\(name)' is not defined in .swiftblock/config.yml."
            case let .invalidBrickType(name):
                "Brick type '\(name)' specified in kit is invalid."
        }
    }
}
