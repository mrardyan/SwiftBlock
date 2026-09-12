import Foundation

public struct RefactoringResult {
    public let oldName: String
    public let newName: String
    public let modifiedFiles: [String]
    public let renamedFiles: [String]
    public let isDryRun: Bool

    public init(oldName: String, newName: String, modifiedFiles: [String], renamedFiles: [String], isDryRun: Bool) {
        self.oldName = oldName
        self.newName = newName
        self.modifiedFiles = modifiedFiles
        self.renamedFiles = renamedFiles
        self.isDryRun = isDryRun
    }
}

public enum ProjectRefactoringError: Error, LocalizedError {
    case invalidProjectName(String)
    case configNotFound(String)
    case refactoringFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidProjectName(let name):
            return "Invalid project name '\(name)'. Project name must start with a letter and contain only alphanumeric characters."
        case .configNotFound(let path):
            return "No valid .swiftblock/config.yml found at '\(path)'."
        case .refactoringFailed(let message):
            return "Project refactoring failed: \(message)"
        }
    }
}

public class ProjectRefactoringEngine {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func renameProject(
        projectPath: String = FileManager.default.currentDirectoryPath,
        newName: String,
        isDryRun: Bool = false
    ) throws -> RefactoringResult {
        let absolutePath = (projectPath as NSString).isAbsolutePath
            ? (projectPath as NSString).standardizingPath
            : ("\(fileManager.currentDirectoryPath)/\(projectPath)" as NSString).standardizingPath

        let sanitizedNewName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidProjectName(sanitizedNewName) else {
            throw ProjectRefactoringError.invalidProjectName(newName)
        }

        let configPath = "\(absolutePath)/.swiftblock/config.yml"
        guard fileManager.fileExists(atPath: configPath),
              var config = try? SwiftBlockConfig.load(from: absolutePath) else {
            throw ProjectRefactoringError.configNotFound(absolutePath)
        }

        let oldName = config.projectName
        if oldName == sanitizedNewName {
            return RefactoringResult(oldName: oldName, newName: sanitizedNewName, modifiedFiles: [], renamedFiles: [], isDryRun: isDryRun)
        }

        var modifiedFiles: [String] = []
        var renamedFiles: [String] = []

        if isDryRun {
            print("🔍 [DRY RUN] Would rename project '\(oldName)' -> '\(sanitizedNewName)' at: \(absolutePath)")
            return RefactoringResult(oldName: oldName, newName: sanitizedNewName, modifiedFiles: ["config.yml"], renamedFiles: [], isDryRun: true)
        }

        // 1. Update .swiftblock/config.yml
        config.projectName = sanitizedNewName
        try config.save(to: absolutePath)
        modifiedFiles.append(".swiftblock/config.yml")

        // 2. Refactor Project Manifest (Project.swift or project.yml)
        let tuistManifest = "\(absolutePath)/Project.swift"
        let xcodeGenManifest = "\(absolutePath)/project.yml"

        if fileManager.fileExists(atPath: tuistManifest) {
            if var content = try? String(contentsOfFile: tuistManifest, encoding: .utf8) {
                content = content.replacingOccurrences(of: oldName, with: sanitizedNewName)
                try content.write(toFile: tuistManifest, atomically: true, encoding: .utf8)
                modifiedFiles.append("Project.swift")
            }
        }

        if fileManager.fileExists(atPath: xcodeGenManifest) {
            if var content = try? String(contentsOfFile: xcodeGenManifest, encoding: .utf8) {
                content = content.replacingOccurrences(of: oldName, with: sanitizedNewName)
                try content.write(toFile: xcodeGenManifest, atomically: true, encoding: .utf8)
                modifiedFiles.append("project.yml")
            }
        }

        // 3. Dynamically rename files and directories containing oldName
        if let enumerator = fileManager.enumerator(atPath: absolutePath) {
            var itemsToRename: [String] = []
            while let relativePath = enumerator.nextObject() as? String {
                if relativePath.hasPrefix(".build") || relativePath.hasPrefix(".git") { continue }
                let filename = (relativePath as NSString).lastPathComponent
                if filename.contains(oldName) {
                    itemsToRename.append(relativePath)
                }
            }
            itemsToRename.sort { $0.count > $1.count }
            for relPath in itemsToRename {
                let fullPath = "\(absolutePath)/\(relPath)"
                let dirPath = (fullPath as NSString).deletingLastPathComponent
                let oldFilename = (fullPath as NSString).lastPathComponent
                let newFilename = oldFilename.replacingOccurrences(of: oldName, with: sanitizedNewName)
                let destinationPath = "\(dirPath)/\(newFilename)"

                if fileManager.fileExists(atPath: fullPath) {
                    if fileManager.fileExists(atPath: destinationPath) {
                        try? fileManager.removeItem(atPath: destinationPath)
                    }
                    try fileManager.moveItem(atPath: fullPath, toPath: destinationPath)
                    let relativeDest = destinationPath.replacingOccurrences(of: "\(absolutePath)/", with: "")
                    renamedFiles.append(relativeDest)
                }
            }
        }

        // 4. Refactor Swift source and test files across App and Packages
        if let enumerator = fileManager.enumerator(atPath: absolutePath) {
            while let file = enumerator.nextObject() as? String {
                if file.hasPrefix(".build/") || file.hasPrefix(".git/") { continue }
                if file.hasSuffix(".swift") {
                    let fullPath = "\(absolutePath)/\(file)"
                    if var content = try? String(contentsOfFile: fullPath, encoding: .utf8) {
                        if content.contains(oldName) {
                            content = content.replacingOccurrences(of: "struct \(oldName)App", with: "struct \(sanitizedNewName)App")
                            content = content.replacingOccurrences(of: "@testable import \(oldName)", with: "@testable import \(sanitizedNewName)")
                            content = content.replacingOccurrences(of: "\(oldName)Tests", with: "\(sanitizedNewName)Tests")
                            content = content.replacingOccurrences(of: oldName, with: sanitizedNewName)
                            try content.write(toFile: fullPath, atomically: true, encoding: .utf8)
                            modifiedFiles.append(file)
                        }
                    }
                }
            }
        }

        // 5. Refactor Makefile and CI/CD pipelines
        let makefilePath = "\(absolutePath)/Makefile"
        if fileManager.fileExists(atPath: makefilePath),
           var content = try? String(contentsOfFile: makefilePath, encoding: .utf8) {
            if content.contains(oldName) {
                content = content.replacingOccurrences(of: oldName, with: sanitizedNewName)
                try content.write(toFile: makefilePath, atomically: true, encoding: .utf8)
                modifiedFiles.append("Makefile")
            }
        }

        let githubWorkflow = "\(absolutePath)/.github/workflows/ci.yml"
        if fileManager.fileExists(atPath: githubWorkflow),
           var content = try? String(contentsOfFile: githubWorkflow, encoding: .utf8) {
            if content.contains(oldName) {
                content = content.replacingOccurrences(of: oldName, with: sanitizedNewName)
                try content.write(toFile: githubWorkflow, atomically: true, encoding: .utf8)
                modifiedFiles.append(".github/workflows/ci.yml")
            }
        }

        return RefactoringResult(
            oldName: oldName,
            newName: sanitizedNewName,
            modifiedFiles: Array(Set(modifiedFiles)),
            renamedFiles: renamedFiles,
            isDryRun: false
        )
    }

    private func isValidProjectName(_ name: String) -> Bool {
        guard !name.isEmpty else { return false }
        let regex = "^[A-Za-z][A-Za-z0-9_]*$"
        return name.range(of: regex, options: .regularExpression) != nil
    }
}
