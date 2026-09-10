import Foundation
import Testing
@testable import SwiftBlockCore

struct BlueprintEngineTests {

    @Test func executeDefaultBuiltInBlueprint() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let config = SwiftBlockConfig(
            projectName: "BlueprintTestApp",
            bundlePrefix: "com.test"
        )
        try config.save(to: tempDir.path)

        let engine = BlueprintEngine()
        let result = try engine.executeBlueprint(
            name: "feature",
            moduleName: "Profile",
            config: config,
            templatePath: "/usr/local/share/swiftblock/Blocks/Modules",
            projectPath: tempDir.path,
            isDryRun: true
        )

        #expect(result.blueprintName == "feature")
        #expect(result.moduleName == "Profile")
        #expect(result.generatedBlocks == [.scene, .usecase, .repository, .mapper])
    }

    @Test func saveAndLoadCustomBlueprint() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        var config = SwiftBlockConfig(
            projectName: "SaveTestApp",
            bundlePrefix: "com.test"
        )
        config.blueprints["custom_screen"] = ["scene", "service"]
        try config.save(to: tempDir.path)

        let loadedConfig = try SwiftBlockConfig.load(from: tempDir.path)
        #expect(loadedConfig.blueprints["custom_screen"] == ["scene", "service"])
        #expect(loadedConfig.blueprints["feature"] == ["scene", "usecase", "repository", "mapper"])
    }

    @Test func blueprintNotFoundThrows() {
        let config = SwiftBlockConfig(projectName: "App")
        let engine = BlueprintEngine()

        #expect(throws: BlueprintEngineError.blueprintNotFound("nonexistent")) {
            try engine.executeBlueprint(name: "nonexistent", moduleName: "Home", config: config, isDryRun: true)
        }
    }
}
