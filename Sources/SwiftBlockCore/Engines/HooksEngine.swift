import Foundation
#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#endif

public enum HooksEngine {
    /// Characters that have special meaning in POSIX shell and must be escaped
    /// when interpolating user-supplied values into hook command strings.
    private static let shellMetacharacters = CharacterSet(charactersIn: ";|&$`\"'\\!#(){}[]<>?*~\n\r")

    /// Escapes shell metacharacters in a value intended for interpolation into
    /// a shell command string. Wraps the value in single quotes and escapes
    /// embedded single quotes using the `'\''` idiom.
    static func shellEscape(_ value: String) -> String {
        // Single-quote wrapping is the safest POSIX escaping strategy.
        // Embedded single quotes are handled by ending the current single-quoted
        // segment, inserting an escaped single quote, and reopening.
        let escaped = value.replacingOccurrences(of: "'", with: "'\\''")
        return "'\(escaped)'"
    }

    /// Returns `true` when the raw (unescaped) value contains characters that
    /// could alter shell execution semantics.
    static func containsShellMetacharacters(_ value: String) -> Bool {
        value.rangeOfCharacter(from: shellMetacharacters) != nil
    }

    public static func renderCommand(
        _ command: String,
        variables: [String: String] = [:],
        projectName: String = "",
        moduleName: String? = nil,
        sanitize: Bool = true
    ) -> String {
        var rendered = command

        // Helper that applies shell-escaping when sanitize mode is on and the
        // value contains characters that could cause injection.
        func safe(_ value: String) -> String {
            guard sanitize, containsShellMetacharacters(value) else { return value }
            return shellEscape(value)
        }

        rendered = rendered.replacingOccurrences(of: "__PROJECT_NAME__", with: safe(projectName))
        rendered = rendered.replacingOccurrences(of: "{{projectName}}", with: safe(projectName))

        if let moduleName {
            rendered = rendered.replacingOccurrences(of: "__MODULE_NAME__", with: safe(moduleName))
            rendered = rendered.replacingOccurrences(of: "{{moduleName}}", with: safe(moduleName))
            rendered = rendered.replacingOccurrences(of: "{{name}}", with: safe(moduleName))
        }

        for (key, value) in variables {
            rendered = rendered.replacingOccurrences(of: "{{\(key)}}", with: safe(value))
            rendered = rendered.replacingOccurrences(of: "{{variables.\(key)}}", with: safe(value))
        }

        return rendered
    }

    /// Prompts the user to confirm hook execution in interactive TTY sessions.
    /// Returns `true` if the user approves, `false` otherwise.
    /// In non-interactive (piped) sessions, returns `false` by default for security,
    /// unless explicitly allowed via `skipConfirmation`, `SWIFTBLOCK_ALLOW_HOOKS=1`, or running inside a test runner.
    static func confirmHookExecution(_ renderedCommand: String, skipConfirmation: Bool = false) -> Bool {
        if skipConfirmation { return true }
        if ProcessInfo.processInfo.environment["SWIFTBLOCK_ALLOW_HOOKS"] == "1"
            || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || NSClassFromString("XCTestCase") != nil
        {
            return true
        }

        guard isatty(STDIN_FILENO) != 0 else {
            print("⚠️ Hook execution denied in non-interactive mode: \(renderedCommand)")
            return false
        }

        print("🔒 A brick hook wants to execute the following command:")
        print("   \(renderedCommand)")
        print("   Allow? [y/N]: ", terminator: "")
        fflush(stdout)

        guard let response = Swift.readLine()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
            return false
        }
        return response == "y" || response == "yes"
    }

    public static func executeHook(
        _ commandString: String,
        variables: [String: String] = [:],
        projectName: String = "",
        moduleName: String? = nil,
        projectRootPath: String = FileManager.default.currentDirectoryPath,
        isDryRun: Bool = false,
        skipConfirmation: Bool = false
    ) throws {
        let renderedCommand = renderCommand(commandString, variables: variables, projectName: projectName, moduleName: moduleName)

        if isDryRun {
            print("🔍 [DRY RUN] Would execute hook command: \(renderedCommand)")
            return
        }

        guard confirmHookExecution(renderedCommand, skipConfirmation: skipConfirmation) else {
            print("⏭️ Hook skipped by user: \(renderedCommand)")
            return
        }

        print("⚡️ Executing hook: \(renderedCommand)")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", renderedCommand]
        process.currentDirectoryURL = URL(fileURLWithPath: projectRootPath)

        // Only stderr is captured; stdout inherits the parent's output to avoid pipe-buffer deadlocks.
        let errorPipe = Pipe()
        process.standardError = errorPipe

        defer {
            try? errorPipe.fileHandleForReading.close()
        }

        try process.run()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
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
        isDryRun: Bool = false,
        skipConfirmation: Bool = false
    ) throws {
        for command in commands {
            try executeHook(
                command,
                variables: variables,
                projectName: projectName,
                moduleName: moduleName,
                projectRootPath: projectRootPath,
                isDryRun: isDryRun,
                skipConfirmation: skipConfirmation
            )
        }
    }
}
