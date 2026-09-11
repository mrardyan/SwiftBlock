import Foundation
import Testing
@testable import SwiftBlockCore

struct KitEngineTests {

    @Test func executeDefaultBuiltInKit() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let config = SwiftBlockConfig(
            projectName: "KitTestApp",
            bundlePrefix: "com.test"
        )
        try config.save(to: tempDir.path)

        let engine = KitEngine()
        let result = try engine.executeKit(
            name: "feature",
            moduleName: "Profile",
            config: config,
            projectPath: tempDir.path,
            isDryRun: true
        )

        #expect(result.kitName == "feature")
        #expect(result.moduleName == "Profile")
        #expect(result.generatedBricks == [.scene, .usecase, .repository, .mapper])
    }

    @Test func saveAndLoadCustomKit() throws {
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
        config.kits["custom_screen"] = ["scene", "service"]
        try config.save(to: tempDir.path)

        let loadedConfig = try SwiftBlockConfig.load(from: tempDir.path)
        #expect(loadedConfig.kits["custom_screen"] == ["scene", "service"])
        #expect(loadedConfig.kits["feature"] == ["scene", "usecase", "repository", "mapper"])
    }

    @Test func kitNotFoundThrows() {
        let config = SwiftBlockConfig(projectName: "App")
        let engine = KitEngine()

        #expect(throws: KitEngineError.kitNotFound("nonexistent")) {
            try engine.executeKit(name: "nonexistent", moduleName: "Home", config: config, isDryRun: true)
        }
    }
}
