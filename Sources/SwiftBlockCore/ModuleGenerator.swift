import Foundation

public struct ModuleGeneratorOptions {
    public var type: ModuleType
    public var moduleName: String
    public var projectRootPath: String
    public var modulesTemplatePath: String
    public var isDryRun: Bool
    public var variables: [String: String]

    public init(
        type: ModuleType,
        moduleName: String,
        projectRootPath: String = FileManager.default.currentDirectoryPath,
        modulesTemplatePath: String? = nil,
        isDryRun: Bool = false,
        variables: [String: String] = [:]
    ) {
        self.type = type
        self.moduleName = moduleName
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
                let subFolder = type.category == .core ? "Bricks/Singletons" : "Bricks/Generatives/Architecture"
                self.modulesTemplatePath = "/usr/local/share/swiftblock/\(subFolder)"
            }
        }
        self.isDryRun = isDryRun
        self.variables = variables
    }
}

public enum ModuleGeneratorError: Error, LocalizedError {
    case templateNotFound(String)
    case moduleAlreadyExists(String)
    case generationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .templateNotFound(let path):
            return "Module template not found at \(path)"
        case .moduleAlreadyExists(let path):
            return "Module already exists at \(path)"
        case .generationFailed(let message):
            return "Failed to generate module: \(message)"
        }
    }
}

public class ModuleGenerator {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func generateModule(options: ModuleGeneratorOptions) throws -> String {
        let config = try SwiftBlockConfig.load(from: options.projectRootPath)
        let resolvedPath = config.resolveOutputPath(for: options.type, moduleName: options.moduleName)

        let destinationFolderPath: String
        if options.type.category == .core {
            destinationFolderPath = "\(options.projectRootPath)/\(resolvedPath)"
        } else if resolvedPath.contains(options.moduleName.lowercased()) || resolvedPath.contains(options.moduleName) {
            destinationFolderPath = "\(options.projectRootPath)/\(resolvedPath)"
        } else {
            destinationFolderPath = "\(options.projectRootPath)/\(resolvedPath)/\(options.moduleName)"
        }

        let discoveryEngine = BlockDiscoveryEngine(fileManager: fileManager)
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
            throw ModuleGeneratorError.templateNotFound("\(options.modulesTemplatePath)/\(options.type.rawValue.capitalized)")
        }

        if options.type.category != .core && fileManager.fileExists(atPath: destinationFolderPath) {
            throw ModuleGeneratorError.moduleAlreadyExists(destinationFolderPath)
        }

        let manifest = BrickManifest.load(fromPath: templateTypeFolderPath)
        if let manifest = manifest {
            try HooksEngine.executeHooks(
                manifest.preSnapHooks,
                variables: options.variables,
                projectName: config.projectName,
                moduleName: options.moduleName,
                projectRootPath: options.projectRootPath,
                isDryRun: options.isDryRun
            )
        }

        if options.isDryRun {
            print("🔍 [DRY RUN] Would load module block from: \(templateTypeFolderPath)")
            print("🔍 [DRY RUN] Would generate \(options.type.rawValue) module '\(options.moduleName)' at: \(destinationFolderPath)")
            return destinationFolderPath
        }

        try fileManager.createDirectory(atPath: destinationFolderPath, withIntermediateDirectories: true)

        do {
            try copyAndProcessModuleTemplates(
                from: templateTypeFolderPath,
                to: destinationFolderPath,
                moduleName: options.moduleName,
                projectName: config.projectName,
                projectRootPath: options.projectRootPath,
                moduleType: options.type,
                variables: options.variables,
                config: config
            )

            let manifestGenerator = ProjectManifestGeneratorFactory.createGenerator(for: config.generatorTool)
            try? manifestGenerator.addModuleDependency(
                moduleName: options.moduleName,
                type: options.type,
                config: config,
                projectPath: options.projectRootPath
            )

            if let manifest = manifest {
                try CodeInjector.injectAll(
                    specs: manifest.injections,
                    variables: options.variables,
                    projectName: config.projectName,
                    moduleName: options.moduleName,
                    projectRootPath: options.projectRootPath,
                    config: config,
                    isDryRun: options.isDryRun
                )

                try HooksEngine.executeHooks(
                    manifest.postSnapHooks,
                    variables: options.variables,
                    projectName: config.projectName,
                    moduleName: options.moduleName,
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
        moduleType: ModuleType,
        variables: [String: String] = [:],
        config: SwiftBlockConfig? = nil
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
                if moduleType.category == .core {
                    itemTargetPath = "\(projectRootPath)/App/Tests/Core/\(moduleType.rawValue.lowercased())/\(itemRelativePath)"
                } else {
                    itemTargetPath = "\(projectRootPath)/App/Tests/Features/\(moduleName.lowercased())/\(moduleType.rawValue.lowercased())/\(itemRelativePath)"
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
                        let processed = TemplateRenderer.render(
                            template: content,
                            variables: variables,
                            config: config,
                            moduleName: moduleName,
                            projectName: projectName
                        )
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
