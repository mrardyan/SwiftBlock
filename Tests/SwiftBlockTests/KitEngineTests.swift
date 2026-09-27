import Foundation
@testable import SwiftBlockCore
import XCTest

final class KitEngineTests: XCTestCase {
    func testExecuteDefaultBuiltInKit() throws {
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

        XCTAssertEqual(result.kitName, "feature")
        XCTAssertEqual(result.moduleName, "Profile")
        XCTAssertEqual(result.generatedBricks, [.scene, .usecase, .repository, .mapper])
    }

    func testSaveAndLoadCustomKit() throws {
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
        XCTAssertEqual(loadedConfig.kits["custom_screen"], ["scene", "service"])
        XCTAssertEqual(loadedConfig.kits["feature"], ["scene", "usecase", "repository", "mapper"])
    }

    func testKitNotFoundThrows() {
        let config = SwiftBlockConfig(projectName: "App")
        let engine = KitEngine()

        XCTAssertThrowsError(try engine.executeKit(name: "nonexistent", moduleName: "Home", config: config, isDryRun: true))
    }

    func testKitBrickSpecParsing() {
        let plain = KitBrickSpec.parse("scene")
        XCTAssertEqual(plain.name, "scene")
        XCTAssertTrue(plain.flavors.isEmpty)
        XCTAssertTrue(plain.optionalDeps.isEmpty)

        let withFlavor = KitBrickSpec.parse("scene(stateStyle=combine)")
        XCTAssertEqual(withFlavor.name, "scene")
        XCTAssertEqual(withFlavor.flavors["stateStyle"], "combine")

        let withFlavorAndDeps = KitBrickSpec.parse("repository(strategy=offline-first)[storage,logger]")
        XCTAssertEqual(withFlavorAndDeps.name, "repository")
        XCTAssertEqual(withFlavorAndDeps.flavors["strategy"], "offline-first")
        XCTAssertEqual(withFlavorAndDeps.optionalDeps, ["storage", "logger"])
    }

    func testKitBrickSpecParsingEdgeCases() {
        // Multiple flavors
        let multiFlavor = KitBrickSpec.parse("scene(stateStyle=combine, navigation=stack)")
        XCTAssertEqual(multiFlavor.name, "scene")
        XCTAssertEqual(multiFlavor.flavors["stateStyle"], "combine")
        XCTAssertEqual(multiFlavor.flavors["navigation"], "stack")

        // Whitespace tolerant
        let spaced = KitBrickSpec.parse("  repository ( strategy = offline-first ) [ storage , logger ]  ")
        XCTAssertEqual(spaced.name, "repository")
        XCTAssertEqual(spaced.flavors["strategy"], "offline-first")
        XCTAssertEqual(spaced.optionalDeps, ["storage", "logger"])

        // Optional deps without flavors
        let depsOnly = KitBrickSpec.parse("usecase[exponentialbackoff,logger]")
        XCTAssertEqual(depsOnly.name, "usecase")
        XCTAssertEqual(depsOnly.optionalDeps, ["exponentialbackoff", "logger"])
        XCTAssertTrue(depsOnly.flavors.isEmpty)

        // Brackets but no flavors, and flavors but no brackets
        let emptyBrackets = KitBrickSpec.parse("scene[]")
        XCTAssertEqual(emptyBrackets.name, "scene")
        XCTAssertTrue(emptyBrackets.optionalDeps.isEmpty)

        // Malformed flavor (no '=') is ignored rather than crashing
        let malformedFlavor = KitBrickSpec.parse("scene(badflavor)")
        XCTAssertEqual(malformedFlavor.name, "scene")
        XCTAssertTrue(malformedFlavor.flavors.isEmpty)

        // Unclosed bracket is ignored gracefully
        let unclosed = KitBrickSpec.parse("scene[storage")
        XCTAssertEqual(unclosed.name, "scene")
        XCTAssertTrue(unclosed.optionalDeps.isEmpty)
    }

    func testExecuteKitWithFlavorPresets() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        var config = SwiftBlockConfig(projectName: "FlavorKitApp", bundlePrefix: "com.test")
        config.kits["offline_feature"] = [
            "scene(stateStyle=combine)",
            "repository(strategy=offline-first)[storage]",
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

        XCTAssertEqual(result.kitName, "offline_feature")
        XCTAssertEqual(result.moduleName, "Order")
        XCTAssertEqual(result.generatedBricks, [.scene, .repository])
    }
}
