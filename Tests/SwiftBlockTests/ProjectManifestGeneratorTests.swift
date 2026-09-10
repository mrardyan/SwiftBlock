import Foundation
import Testing
@testable import SwiftBlockCore

struct ProjectManifestGeneratorTests {

    @Test func tuistManifestGeneratorOutput() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let config = SwiftBlockConfig(
            projectName: "TestTuistApp",
            bundlePrefix: "com.test",
            generatorTool: .tuist
        )

        let generator = TuistManifestGenerator()
        try generator.generateManifest(config: config, projectPath: tempDir.path)

        let projectFile = tempDir.appendingPathComponent("Project.swift")
        #expect(FileManager.default.fileExists(atPath: projectFile.path))

        let content = try String(contentsOf: projectFile, encoding: .utf8)
        #expect(content.contains("name: \"TestTuistApp\""))
        #expect(content.contains("bundleId: \"com.test.TestTuistApp\""))
    }

    @Test func xcodeGenManifestGeneratorOutput() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let config = SwiftBlockConfig(
            projectName: "TestXcodeGenApp",
            bundlePrefix: "com.test",
            generatorTool: .xcodegen
        )

        let generator = XcodeGenManifestGenerator()
        try generator.generateManifest(config: config, projectPath: tempDir.path)

        let projectFile = tempDir.appendingPathComponent("project.yml")
        #expect(FileManager.default.fileExists(atPath: projectFile.path))

        let content = try String(contentsOf: projectFile, encoding: .utf8)
        #expect(content.contains("name: TestXcodeGenApp"))
        #expect(content.contains("bundleIdPrefix: com.test"))
    }

    @Test func tuistManifestGeneratorWithConfigBlock() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let config = SwiftBlockConfig(
            projectName: "TestTuistConfigApp",
            bundlePrefix: "com.test",
            generatorTool: .tuist,
            coreBlocks: [.config]
        )

        let generator = TuistManifestGenerator()
        try generator.generateManifest(config: config, projectPath: tempDir.path)

        let projectFile = tempDir.appendingPathComponent("Project.swift")
        let content = try String(contentsOf: projectFile, encoding: .utf8)
        #expect(content.contains("Development.xcconfig"))
        #expect(content.contains("Staging.xcconfig"))
        #expect(content.contains("Production.xcconfig"))
        #expect(content.contains("TestTuistConfigApp-Dev"))
        #expect(content.contains("TestTuistConfigApp-Staging"))
        #expect(content.contains("TestTuistConfigApp-Prod"))

        // Verify strict Tuist parameter ordering: dependencies must precede settings
        if let depRange = content.range(of: "dependencies:"),
           let setRange = content.range(of: "settings:") {
            #expect(depRange.lowerBound < setRange.lowerBound)
        } else {
            Issue.record("Manifest must contain both 'dependencies:' and 'settings:' parameters.")
        }
    }

    @Test func xcodeGenManifestGeneratorWithConfigBlock() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let config = SwiftBlockConfig(
            projectName: "TestXcodeGenConfigApp",
            bundlePrefix: "com.test",
            generatorTool: .xcodegen,
            coreBlocks: [.config]
        )

        let generator = XcodeGenManifestGenerator()
        try generator.generateManifest(config: config, projectPath: tempDir.path)

        let projectFile = tempDir.appendingPathComponent("project.yml")
        let content = try String(contentsOf: projectFile, encoding: .utf8)
        #expect(content.contains("Configs/Development.xcconfig"))
        #expect(content.contains("TestXcodeGenConfigApp-Dev"))
        #expect(content.contains("TestXcodeGenConfigApp-Staging"))
        #expect(content.contains("TestXcodeGenConfigApp-Prod"))
    }

    @Test func generatorFactorySelection() {
        let tuistGenerator = ProjectManifestGeneratorFactory.createGenerator(for: .tuist)
        #expect(tuistGenerator is TuistManifestGenerator)

        let xcodeGenGenerator = ProjectManifestGeneratorFactory.createGenerator(for: .xcodegen)
        #expect(xcodeGenGenerator is XcodeGenManifestGenerator)
    }
}
