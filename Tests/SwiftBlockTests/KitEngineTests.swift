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

    @Test func testKitBrickSpecParsing() {
        let plain = KitBrickSpec.parse("scene")
        #expect(plain.name == "scene")
        #expect(plain.flavors.isEmpty)
        #expect(plain.optionalDeps.isEmpty)

        let withFlavor = KitBrickSpec.parse("scene(stateStyle=combine)")
        #expect(withFlavor.name == "scene")
        #expect(withFlavor.flavors["stateStyle"] == "combine")

        let withFlavorAndDeps = KitBrickSpec.parse("repository(strategy=offline-first)[storage,logger]")
        #expect(withFlavorAndDeps.name == "repository")
        #expect(withFlavorAndDeps.flavors["strategy"] == "offline-first")
        #expect(withFlavorAndDeps.optionalDeps == ["storage", "logger"])
    }

    @Test func testKitBrickSpecParsingEdgeCases() {
        // Multiple flavors
        let multiFlavor = KitBrickSpec.parse("scene(stateStyle=combine, navigation=stack)")
        #expect(multiFlavor.name == "scene")
        #expect(multiFlavor.flavors["stateStyle"] == "combine")
        #expect(multiFlavor.flavors["navigation"] == "stack")

        // Whitespace tolerant
        let spaced = KitBrickSpec.parse("  repository ( strategy = offline-first ) [ storage , logger ]  ")
        #expect(spaced.name == "repository")
        #expect(spaced.flavors["strategy"] == "offline-first")
        #expect(spaced.optionalDeps == ["storage", "logger"])

        // Optional deps without flavors
        let depsOnly = KitBrickSpec.parse("usecase[exponentialbackoff,logger]")
        #expect(depsOnly.name == "usecase")
        #expect(depsOnly.optionalDeps == ["exponentialbackoff", "logger"])
        #expect(depsOnly.flavors.isEmpty)

        // Brackets but no flavors, and flavors but no brackets
        let emptyBrackets = KitBrickSpec.parse("scene[]")
        #expect(emptyBrackets.name == "scene")
        #expect(emptyBrackets.optionalDeps.isEmpty)

        // Malformed flavor (no '=') is ignored rather than crashing
        let malformedFlavor = KitBrickSpec.parse("scene(badflavor)")
        #expect(malformedFlavor.name == "scene")
        #expect(malformedFlavor.flavors.isEmpty)

        // Unclosed bracket is ignored gracefully
        let unclosed = KitBrickSpec.parse("scene[storage")
        #expect(unclosed.name == "scene")
        #expect(unclosed.optionalDeps.isEmpty)
    }

    @Test func testExecuteKitWithFlavorPresets() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        var config = SwiftBlockConfig(projectName: "FlavorKitApp", bundlePrefix: "com.test")
        config.kits["offline_feature"] = [
            "scene(stateStyle=combine)",
            "repository(strategy=offline-first)[storage]"
        ]
        try config.save(to: tempDir.path)

        let engine = KitEngine()
        let result = try engine.executeKit(
            name: "offline_feature",
            moduleName: "Order",
            config: config,
            projectPath: tempDir.path,
            isDryRun: true
        )

        #expect(result.kitName == "offline_feature")
        #expect(result.moduleName == "Order")
        #expect(result.generatedBricks == [.scene, .repository])
    }
}
