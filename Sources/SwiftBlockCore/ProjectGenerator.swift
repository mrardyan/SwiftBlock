import Foundation

public struct ProjectGeneratorOptions {
    public var projectName: String
    public var bundlePrefix: String
    public var templatePath: String
    public var outputPath: String
    public var isDryRun: Bool
    public var customConfig: SwiftBlockConfig?

    public init(
        projectName: String,
        bundlePrefix: String = "com.example",
        templatePath: String = "/usr/local/share/swiftblock/Blocks/Projects/BaseProject-SwiftUI",
        outputPath: String? = nil,
        isDryRun: Bool = false,
        customConfig: SwiftBlockConfig? = nil
    ) {
        self.projectName = projectName
        self.bundlePrefix = bundlePrefix
        self.templatePath = templatePath
        self.outputPath = outputPath ?? "\(FileManager.default.currentDirectoryPath)/\(projectName)"
        self.isDryRun = isDryRun
        self.customConfig = customConfig
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

        if options.isDryRun {
            print("🔍 [DRY RUN] Would copy project block from: \(options.templatePath)")
            print("🔍 [DRY RUN] Would create project directory: \(options.outputPath)")
            print("🔍 [DRY RUN] Would replace placeholders for project: '\(options.projectName)' and bundle prefix: '\(options.bundlePrefix)'")
            return
        }

        do {
            try fileManager.copyItem(atPath: options.templatePath, toPath: options.outputPath)
            try replacePlaceholders(in: options.outputPath, projectName: options.projectName, bundlePrefix: options.bundlePrefix)
            try renamePaths(in: options.outputPath, projectName: options.projectName, bundlePrefix: options.bundlePrefix)

            if let customConfig = options.customConfig {
                let configFilePath = "\(options.outputPath)/.swiftblock"
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let configData = try encoder.encode(customConfig)
                try configData.write(to: URL(fileURLWithPath: configFilePath))
            }
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

        let allowedExtensions = ["swift", "xcodeproj", "pbxproj", "plist", "md", "yaml", "yml", "txt", "sh", "json"]
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
