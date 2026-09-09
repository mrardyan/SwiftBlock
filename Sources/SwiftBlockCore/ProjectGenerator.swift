import Foundation

public struct ProjectGeneratorOptions {
    public var projectName: String
    public var bundlePrefix: String
    public var templatePath: String
    public var outputPath: String

    public init(
        projectName: String,
        bundlePrefix: String = "io.ardyan",
        templatePath: String = "/usr/local/share/swiftblock/Templates/Projects/BaseProject-SwiftUI",
        outputPath: String? = nil
    ) {
        self.projectName = projectName
        self.bundlePrefix = bundlePrefix
        self.templatePath = templatePath
        self.outputPath = outputPath ?? "\(FileManager.default.currentDirectoryPath)/\(projectName)"
    }
}

public enum ProjectGeneratorError: Error, LocalizedError {
    case templateNotFound(String)
    case generationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .templateNotFound(let path):
            return "Template not found at \(path)"
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

        do {
            try fileManager.copyItem(atPath: options.templatePath, toPath: options.outputPath)
            try replacePlaceholders(in: options.outputPath, projectName: options.projectName, bundlePrefix: options.bundlePrefix)
        } catch {
            // Clean up partially copied project folder if generation failed
            if fileManager.fileExists(atPath: options.outputPath) {
                try? fileManager.removeItem(atPath: options.outputPath)
            }
            throw error
        }
    }

    public func replacePlaceholders(in folderPath: String, projectName: String, bundlePrefix: String) throws {
        let enumerator = fileManager.enumerator(atPath: folderPath)

        let allowedExtensions = ["swift", "xcodeproj", "pbxproj", "plist", "md", "yaml", "yml", "txt", "sh"]
        let allowedExactFilenames = [".swiftformat", ".gitignore", ".editorconfig", "Makefile", ".swiftblock"]

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
                try content.write(toFile: filePath, atomically: true, encoding: .utf8)
            }
        }
    }
}
