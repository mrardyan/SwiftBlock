import Foundation

public class GitRepositoryInitializer {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func initializeRepository(at projectPath: String, config: SwiftBlockConfig, isVerbose: Bool = false) throws {
        guard config.gitInit else { return }

        let gitDir = "\(projectPath)/.git"
        if !fileManager.fileExists(atPath: gitDir) {
            if isVerbose {
                print("🔹 [Git] Initializing Git repository at \(projectPath)...")
            }
            try runProcess(executable: "/usr/bin/git", arguments: ["init"], currentDirectoryPath: projectPath)
        }

        // Ensure .gitignore exists
        let gitignorePath = "\(projectPath)/.gitignore"
        if !fileManager.fileExists(atPath: gitignorePath) {
            let content = """
.DS_Store
/*.xcodeproj
/*.xcworkspace
.build/
DerivedData/
.mise.local.toml
"""
            let trimmedContent = content.trimmingCharacters(in: .newlines) + "\n"
            try trimmedContent.write(toFile: gitignorePath, atomically: true, encoding: .utf8)
        }

        // Run pre-commit install if precommit guardrail is enabled and pre-commit executable is present
        if config.guardrails.precommit {
            let whichPreCommit = runProcessOutput(executable: "/usr/bin/which", arguments: ["pre-commit"])
            if !whichPreCommit.isEmpty {
                if isVerbose {
                    print("🔹 [Git] Installing pre-commit hooks...")
                }
                _ = try? runProcess(executable: whichPreCommit, arguments: ["install"], currentDirectoryPath: projectPath)
            }
        }
    }

    private func runProcess(executable: String, arguments: [String], currentDirectoryPath: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.currentDirectoryURL = URL(fileURLWithPath: currentDirectoryPath)

        try process.run()
        process.waitUntilExit()
    }

    private func runProcessOutput(executable: String, arguments: [String]) -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = pipe

        defer {
            try? pipe.fileHandleForReading.close()
        }

        try? process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
