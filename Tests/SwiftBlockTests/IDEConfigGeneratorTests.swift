import Foundation
import Testing
@testable import SwiftBlockCore

struct IDEConfigGeneratorTests {
    @Test func generateVSCodeTasks() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let config = SwiftBlockConfig(projectName: "IDETestApp")
        let generator = IDEConfigGenerator()
        try generator.generateVSCodeTasks(projectPath: tempDir, config: config)

        let tasksFile = "\(tempDir)/.vscode/tasks.json"
        #expect(FileManager.default.fileExists(atPath: tasksFile))

        let content = try String(contentsOfFile: tasksFile, encoding: .utf8)
        #expect(content.contains("SwiftBlock: Snap Scene"))
        #expect(content.contains("SwiftBlock: Doctor Diagnostics"))
    }

    @Test func updateMakefileShortcuts() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let makefilePath = "\(tempDir)/Makefile"
        try "setup:\n\techo setup".write(toFile: makefilePath, atomically: true, encoding: .utf8)

        let generator = IDEConfigGenerator()
        try generator.updateMakefileShortcuts(projectPath: tempDir)

        let content = try String(contentsOfFile: makefilePath, encoding: .utf8)
        #expect(content.contains("snap-scene:"))
        #expect(content.contains("swiftblock snap scene"))
    }
}
