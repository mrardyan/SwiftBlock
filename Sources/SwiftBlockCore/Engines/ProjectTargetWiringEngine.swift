import Foundation

public enum TargetWiringError: Error, LocalizedError {
    case manifestNotFound(String)
    case wiringFailed(String)

    public var errorDescription: String? {
        switch self {
        case .manifestNotFound(let path):
            return "Project manifest not found at: \(path)"
        case .wiringFailed(let message):
            return "Target wiring failed: \(message)"
        }
    }
}

public class ProjectTargetWiringEngine {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    @discardableResult
    public func wireFeatureTarget(
        moduleName: String,
        projectPath: String = FileManager.default.currentDirectoryPath,
        config: SwiftBlockConfig? = nil,
        isDryRun: Bool = false
    ) throws -> Bool {
        let absolutePath = (projectPath as NSString).isAbsolutePath
            ? (projectPath as NSString).standardizingPath
            : ("\(fileManager.currentDirectoryPath)/\(projectPath)" as NSString).standardizingPath

        let sanitizedName = moduleName.capitalized

        let tuistManifest = "\(absolutePath)/Project.swift"
        let xcodeGenManifest = "\(absolutePath)/project.yml"

        var wired = false

        if fileManager.fileExists(atPath: tuistManifest) {
            wired = try wireTuistManifest(manifestPath: tuistManifest, moduleName: sanitizedName, isDryRun: isDryRun)
        } else if fileManager.fileExists(atPath: xcodeGenManifest) {
            wired = try wireXcodeGenManifest(manifestPath: xcodeGenManifest, moduleName: sanitizedName, isDryRun: isDryRun)
        }

        return wired
    }

    private func wireTuistManifest(manifestPath: String, moduleName: String, isDryRun: Bool) throws -> Bool {
        guard let content = try? String(contentsOfFile: manifestPath, encoding: .utf8) else {
            return false
        }

        // Avoid duplicate target wiring
        if content.contains("Target.target(name: \"\(moduleName)\"") || content.contains(".target(name: \"\(moduleName)\"") {
            print("ℹ️ Target '\(moduleName)' already wired in Project.swift")
            return false
        }

        if isDryRun {
            print("🔍 [DRY RUN] Would wire Tuist target '\(moduleName)' in Project.swift")
            return true
        }

        let targetDeclaration = """

        // MARK: - Auto-Wired Feature Target: \(moduleName)
        Target.target(
            name: "\(moduleName)",
            destinations: .iOS,
            product: .framework,
            bundleId: "$(PRODUCT_BUNDLE_IDENTIFIER).\(moduleName.lowercased())",
            infoPlist: .default,
            sources: ["App/Sources/Features/\(moduleName)/**"],
            dependencies: [
                .target(name: "Core")
            ]
        ),
"""

        var lines = content.components(separatedBy: "\n")
        if let targetsIndex = lines.firstIndex(where: { $0.contains("targets: [") }) {
            lines.insert(targetDeclaration, at: targetsIndex + 1)
            let newContent = lines.joined(separator: "\n")
            try newContent.write(toFile: manifestPath, atomically: true, encoding: .utf8)
            print("✔ Auto-wired Tuist target '\(moduleName)' into Project.swift")
            return true
        } else if let lastBraceIndex = lines.rIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "]" }) {
            lines.insert(targetDeclaration, at: lastBraceIndex)
            let newContent = lines.joined(separator: "\n")
            try newContent.write(toFile: manifestPath, atomically: true, encoding: .utf8)
            print("✔ Auto-wired Tuist target '\(moduleName)' into Project.swift")
            return true
        }

        return false
    }

    private func wireXcodeGenManifest(manifestPath: String, moduleName: String, isDryRun: Bool) throws -> Bool {
        guard let content = try? String(contentsOfFile: manifestPath, encoding: .utf8) else {
            return false
        }

        if content.contains("\(moduleName):") {
            print("ℹ️ Target '\(moduleName)' already wired in project.yml")
            return false
        }

        if isDryRun {
            print("🔍 [DRY RUN] Would wire XcodeGen target '\(moduleName)' in project.yml")
            return true
        }

        let targetDeclaration = """

  \(moduleName):
    type: framework
    platform: iOS
    sources:
      - path: App/Sources/Features/\(moduleName)
    dependencies:
      - target: Core
"""

        var lines = content.components(separatedBy: "\n")
        if let targetsIndex = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "targets:" }) {
            lines.insert(targetDeclaration, at: targetsIndex + 1)
            let newContent = lines.joined(separator: "\n")
            try newContent.write(toFile: manifestPath, atomically: true, encoding: .utf8)
            print("✔ Auto-wired XcodeGen target '\(moduleName)' into project.yml")
            return true
        }

        return false
    }
}

private extension Array {
    func rIndex(where predicate: (Element) -> Bool) -> Int? {
        for index in stride(from: count - 1, through: 0, by: -1) {
            if predicate(self[index]) {
                return index
            }
        }
        return nil
    }
}
