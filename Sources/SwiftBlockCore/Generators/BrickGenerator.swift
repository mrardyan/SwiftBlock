import Foundation

public struct BrickGeneratorOptions {
    public var type: Brick
    public var name: String
    public var projectRootPath: String
    public var modulesTemplatePath: String
    public var isDryRun: Bool
    public var variables: [String: String]

    public init(
        type: Brick,
        name: String,
        projectRootPath: String = FileManager.default.currentDirectoryPath,
        modulesTemplatePath: String? = nil,
        isDryRun: Bool = false,
        variables: [String: String] = [:]
    ) {
        self.type = type
        self.name = name
        self.projectRootPath = projectRootPath
        if let templatePath = modulesTemplatePath, !templatePath.isEmpty {
            self.modulesTemplatePath = templatePath
        } else {
            let envRoot = ProcessInfo.processInfo.environment["SWIFTBLOCK_ROOT"]
            let envBricks = envRoot.map { "\($0)/Bricks" } ?? ""
            let localBricks = "\(FileManager.default.currentDirectoryPath)/Bricks"
            let shareBricks = "/usr/local/share/swiftblock/Bricks"

            if !envBricks.isEmpty && FileManager.default.fileExists(atPath: envBricks) {
                self.modulesTemplatePath = envBricks
            } else if FileManager.default.fileExists(atPath: localBricks) {
                self.modulesTemplatePath = localBricks
            } else if FileManager.default.fileExists(atPath: shareBricks) {
                self.modulesTemplatePath = shareBricks
            } else if let envRoot = envRoot, FileManager.default.fileExists(atPath: envRoot) {
                self.modulesTemplatePath = envRoot
            } else {
                let subFolder = "Bricks/\(type.category.rawValue.capitalized)"
                self.modulesTemplatePath = "/usr/local/share/swiftblock/\(subFolder)"
            }
        }
        self.isDryRun = isDryRun
        self.variables = variables
    }
}

public typealias ModuleGeneratorOptions = BrickGeneratorOptions

public enum BrickGeneratorError: Error, LocalizedError {
    case templateNotFound(String)
    case brickAlreadyExists(String)
    case moduleAlreadyExists(String)
    case baseplateMismatch(brickName: String, baseplates: [String], projectType: String)
    case generationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .templateNotFound(let path):
            return "Brick template not found at \(path)"
        case .brickAlreadyExists(let path), .moduleAlreadyExists(let path):
            return "Brick already exists at \(path)"
        case .baseplateMismatch(let brickName, let baseplates, let projectType):
            return "Brick '\(brickName)' only supports baseplate(s) [\(baseplates.joined(separator: ", "))] and cannot be snapped into a \(projectType) project."
        case .generationFailed(let message):
            return "Failed to generate brick: \(message)"
        }
    }
}

public typealias ModuleGeneratorError = BrickGeneratorError

public class BrickGenerator {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func generateModule(options: BrickGeneratorOptions) throws -> String {
        try generateBrick(options: options)
    }

    public func generateBrick(options: BrickGeneratorOptions) throws -> String {
        let config = try SwiftBlockConfig.load(from: options.projectRootPath)

        let discoveryEngine = BrickDiscoveryEngine(fileManager: fileManager)
        let resolvedTemplate = discoveryEngine.resolveBrickPath(named: options.type.rawValue, in: options.modulesTemplatePath)

        var templateTypeFolderPath: String
        if fileManager.fileExists(atPath: "\(options.modulesTemplatePath)/brick.yml") || fileManager.fileExists(atPath: "\(options.modulesTemplatePath)/block.json") {
            templateTypeFolderPath = options.modulesTemplatePath
        } else if let resolved = resolvedTemplate, (resolved.hasPrefix(options.modulesTemplatePath) || options.modulesTemplatePath.contains("Bricks") || options.modulesTemplatePath.contains("Blocks")) {
            templateTypeFolderPath = resolved
        } else {
            templateTypeFolderPath = "\(options.modulesTemplatePath)/\(options.type.rawValue.capitalized)"
            if !fileManager.fileExists(atPath: templateTypeFolderPath) {
                let lastComponent = (options.modulesTemplatePath as NSString).lastPathComponent.lowercased()
                if lastComponent == options.type.rawValue.lowercased() {
                    templateTypeFolderPath = options.modulesTemplatePath
                }
            }
        }

        guard fileManager.fileExists(atPath: templateTypeFolderPath) else {
            throw BrickGeneratorError.templateNotFound("\(options.modulesTemplatePath)/\(options.type.rawValue.capitalized)")
        }

        let manifest = BrickManifest.load(fromPath: templateTypeFolderPath)

        // Effective category: curated registry wins; otherwise derive from the manifest so that
        // unregistered bricks (e.g. via --template-path) get the correct classification.
        let effectiveCategory: Brick.Category
        if let curated = BrickRegistry.curatedSpec(for: options.type)?.category {
            effectiveCategory = curated
        } else if let manifest = manifest {
            effectiveCategory = BrickRegistry.category(for: manifest.category, defaultPath: manifest.defaultPath)
        } else {
            effectiveCategory = options.type.category
        }

        if let manifest = manifest, let baseplates = manifest.baseplates, !baseplates.isEmpty {
            let isVapor = config.generatorTool == .spm
            let allowed = baseplates.map { $0.lowercased() }
            let matches = isVapor ? allowed.contains("vapor") : allowed.contains("swiftui")
            if !matches {
                throw BrickGeneratorError.baseplateMismatch(
                    brickName: manifest.name,
                    baseplates: baseplates,
                    projectType: isVapor ? "Vapor (SPM)" : "SwiftUI (Tuist/XcodeGen)"
                )
            }
        }

        let resolvedPath = config.resolveOutputPath(
            for: options.type,
            moduleName: options.name,
            manifestDefaultPath: manifest?.defaultPath,
            category: effectiveCategory
        )

        let isSingleton = (manifest?.instantiation == .singleton) || effectiveCategory.isSingleton

        let destinationFolderPath: String
        if isSingleton {
            destinationFolderPath = "\(options.projectRootPath)/\(resolvedPath)"
        } else if resolvedPath.contains(options.name.lowercased()) || resolvedPath.contains(options.name) {
            destinationFolderPath = "\(options.projectRootPath)/\(resolvedPath)"
        } else {
            destinationFolderPath = "\(options.projectRootPath)/\(resolvedPath)/\(options.name)"
        }

        if !isSingleton && fileManager.fileExists(atPath: destinationFolderPath) {
            throw BrickGeneratorError.moduleAlreadyExists(destinationFolderPath)
        }

        if let manifest = manifest {
            try HooksEngine.executeHooks(
                manifest.preSnapHooks,
                variables: options.variables,
                projectName: config.projectName,
                moduleName: options.name,
                projectRootPath: options.projectRootPath,
                isDryRun: options.isDryRun
            )
        }

        if options.isDryRun {
            print("🔍 [DRY RUN] Would load module block from: \(templateTypeFolderPath)")
            print("🔍 [DRY RUN] Would generate \(options.type.rawValue) module '\(options.name)' at: \(destinationFolderPath)")
            return destinationFolderPath
        }

        try fileManager.createDirectory(atPath: destinationFolderPath, withIntermediateDirectories: true)

        do {
            try copyAndProcessModuleTemplates(
                from: templateTypeFolderPath,
                to: destinationFolderPath,
                moduleName: options.name,
                projectName: config.projectName,
                projectRootPath: options.projectRootPath,
                moduleType: options.type,
                variables: options.variables,
                config: config,
                manifest: manifest
            )

            let manifestGenerator = ProjectManifestGeneratorFactory.createGenerator(for: config.generatorTool)
            do {
                try manifestGenerator.addBrickDependency(
                    name: options.name,
                    type: options.type,
                    config: config,
                    projectPath: options.projectRootPath
                )
            } catch {
                print("⚠️ Could not register brick '\(options.name)' in project manifest: \(error.localizedDescription)")
            }

            if effectiveCategory == .feature {
                let targetWiringEngine = ProjectTargetWiringEngine(fileManager: fileManager)
                do {
                    try targetWiringEngine.wireFeatureTarget(
                        moduleName: options.name,
                        projectPath: options.projectRootPath,
                        config: config,
                        isDryRun: options.isDryRun
                    )
                } catch {
                    print("⚠️ Could not wire feature target for '\(options.name)': \(error.localizedDescription)")
                }
            }

            if let manifest = manifest {
                try CodeInjector.injectAll(
                    specs: manifest.injections,
                    variables: options.variables,
                    projectName: config.projectName,
                    moduleName: options.name,
                    projectRootPath: options.projectRootPath,
                    config: config,
                    isDryRun: options.isDryRun
                )

                try HooksEngine.executeHooks(
                    manifest.postSnapHooks,
                    variables: options.variables,
                    projectName: config.projectName,
                    moduleName: options.name,
                    projectRootPath: options.projectRootPath,
                    isDryRun: options.isDryRun
                )
            }

            return destinationFolderPath
        } catch {
            if fileManager.fileExists(atPath: destinationFolderPath) {
                try? fileManager.removeItem(atPath: destinationFolderPath)
            }
            throw error
        }
    }

    private func copyAndProcessModuleTemplates(
        from sourcePath: String,
        to targetPath: String,
        moduleName: String,
        projectName: String,
        projectRootPath: String,
        moduleType: Brick,
        variables: [String: String] = [:],
        config: SwiftBlockConfig? = nil,
        manifest: BrickManifest? = nil
    ) throws {
        let enumerator = fileManager.enumerator(atPath: sourcePath)

        while let item = enumerator?.nextObject() as? String {
            // NEVER copy template metadata (brick.yml, block.json) to output projects
            let fileName = (item as NSString).lastPathComponent
            if fileName == "block.json" || fileName == "brick.yml" || fileName == "brick.yaml" {
                continue
            }

            let itemSourcePath = "\(sourcePath)/\(item)"
            let itemRelativePath = TemplateRenderer.renderPath(
                pathTemplate: item,
                variables: variables,
                moduleName: moduleName,
                blockName: moduleType.rawValue,
                config: config
            )

            let itemTargetPath: String
            if itemRelativePath.hasSuffix("Tests.swift") {
                let testRoot = (config?.generatorTool == .spm)
                    ? "\(projectRootPath)/Tests/AppTests"
                    : "\(projectRootPath)/App/Tests"
                let isSingleton = (manifest?.instantiation == .singleton) || moduleType.category.isSingleton
                if isSingleton {
                    itemTargetPath = "\(testRoot)/Core/\(moduleType.rawValue.lowercased())/\(itemRelativePath)"
                } else {
                    itemTargetPath = "\(testRoot)/Features/\(moduleName.lowercased())/\(moduleType.rawValue.lowercased())/\(itemRelativePath)"
                }
            } else {
                itemTargetPath = "\(targetPath)/\(itemRelativePath)"
            }

            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: itemSourcePath, isDirectory: &isDir) {
                if isDir.boolValue {
                    try fileManager.createDirectory(atPath: itemTargetPath, withIntermediateDirectories: true)
                } else {
                    let parentDir = (itemTargetPath as NSString).deletingLastPathComponent
                    if !fileManager.fileExists(atPath: parentDir) {
                        try fileManager.createDirectory(atPath: parentDir, withIntermediateDirectories: true)
                    }

                    // Text files are processed with template rendering; binary files copied raw
                    if let content = try? String(contentsOfFile: itemSourcePath, encoding: .utf8) {
                        var processed = TemplateRenderer.render(
                            template: content,
                            variables: variables,
                            config: config,
                            moduleName: moduleName,
                            projectName: projectName
                        )
                        if itemRelativePath.hasSuffix("Tests.swift") {
                            let framework = config?.testFramework ?? .swiftTesting
                            processed = TestFrameworkConverter.convert(processed, target: framework)
                        }
                        let trimmedProcessed = processed.trimmingCharacters(in: .newlines) + "\n"
                        try trimmedProcessed.write(toFile: itemTargetPath, atomically: true, encoding: .utf8)
                    } else {
                        if fileManager.fileExists(atPath: itemTargetPath) {
                            try? fileManager.removeItem(atPath: itemTargetPath)
                        }
                        try fileManager.copyItem(atPath: itemSourcePath, toPath: itemTargetPath)
                    }
                }
            }
        }
    }
}

public typealias ModuleGenerator = BrickGenerator
