import Foundation
import Testing
@testable import SwiftBlockCore

struct HooksEngineTests {
    @Test func commandRendering() {
        let command = "echo 'Module {{moduleName}} for project {{projectName}} with timeout {{timeout}}'"
        let rendered = HooksEngine.renderCommand(
            command,
            variables: ["timeout": "60"],
            projectName: "TestApp",
            moduleName: "Profile"
        )
        
        #expect(rendered == "echo 'Module Profile for project TestApp with timeout 60'")
    }

    @Test func dryRunHookExecution() throws {
        let command = "echo 'hello world'"
        try HooksEngine.executeHook(
            command,
            variables: [:],
            projectName: "TestApp",
            moduleName: "Profile",
            isDryRun: true
        )
    }

    @Test func realHookExecution() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let targetFile = "\(tempDir)/output.txt"
        let command = "echo 'HookExecuted' > output.txt"

        try HooksEngine.executeHooks(
            [command],
            variables: [:],
            projectName: "TestApp",
            moduleName: nil,
            projectRootPath: tempDir,
            isDryRun: false
        )

        #expect(FileManager.default.fileExists(atPath: targetFile))
        let content = try String(contentsOfFile: targetFile, encoding: .utf8)
        #expect(content.trimmingCharacters(in: .newlines) == "HookExecuted")
    }

    @Test func manifestHooksParsing() {
        let yamlContent = """
        name: customservice
        hooks:
          post_snap:
            - "echo 'HookExecuted: {{moduleName}}' > hook_output.txt"
        """

        let manifest = BrickManifest.parseYAML(yamlContent, folderName: "customservice")
        #expect(manifest.postSnapHooks.count == 1)
        #expect(manifest.postSnapHooks[0].contains("HookExecuted"))
    }

    @Test func failedHookExecutionGracefullyHandled() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let failingCommand = "non_existent_command_123456789 || exit 1"
        #expect(throws: Never.self) {
            try HooksEngine.executeHook(
                failingCommand,
                variables: [:],
                projectName: "TestApp",
                moduleName: "Profile",
                projectRootPath: tempDir
            )
        }
    }
}
