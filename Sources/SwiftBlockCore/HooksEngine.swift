import Foundation

public struct HooksEngine {
    public static func renderCommand(
        _ command: String,
        variables: [String: String] = [:],
        projectName: String = "",
        moduleName: String? = nil
    ) -> String {
        var rendered = command
        rendered = rendered.replacingOccurrences(of: "__PROJECT_NAME__", with: projectName)
        rendered = rendered.replacingOccurrences(of: "{{projectName}}", with: projectName)
        
        if let moduleName = moduleName {
            rendered = rendered.replacingOccurrences(of: "__MODULE_NAME__", with: moduleName)
            rendered = rendered.replacingOccurrences(of: "{{moduleName}}", with: moduleName)
            rendered = rendered.replacingOccurrences(of: "{{name}}", with: moduleName)
        }
        
        for (key, value) in variables {
            rendered = rendered.replacingOccurrences(of: "{{\(key)}}", with: value)
            rendered = rendered.replacingOccurrences(of: "{{variables.\(key)}}", with: value)
        }
        
        return rendered
    }

    public static func executeHook(
        _ commandString: String,
        variables: [String: String] = [:],
        projectName: String = "",
        moduleName: String? = nil,
        projectRootPath: String = FileManager.default.currentDirectoryPath,
        isDryRun: Bool = false
    ) throws {
        let renderedCommand = renderCommand(commandString, variables: variables, projectName: projectName, moduleName: moduleName)
        
        if isDryRun {
            print("🔍 [DRY RUN] Would execute hook command: \(renderedCommand)")
            return
        }
        
        print("⚡️ Executing hook: \(renderedCommand)")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", renderedCommand]
        process.currentDirectoryURL = URL(fileURLWithPath: projectRootPath)
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            print("⚠️ Hook command failed (exit code \(process.terminationStatus)): \(errorMessage.trimmingCharacters(in: .newlines))")
        }
    }

    public static func executeHooks(
        _ commands: [String],
        variables: [String: String] = [:],
        projectName: String = "",
        moduleName: String? = nil,
        projectRootPath: String = FileManager.default.currentDirectoryPath,
        isDryRun: Bool = false
    ) throws {
        for command in commands {
            try executeHook(
                command,
                variables: variables,
                projectName: projectName,
                moduleName: moduleName,
                projectRootPath: projectRootPath,
                isDryRun: isDryRun
            )
        }
    }
}
