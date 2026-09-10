import Foundation
import Testing
@testable import SwiftBlockCore

struct EnvironmentSetupGeneratorTests {

    @Test func generateSetupFiles() throws {
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

        #expect(FileManager.default.fileExists(atPath: makefile.path))
        #expect(FileManager.default.fileExists(atPath: miseFile.path))
        #expect(FileManager.default.fileExists(atPath: scriptFile.path))

        let makefileContent = try String(contentsOf: makefile, encoding: .utf8)
        #expect(makefileContent.contains("help:"))
        #expect(makefileContent.contains("Usage: make [target]"))
        #expect(makefileContent.contains("tuist generate"))
        #expect(makefileContent.contains("swiftlint"))

        let miseContent = try String(contentsOf: miseFile, encoding: .utf8)
        #expect(miseContent.contains("tuist = \"4.12.0\""))
        #expect(miseContent.contains("swiftlint = \"0.55.0\""))

        let scriptContent = try String(contentsOf: scriptFile, encoding: .utf8)
        #expect(scriptContent.contains("mise install"))
        #expect(scriptContent.contains("pre-commit install"))
        #expect(scriptContent.contains("tuist generate"))
    }

    @Test func generateSetupFilesMinimalGuardrails() throws {
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
        #expect(makefileContent.contains("xcodegen generate"))
        #expect(!makefileContent.contains("swiftlint"))
        #expect(!makefileContent.contains("swiftformat"))

        let miseContent = try String(contentsOf: tempDir.appendingPathComponent(".mise.toml"), encoding: .utf8)
        #expect(miseContent.contains("xcodegen ="))
        #expect(!miseContent.contains("swiftlint"))
        #expect(!miseContent.contains("swiftformat"))

        let scriptContent = try String(contentsOf: tempDir.appendingPathComponent("Scripts/setup.sh"), encoding: .utf8)
        #expect(scriptContent.contains("xcodegen generate"))
        #expect(!scriptContent.contains("pre-commit install"))
    }

    @Test func setupScriptIsExecutable() throws {
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
            #expect(permissions.int16Value & 0o111 != 0) // check executable bit
        }
    }
}

