import Foundation

public struct ModuleGeneratorOptions {
    public var type: ModuleType
    public var moduleName: String
    public var projectRootPath: String
    public var modulesTemplatePath: String

    public init(
        type: ModuleType,
        moduleName: String,
        projectRootPath: String = FileManager.default.currentDirectoryPath,
        modulesTemplatePath: String = "/usr/local/share/swiftblock/Templates/Modules"
    ) {
        self.type = type
        self.moduleName = moduleName
        self.projectRootPath = projectRootPath
        self.modulesTemplatePath = modulesTemplatePath
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
        let relativePath = config.paths.path(for: options.type)
        let destinationFolderPath = "\(options.projectRootPath)/\(relativePath)/\(options.moduleName)"
        
        let templateTypeFolderPath = "\(options.modulesTemplatePath)/\(options.type.rawValue.capitalized)"
        guard fileManager.fileExists(atPath: templateTypeFolderPath) else {
            throw ModuleGeneratorError.templateNotFound(templateTypeFolderPath)
        }

        if fileManager.fileExists(atPath: destinationFolderPath) {
            throw ModuleGeneratorError.moduleAlreadyExists(destinationFolderPath)
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
            let itemSourcePath = "\(sourcePath)/\(item)"
            let itemRelativePath = item.replacingOccurrences(of: "__MODULE_NAME__", with: moduleName)
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

                    var content = try String(contentsOfFile: itemSourcePath, encoding: .utf8)
                    content = content.replacingOccurrences(of: "__MODULE_NAME__", with: moduleName)
                    content = content.replacingOccurrences(of: "__PROJECT_NAME__", with: projectName)
                    try content.write(toFile: itemTargetPath, atomically: true, encoding: .utf8)
                }
            }
        }
    }
}
