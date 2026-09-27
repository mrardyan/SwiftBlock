import Foundation
@testable import SwiftBlockCore
import XCTest

final class ProjectManifestGeneratorTests: XCTestCase {
    func testTuistManifestGeneratorOutput() throws {
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
        XCTAssertTrue(FileManager.default.fileExists(atPath: projectFile.path))

        let content = try String(contentsOf: projectFile, encoding: .utf8)
        XCTAssertTrue(content.contains("name: \"TestTuistApp\""))
        XCTAssertTrue(content.contains("bundleId: \"com.test.TestTuistApp\""))
    }

    func testXcodeGenManifestGeneratorOutput() throws {
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
        XCTAssertTrue(FileManager.default.fileExists(atPath: projectFile.path))

        let content = try String(contentsOf: projectFile, encoding: .utf8)
        XCTAssertTrue(content.contains("name: TestXcodeGenApp"))
        XCTAssertTrue(content.contains("bundleIdPrefix: com.test"))
    }

    func testTuistManifestGeneratorWithConfigBlock() throws {
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
        XCTAssertTrue(content.contains("Development.xcconfig"))
        XCTAssertTrue(content.contains("Staging.xcconfig"))
        XCTAssertTrue(content.contains("Production.xcconfig"))
        XCTAssertTrue(content.contains("TestTuistConfigApp-Dev"))
        XCTAssertTrue(content.contains("TestTuistConfigApp-Stg"))
        XCTAssertTrue(content.contains("TestTuistConfigApp"))

        // Verify target parameter ordering: dependencies must precede target settings
        if let depRange = content.range(of: "dependencies: ["),
           let lastSetRange = content.range(of: "settings:", options: .backwards)
        {
            XCTAssertLessThan(depRange.lowerBound, lastSetRange.lowerBound)
        } else {
            XCTFail("Manifest must contain both 'dependencies:' and 'settings:' parameters.")
        }
    }

    func testXcodeGenManifestGeneratorWithConfigBlock() throws {
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
        XCTAssertTrue(content.contains("Configs/Development.xcconfig"))
        XCTAssertTrue(content.contains("TestXcodeGenConfigApp-Dev"))
        XCTAssertTrue(content.contains("TestXcodeGenConfigApp-Stg"))
        XCTAssertTrue(content.contains("TestXcodeGenConfigApp:"))
    }

    func testGeneratorFactorySelection() {
        let tuistGenerator = ProjectManifestGeneratorFactory.createGenerator(for: .tuist)
        XCTAssertTrue(tuistGenerator is TuistManifestGenerator)

        let xcodeGenGenerator = ProjectManifestGeneratorFactory.createGenerator(for: .xcodegen)
        XCTAssertTrue(xcodeGenGenerator is XcodeGenManifestGenerator)
    }
}
