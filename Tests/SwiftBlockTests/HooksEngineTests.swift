import XCTest
@testable import SwiftBlockCore

final class HooksEngineTests: XCTestCase {
    func testCommandRendering() {
        let command = "echo 'Module {{moduleName}} for project {{projectName}} with timeout {{timeout}}'"
        let rendered = HooksEngine.renderCommand(
            command,
            variables: ["timeout": "60"],
            projectName: "TestApp",
            moduleName: "Profile"
        )
        
        XCTAssertEqual(rendered, "echo 'Module Profile for project TestApp with timeout 60'")
    }

    func testDryRunHookExecution() throws {
        let command = "echo 'hello world'"
        XCTAssertNoThrow(
            try HooksEngine.executeHook(
                command,
                variables: [:],
                projectName: "TestApp",
                moduleName: "Profile",
                isDryRun: true
            )
        )
    }

    func testRealHookExecution() throws {
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

        XCTAssertTrue(FileManager.default.fileExists(atPath: targetFile))
        let content = try String(contentsOfFile: targetFile, encoding: .utf8)
        XCTAssertEqual(content.trimmingCharacters(in: .newlines), "HookExecuted")
    }
}
