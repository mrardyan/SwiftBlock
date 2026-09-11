import Foundation

public struct BoxValidationReport {
    public let isValid: Bool
    public let errors: [String]
    public let warnings: [String]
    public let manifest: BrickManifest?

    public init(isValid: Bool, errors: [String], warnings: [String], manifest: BrickManifest?) {
        self.isValid = isValid
        self.errors = errors
        self.warnings = warnings
        self.manifest = manifest
    }
}

public struct BoxPublishResult {
    public let boxName: String
    public let tag: String
    public let remote: String
    public let isDryRun: Bool

    public init(boxName: String, tag: String, remote: String, isDryRun: Bool) {
        self.boxName = boxName
        self.tag = tag
        self.remote = remote
        self.isDryRun = isDryRun
    }
}

public enum BoxPublisherError: Error, LocalizedError {
    case validationFailed(errors: [String])
    case notGitRepository(String)
    case publishFailed(String)

    public var errorDescription: String? {
        switch self {
        case .validationFailed(let errors):
            return "Box validation failed:\n" + errors.map { "  - \($0)" }.joined(separator: "\n")
        case .notGitRepository(let path):
            return "Directory at '\(path)' is not a valid Git repository."
        case .publishFailed(let message):
            return "Failed to publish box: \(message)"
        }
    }
}

public class BoxPublisher {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func validateBox(at path: String) throws -> BoxValidationReport {
        let absolutePath = (path as NSString).isAbsolutePath
            ? (path as NSString).standardizingPath
            : ("\(fileManager.currentDirectoryPath)/\(path)" as NSString).standardizingPath

        var errors: [String] = []
        var warnings: [String] = []

        guard fileManager.fileExists(atPath: absolutePath) else {
            return BoxValidationReport(isValid: false, errors: ["Path '\(absolutePath)' does not exist."], warnings: [], manifest: nil)
        }

        let ymlPath = "\(absolutePath)/brick.yml"
        let yamlPath = "\(absolutePath)/brick.yaml"
        let jsonPath = "\(absolutePath)/block.json"

        let hasManifestFile = fileManager.fileExists(atPath: ymlPath) ||
                              fileManager.fileExists(atPath: yamlPath) ||
                              fileManager.fileExists(atPath: jsonPath)

        guard hasManifestFile else {
            return BoxValidationReport(isValid: false, errors: ["No valid brick.yml, brick.yaml, or block.json found in '\(absolutePath)'."], warnings: [], manifest: nil)
        }

        let manifest = BrickManifest.load(fromPath: absolutePath)
        guard let manifest = manifest else {
            return BoxValidationReport(isValid: false, errors: ["Failed to parse brick manifest in '\(absolutePath)'."], warnings: [], manifest: nil)
        }

        if manifest.name.trimmingCharacters(in: .whitespaces).isEmpty {
            errors.append("Brick manifest 'name' field cannot be empty.")
        }

        if manifest.description.trimmingCharacters(in: .whitespaces).isEmpty {
            warnings.append("Brick manifest 'description' field is empty.")
        }

        // Verify template file existences if injections are present
        for injection in manifest.injections {
            if injection.target.trimmingCharacters(in: .whitespaces).isEmpty {
                errors.append("Injection spec contains empty 'target' field.")
            }
            if injection.content.trimmingCharacters(in: .whitespaces).isEmpty {
                warnings.append("Injection spec for '\(injection.target)' has empty content snippet.")
            }
        }

        let isValid = errors.isEmpty
        return BoxValidationReport(isValid: isValid, errors: errors, warnings: warnings, manifest: manifest)
    }

    public func publishBox(
        at path: String = FileManager.default.currentDirectoryPath,
        tag: String? = nil,
        remote: String = "origin",
        isDryRun: Bool = false
    ) throws -> BoxPublishResult {
        let absolutePath = (path as NSString).isAbsolutePath
            ? (path as NSString).standardizingPath
            : ("\(fileManager.currentDirectoryPath)/\(path)" as NSString).standardizingPath

        let report = try validateBox(at: absolutePath)
        guard report.isValid, let manifest = report.manifest else {
            throw BoxPublisherError.validationFailed(errors: report.errors)
        }

        let gitDir = "\(absolutePath)/.git"
        guard fileManager.fileExists(atPath: gitDir) else {
            throw BoxPublisherError.notGitRepository(absolutePath)
        }

        let versionTag: String
        if let customTag = tag, !customTag.isEmpty {
            versionTag = customTag.hasPrefix("v") ? customTag : "v\(customTag)"
        } else {
            versionTag = "v1.0.0"
        }

        if isDryRun {
            print("🔍 [DRY RUN] Would validate box '\(manifest.name)' at: \(absolutePath)")
            print("🔍 [DRY RUN] Would create git tag '\(versionTag)' and push to remote '\(remote)'")
            return BoxPublishResult(boxName: manifest.name, tag: versionTag, remote: remote, isDryRun: true)
        }

        let gitBinary = findGitExecutable()

        // 1. Stage changes
        _ = runProcess(executable: gitBinary, arguments: ["add", "."], currentDirectoryPath: absolutePath)

        // 2. Commit changes (if any)
        _ = runProcess(executable: gitBinary, arguments: ["commit", "-m", "publish: release \(versionTag) for \(manifest.name)"], currentDirectoryPath: absolutePath)

        // 3. Create tag
        let tagExitCode = runProcess(executable: gitBinary, arguments: ["tag", "-a", versionTag, "-m", "Release \(versionTag)"], currentDirectoryPath: absolutePath)
        if tagExitCode != 0 {
            // If tag already exists, force update
            _ = runProcess(executable: gitBinary, arguments: ["tag", "-f", versionTag], currentDirectoryPath: absolutePath)
        }

        // 4. Push tag and branch to remote
        let pushExitCode = runProcess(executable: gitBinary, arguments: ["push", remote, versionTag], currentDirectoryPath: absolutePath)
        if pushExitCode != 0 {
            print("⚠️ Note: 'git push' exit code was non-zero (remote '\(remote)' might not be configured or unreachable).")
        }

        return BoxPublishResult(boxName: manifest.name, tag: versionTag, remote: remote, isDryRun: false)
    }

    private func findGitExecutable() -> String {
        if fileManager.fileExists(atPath: "/usr/bin/git") { return "/usr/bin/git" }
        if fileManager.fileExists(atPath: "/usr/local/bin/git") { return "/usr/local/bin/git" }
        if fileManager.fileExists(atPath: "/opt/homebrew/bin/git") { return "/opt/homebrew/bin/git" }
        return "git"
    }

    private func runProcess(executable: String, arguments: [String], currentDirectoryPath: String) -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.currentDirectoryURL = URL(fileURLWithPath: currentDirectoryPath)
        try? process.run()
        process.waitUntilExit()
        return process.terminationStatus
    }
}
