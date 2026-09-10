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

    @Test func generatorFactorySelection() {
        let tuistGenerator = ProjectManifestGeneratorFactory.createGenerator(for: .tuist)
        #expect(tuistGenerator is TuistManifestGenerator)

        let xcodeGenGenerator = ProjectManifestGeneratorFactory.createGenerator(for: .xcodegen)
        #expect(xcodeGenGenerator is XcodeGenManifestGenerator)
    }
}
