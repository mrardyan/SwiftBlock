import Foundation

public struct ModuleGeneratorOptions {
    public var type: ModuleType
    public var moduleName: String
    public var projectRootPath: String
    public var modulesTemplatePath: String
    public var isDryRun: Bool

    public init(
        type: ModuleType,
        moduleName: String,
        projectRootPath: String = FileManager.default.currentDirectoryPath,
        modulesTemplatePath: String? = nil,
        isDryRun: Bool = false
    ) {
        self.type = type
        self.moduleName = moduleName
        self.projectRootPath = projectRootPath
        if let templatePath = modulesTemplatePath, !templatePath.isEmpty {
            self.modulesTemplatePath = templatePath
        } else {
            let subFolder = type.category == .core ? "Core" : "Modules"
            self.modulesTemplatePath = "/usr/local/share/swiftblock/Blocks/\(subFolder)"
        }
        self.isDryRun = isDryRun
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
        if resolvedPath.contains(options.moduleName.lowercased()) || resolvedPath.contains(options.moduleName) {
            destinationFolderPath = "\(options.projectRootPath)/\(resolvedPath)"
        } else {
            destinationFolderPath = "\(options.projectRootPath)/\(resolvedPath)/\(options.moduleName)"
        }

        var templateTypeFolderPath = "\(options.modulesTemplatePath)/\(options.type.rawValue.capitalized)"
        if !fileManager.fileExists(atPath: templateTypeFolderPath) {
            let lastComponent = (options.modulesTemplatePath as NSString).lastPathComponent.lowercased()
            if lastComponent == options.type.rawValue.lowercased() {
                templateTypeFolderPath = options.modulesTemplatePath
            }
        }

        guard fileManager.fileExists(atPath: templateTypeFolderPath) else {
            throw ModuleGeneratorError.templateNotFound("\(options.modulesTemplatePath)/\(options.type.rawValue.capitalized)")
        }

        if fileManager.fileExists(atPath: destinationFolderPath) {
            throw ModuleGeneratorError.moduleAlreadyExists(destinationFolderPath)
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
                projectName: config.projectName
            )
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
        projectName: String
    ) throws {
        let enumerator = fileManager.enumerator(atPath: sourcePath)

        while let item = enumerator?.nextObject() as? String {
            // NEVER copy template metadata (block.json) to output projects
            if (item as NSString).lastPathComponent == "block.json" {
                continue
            }

            let itemSourcePath = "\(sourcePath)/\(item)"
            let itemRelativePath = item
                .replacingOccurrences(of: "__MODULE_NAME__", with: moduleName)
                .replacingOccurrences(of: "__PROJECT_NAME__", with: projectName)
            let itemTargetPath = "\(targetPath)/\(itemRelativePath)"

            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: itemSourcePath, isDirectory: &isDir) {
                if isDir.boolValue {
                    try fileManager.createDirectory(atPath: itemTargetPath, withIntermediateDirectories: true)
                } else {
                    let parentDir = (itemTargetPath as NSString).deletingLastPathComponent
                    if !fileManager.fileExists(atPath: parentDir) {
                        try fileManager.createDirectory(atPath: parentDir, withIntermediateDirectories: true)
                    }

                    // Text files are processed with placeholder replacement; binary files copied raw
                    if let content = try? String(contentsOfFile: itemSourcePath, encoding: .utf8) {
                        var processed = content.replacingOccurrences(of: "__MODULE_NAME__", with: moduleName)
                        processed = processed.replacingOccurrences(of: "__PROJECT_NAME__", with: projectName)
                        try processed.write(toFile: itemTargetPath, atomically: true, encoding: .utf8)
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
