import Foundation

public struct ToolCheckResult {
    public let name: String
    public let isInstalled: Bool
    public let version: String?
}

public struct DependencyIssue {
    public let filePath: String
    public let message: String
}

public struct DiagnosticsReport {
    public let toolChecks: [ToolCheckResult]
    public let isProjectFolder: Bool
    public let configValid: Bool
    public let configMessage: String
    public let manifestFound: String?
    public let dependencyIssues: [DependencyIssue]
    public let peripheryStatus: String
}

public class DoctorEngine {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func checkTool(_ toolName: String) -> ToolCheckResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [toolName]

        let pipe = Pipe()
        process.standardOutput = pipe

        defer {
            try? pipe.fileHandleForReading.close()
        }

        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .newlines) ?? ""

            if process.terminationStatus == 0 && !path.isEmpty {
                let version = getToolVersion(toolName)
                return ToolCheckResult(name: toolName, isInstalled: true, version: version)
            }
        } catch {}

        return ToolCheckResult(name: toolName, isInstalled: false, version: nil)
    }

    private func getToolVersion(_ toolName: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "\(toolName) --version 2>/dev/null || \(toolName) version 2>/dev/null"]

        let pipe = Pipe()
        process.standardOutput = pipe

        defer {
            try? pipe.fileHandleForReading.close()
        }

        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            let versionStr = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let versionStr = versionStr, !versionStr.isEmpty, versionStr.count < 30 {
                return versionStr
            }
        } catch {}

        return nil
    }

    public func analyzeDependencyGraph(projectRootPath: String) -> [DependencyIssue] {
        var issues: [DependencyIssue] = []
        let sourcesPath = "\(projectRootPath)/App/Sources"

        guard fileManager.fileExists(atPath: sourcesPath),
              let enumerator = fileManager.enumerator(atPath: sourcesPath) else {
            return issues
        }

        while let file = enumerator.nextObject() as? String {
            if file.hasSuffix(".swift") {
                let fullPath = "\(sourcesPath)/\(file)"
                if let content = try? String(contentsOfFile: fullPath, encoding: .utf8) {
                    // Check for invalid or empty file placeholders
                    if content.contains("TODO: Implementation required") && !content.contains("import") {
                        issues.append(DependencyIssue(filePath: file, message: "Contains unfulfilled placeholder code."))
                    }
                }
            }
        }

        return issues
    }

    public func diagnose(projectRootPath: String = FileManager.default.currentDirectoryPath) -> DiagnosticsReport {
        let tools = ["tuist", "xcodegen", "periphery", "swiftlint", "swiftformat", "git", "mise", "make"]
        let toolResults = tools.map { checkTool($0) }

        let configPath = "\(projectRootPath)/.swiftblock/config.yml"
        let isProject = fileManager.fileExists(atPath: configPath)

        var configValid = false
        var configMsg = "No .swiftblock/config.yml found in current working directory."

        if isProject {
            if let _ = try? SwiftBlockConfig.load(from: projectRootPath) {
                configValid = true
                configMsg = "Project configuration (.swiftblock/config.yml) is valid."
            } else {
                configMsg = "Project configuration (.swiftblock/config.yml) is malformed."
            }
        }

        var manifestFound: String? = nil
        if fileManager.fileExists(atPath: "\(projectRootPath)/Project.swift") {
            manifestFound = "Tuist (Project.swift)"
        } else if fileManager.fileExists(atPath: "\(projectRootPath)/project.yml") {
            manifestFound = "XcodeGen (project.yml)"
        }

        let depIssues = analyzeDependencyGraph(projectRootPath: projectRootPath)

        let peripheryTool = toolResults.first(where: { $0.name == "periphery" })
        let peripheryYml = fileManager.fileExists(atPath: "\(projectRootPath)/.periphery.yml")
        let peripheryStatus: String
        if peripheryTool?.isInstalled == true && peripheryYml {
            peripheryStatus = "Installed & Configured (.periphery.yml present)"
        } else if peripheryTool?.isInstalled == true {
            peripheryStatus = "Installed (No .periphery.yml configuration file)"
        } else {
            peripheryStatus = "Not installed"
        }

        return DiagnosticsReport(
            toolChecks: toolResults,
            isProjectFolder: isProject,
            configValid: configValid,
            configMessage: configMsg,
            manifestFound: manifestFound,
            dependencyIssues: depIssues,
            peripheryStatus: peripheryStatus
        )
    }

    public func printDiagnosticsReport(projectRootPath: String = FileManager.default.currentDirectoryPath) {
        let report = diagnose(projectRootPath: projectRootPath)

        print("┌  \(ANSIColor.boldText("SwiftBlock System & Workspace Diagnostics"))")
        print("│")
        print("│  \(ANSIColor.boldText("Developer Tools Health:"))")
        for check in report.toolChecks {
            let icon = check.isInstalled ? "✔" : "!"
            let colorIcon = check.isInstalled ? ANSIColor.greenText(icon) : ANSIColor.yellowText(icon)
            let versionInfo = check.version.map { "(\($0))" } ?? ""
            let status = check.isInstalled ? "Installed \(versionInfo)" : "Not installed"
            print("│    [\(colorIcon)] \(check.name): \(status)")
        }

        print("│")
        print("│  \(ANSIColor.boldText("Project Workspace Status:"))")
        if report.isProjectFolder {
            let icon = report.configValid ? ANSIColor.greenText("✔") : ANSIColor.redText("✖")
            print("│    [\(icon)] Configuration: \(report.configMessage)")
            if let manifest = report.manifestFound {
                print("│    [\(ANSIColor.greenText("✔"))] Project Manifest: \(manifest)")
            } else {
                print("│    [\(ANSIColor.yellowText("!"))] Project Manifest: Not found")
            }
        } else {
            print("│    [\(ANSIColor.cyanText("ℹ"))] Workspace: Global execution context (Not inside a SwiftBlock project directory)")
        }

        print("│")
        print("│  \(ANSIColor.boldText("Dead Code & Diagnostics (Periphery):"))")
        print("│    └── Status: \(report.peripheryStatus)")

        if !report.dependencyIssues.isEmpty {
            print("│")
            print("│  \(ANSIColor.boldText("Dependency Graph & Code Integrity Issues:"))")
            for issue in report.dependencyIssues {
                print("│    └── [\(ANSIColor.yellowText("!"))] \(issue.filePath): \(issue.message)")
            }
        }

        print("│")
        let overallOk = report.toolChecks.contains(where: { $0.isInstalled })
        if overallOk {
            print("└  \(ANSIColor.greenText("✔ SwiftBlock environment is operational and healthy."))")
        } else {
            print("└  \(ANSIColor.yellowText("⚠️ SwiftBlock environment requires tooling installation."))")
        }
    }
}
