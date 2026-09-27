import Foundation
@testable import SwiftBlockCore
import XCTest

final class IDEConfigGeneratorTests: XCTestCase {
    func testGenerateVSCodeTasks() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let config = SwiftBlockConfig(projectName: "IDETestApp")
        let generator = IDEConfigGenerator()
        try generator.generateVSCodeTasks(projectPath: tempDir, config: config)

        let tasksFile = "\(tempDir)/.vscode/tasks.json"
        XCTAssertTrue(FileManager.default.fileExists(atPath: tasksFile))

        let content = try String(contentsOfFile: tasksFile, encoding: .utf8)
        XCTAssertTrue(content.contains("SwiftBlock: Snap Scene"))
        XCTAssertTrue(content.contains("SwiftBlock: Doctor Diagnostics"))
    }

    func testUpdateMakefileShortcuts() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let makefilePath = "\(tempDir)/Makefile"
        try "setup:\n\techo setup".write(toFile: makefilePath, atomically: true, encoding: .utf8)

        let generator = IDEConfigGenerator()
        try generator.updateMakefileShortcuts(projectPath: tempDir)

        let content = try String(contentsOfFile: makefilePath, encoding: .utf8)
        XCTAssertTrue(content.contains("snap-scene:"))
        XCTAssertTrue(content.contains("swiftblock snap scene"))
    }
}
