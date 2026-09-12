import Foundation

public struct ProjectGeneratorOptions {
    public var projectName: String
    public var bundlePrefix: String
    public var templatePath: String
    public var outputPath: String
    public var isDryRun: Bool
    public var isVerbose: Bool
    public var customConfig: SwiftBlockConfig?
    public var baseplateName: String

    public init(
        projectName: String,
        bundlePrefix: String = "com.company",
        templatePath: String? = nil,
        outputPath: String? = nil,
        isDryRun: Bool = false,
        isVerbose: Bool = false,
        customConfig: SwiftBlockConfig? = nil,
        baseplateName: String = "swiftui"
    ) {
        self.projectName = projectName
        self.bundlePrefix = bundlePrefix
        self.baseplateName = baseplateName
        
        let folderName = baseplateName.lowercased().contains("vapor") ? "Vapor" : "SwiftUI"
        let defaultShare = "/usr/local/share/swiftblock/Baseplates/\(folderName)"
        let localDir = "\(FileManager.default.currentDirectoryPath)/Baseplates/\(folderName)"
        let fallbackOld = "/usr/local/share/swiftblock/Blocks/Projects/BaseProject-SwiftUI"
        
        if let custom = templatePath, !custom.isEmpty {
            self.templatePath = custom
        } else if FileManager.default.fileExists(atPath: localDir) {
            self.templatePath = localDir
        } else if FileManager.default.fileExists(atPath: defaultShare) {
            self.templatePath = defaultShare
        } else {
            self.templatePath = fallbackOld
        }
        
        self.outputPath = outputPath ?? "\(FileManager.default.currentDirectoryPath)/\(projectName)"
        self.isDryRun = isDryRun
        self.isVerbose = isVerbose
        self.customConfig = customConfig
    }
}

public enum ProjectGeneratorError: Error, LocalizedError, Equatable {
    case templateNotFound(String)
    case destinationAlreadyExists(String)
    case generationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .templateNotFound(let path):
            return "Template not found at \(path)"
        case .destinationAlreadyExists(let path):
            return "Directory already exists at \(path). Please specify a different project name or remove the existing folder."
        case .generationFailed(let message):
            return "Failed to generate project: \(message)"
        }
    }
}

public class ProjectGenerator {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func generateProject(options: ProjectGeneratorOptions) throws {
        guard fileManager.fileExists(atPath: options.templatePath) else {
            throw ProjectGeneratorError.templateNotFound(options.templatePath)
        }

        if fileManager.fileExists(atPath: options.outputPath) {
            throw ProjectGeneratorError.destinationAlreadyExists(options.outputPath)
        }

        if options.isDryRun {
            print("🔍 [DRY RUN] Would copy project block from: \(options.templatePath)")
            print("🔍 [DRY RUN] Would create project directory: \(options.outputPath)")
            print("🔍 [DRY RUN] Would replace placeholders for project: '\(options.projectName)' and bundle prefix: '\(options.bundlePrefix)'")
            return
        }

        var didCreateDestination = false

        do {
            if options.isVerbose {
                print("🔹 [Assembly] Copying base template from \(options.templatePath) to \(options.outputPath)...")
            }
            try fileManager.copyItem(atPath: options.templatePath, toPath: options.outputPath)
            didCreateDestination = true

            try replacePlaceholders(in: options.outputPath, projectName: options.projectName, bundlePrefix: options.bundlePrefix)
            try renamePaths(in: options.outputPath, projectName: options.projectName, bundlePrefix: options.bundlePrefix)

            // Load/Write SwiftBlockConfig
            let config = options.customConfig ?? SwiftBlockConfig(projectName: options.projectName, bundlePrefix: options.bundlePrefix)
            try config.save(to: options.outputPath)

            // 1. Generate Local SPM Packages if selected
            let packageGen = LocalPackageGenerator(fileManager: fileManager)
            if config.packaging.core == "spm" {
                if options.isVerbose { print("🔹 [Assembly] Generating Core local SPM package...") }
                try packageGen.generateCorePackage(in: options.outputPath, config: config)
            }

            // 1.5 Generate Selected Core Blocks
            if !config.coreBlocks.isEmpty {
                if options.isVerbose { print("🔹 [Assembly] Assembling selected Core Foundation modules...") }
                let moduleGen = BrickGenerator(fileManager: fileManager)
                for type in config.coreBlocks {
                    let defaultName: String
                    switch type {
                    case .storage: defaultName = "AppStorage"
                    case .network: defaultName = "NetworkClient"
                    case .logger: defaultName = "AppLogger"
                    case .config: defaultName = "AppConfig"
                    case .auth, .vaporauth: defaultName = "UserAuth"
                    case .analytics: defaultName = "AppAnalytics"
                    case .featureflag: defaultName = "FeatureFlags"
                    default: defaultName = type.rawValue.capitalized
                    }
                    let moduleOptions = BrickGeneratorOptions(
                        type: type,
                        name: defaultName,
                        projectRootPath: options.outputPath
                    )
                    do {
                        _ = try moduleGen.generateModule(options: moduleOptions)
                    } catch {
                        print("⚠️ [Assembly] Failed to generate core block '\(type.rawValue)': \(error)")
                    }
                }
            }

            // 2. Generate Build Manifest (Tuist / XcodeGen)
            if options.isVerbose { print("🔹 [Assembly] Generating build manifest for \(config.generatorTool.rawValue)...") }
            let manifestGen = ProjectManifestGeneratorFactory.createGenerator(for: config.generatorTool)
            try manifestGen.generateManifest(config: config, projectPath: options.outputPath)

            // 3. Generate Environment Files (Makefile, .mise.toml, Scripts/setup.sh, .xcconfig)
            if options.isVerbose { print("🔹 [Assembly] Generating environment setup files...") }
            let envGen = EnvironmentSetupGenerator(fileManager: fileManager)
            try envGen.generateSetupFiles(in: options.outputPath, config: config)

            let envConfigGen = EnvironmentConfigGenerator(fileManager: fileManager)
            try envConfigGen.generateConfigs(in: options.outputPath, config: config)

            // 4. Inject Guardrails (.swiftlint.yml, .swiftformat, .pre-commit-config.yaml, etc.)
            if options.isVerbose { print("🔹 [Assembly] Injecting guardrail configuration files...") }
            let guardrailGen = GuardrailsGenerator(fileManager: fileManager)
            try guardrailGen.generateGuardrails(in: options.outputPath, config: config)

            // 5. Generate CI/CD Pipeline Workflow Files
            if config.cicd.provider != .none {
                if options.isVerbose { print("🔹 [Assembly] Generating CI/CD pipeline for \(config.cicd.provider.rawValue)...") }
                let cicdGen = CICDManifestGenerator(fileManager: fileManager)
                try cicdGen.generateCICDPipeline(in: options.outputPath, config: config)
            }

            // 6. Initialize Git Repository
            if config.gitInit {
                let gitGen = GitRepositoryInitializer(fileManager: fileManager)
                try gitGen.initializeRepository(at: options.outputPath, config: config, isVerbose: options.isVerbose)
            }

            // 7. Setup IDE Tasks & Shortcuts (.vscode/tasks.json & Makefile)
            let ideGen = IDEConfigGenerator(fileManager: fileManager)
            try ideGen.setupAll(projectPath: options.outputPath, config: config)
        } catch {
            // Clean up partially copied project folder ONLY if created during generation
            if didCreateDestination && fileManager.fileExists(atPath: options.outputPath) {
                try? fileManager.removeItem(atPath: options.outputPath)
            }
            throw error
        }
    }

    public func replacePlaceholders(in folderPath: String, projectName: String, bundlePrefix: String) throws {
        let enumerator = fileManager.enumerator(atPath: folderPath)

        let allowedExtensions = ["swift", "xcodeproj", "pbxproj", "plist", "md", "yaml", "yml", "txt", "sh", "json", "toml"]
        let allowedExactFilenames = [".swiftformat", ".gitignore", ".editorconfig", "Makefile", ".swiftblock", "Package.swift", "Dockerfile", "docker-compose.yml", ".mise.toml"]

        while let file = enumerator?.nextObject() as? String {
            let filePath = "\(folderPath)/\(file)"
            var isDir: ObjCBool = false

            if fileManager.fileExists(atPath: filePath, isDirectory: &isDir), !isDir.boolValue {
                let fileExtension = URL(fileURLWithPath: filePath).pathExtension
                let filename = URL(fileURLWithPath: filePath).lastPathComponent

                guard allowedExtensions.contains(fileExtension) || allowedExactFilenames.contains(filename) else {
                    continue
                }

                var content = try String(contentsOfFile: filePath, encoding: .utf8)
                content = content.replacingOccurrences(of: "__PROJECT_NAME__", with: projectName)
                content = content.replacingOccurrences(of: "__BUNDLE_PREFIX__", with: bundlePrefix)
                let trimmedContent = content.trimmingCharacters(in: .newlines) + "\n"
                try trimmedContent.write(toFile: filePath, atomically: true, encoding: .utf8)
            }
        }
    }

    public func renamePaths(in folderPath: String, projectName: String, bundlePrefix: String) throws {
        let rootURL = URL(fileURLWithPath: folderPath)
        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        var itemsToRename: [URL] = []

        for case let fileURL as URL in enumerator {
            let name = fileURL.lastPathComponent
            if name.contains("__PROJECT_NAME__") || name.contains("__BUNDLE_PREFIX__") {
                itemsToRename.append(fileURL)
            }
        }

        itemsToRename.sort { $0.path.count > $1.path.count }

        for url in itemsToRename {
            let oldName = url.lastPathComponent
            let newName = oldName
                .replacingOccurrences(of: "__PROJECT_NAME__", with: projectName)
                .replacingOccurrences(of: "__BUNDLE_PREFIX__", with: bundlePrefix)

            let destinationURL = url.deletingLastPathComponent().appendingPathComponent(newName)
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.moveItem(at: url, to: destinationURL)
            }
        }
    }
}
