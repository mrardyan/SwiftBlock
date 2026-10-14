import Foundation
@testable import SwiftBlockCore
import XCTest

final class EnvironmentSetupGeneratorTests: XCTestCase {
    func testGenerateSetupFiles() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let config = SwiftBlockConfig(
            projectName: "EnvTestApp",
            bundlePrefix: "com.test",
            generatorTool: .tuist,
            guardrails: GuardrailsConfig(swiftlint: true, swiftformat: true, precommit: true),
            toolVersions: ["tuist": "4.12.0", "swiftlint": "0.55.0"]
        )

        let setupGen = EnvironmentSetupGenerator()
        try setupGen.generateSetupFiles(in: tempDir.path, config: config)

        let makefile = tempDir.appendingPathComponent("Makefile")
        let miseFile = tempDir.appendingPathComponent(".mise.toml")
        let scriptFile = tempDir.appendingPathComponent("Scripts/setup.sh")

        XCTAssertTrue(FileManager.default.fileExists(atPath: makefile.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: miseFile.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: scriptFile.path))

        let makefileContent = try String(contentsOf: makefile, encoding: .utf8)
        XCTAssertTrue(makefileContent.contains("help:"))
        XCTAssertTrue(makefileContent.contains("Usage: make [target]"))
        XCTAssertTrue(makefileContent.contains("tuist generate"))
        XCTAssertTrue(makefileContent.contains("swiftlint"))

        let miseContent = try String(contentsOf: miseFile, encoding: .utf8)
        XCTAssertTrue(miseContent.contains("[tools]"))
        XCTAssertTrue(miseContent.contains("tuist = \"4.12.0\""))
        XCTAssertTrue(miseContent.contains("swiftlint = \"0.55.0\""))

        let scriptContent = try String(contentsOf: scriptFile, encoding: .utf8)
        XCTAssertTrue(scriptContent.contains("mise install"))
        XCTAssertTrue(scriptContent.contains("pre-commit install"))
        XCTAssertTrue(scriptContent.contains("tuist generate"))
    }

    func testGenerateSetupFilesMinimalGuardrails() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let config = SwiftBlockConfig(
            projectName: "MinimalApp",
            bundlePrefix: "com.test",
            generatorTool: .xcodegen,
            guardrails: .none
        )

        let setupGen = EnvironmentSetupGenerator()
        try setupGen.generateSetupFiles(in: tempDir.path, config: config)

        let makefileContent = try String(contentsOf: tempDir.appendingPathComponent("Makefile"), encoding: .utf8)
        XCTAssertTrue(makefileContent.contains("xcodegen generate"))
        XCTAssertFalse(makefileContent.contains("swiftlint"))
        XCTAssertFalse(makefileContent.contains("swiftformat"))

        let miseContent = try String(contentsOf: tempDir.appendingPathComponent(".mise.toml"), encoding: .utf8)
        XCTAssertTrue(miseContent.contains("xcodegen ="))
        XCTAssertFalse(miseContent.contains("swiftlint"))
        XCTAssertFalse(miseContent.contains("swiftformat"))

        let scriptContent = try String(contentsOf: tempDir.appendingPathComponent("Scripts/setup.sh"), encoding: .utf8)
        XCTAssertTrue(scriptContent.contains("xcodegen generate"))
        XCTAssertFalse(scriptContent.contains("pre-commit install"))
    }

    func testSetupScriptIsExecutable() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let config = SwiftBlockConfig(projectName: "PermApp", bundlePrefix: "com.test")
        let setupGen = EnvironmentSetupGenerator()
        try setupGen.generateSetupFiles(in: tempDir.path, config: config)

        let scriptPath = tempDir.appendingPathComponent("Scripts/setup.sh").path
        let attrs = try FileManager.default.attributesOfItem(atPath: scriptPath)
        if let permissions = attrs[.posixPermissions] as? NSNumber {
            XCTAssertNotEqual(permissions.int16Value & 0o111, 0) // check executable bit
        }
    }
}
