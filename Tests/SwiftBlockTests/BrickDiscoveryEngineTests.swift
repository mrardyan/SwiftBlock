import Foundation
import Testing
@testable import SwiftBlockCore

struct BrickDiscoveryEngineTests {

    @Test func evaluateTokens() {
        let template = "App/Sources/Features/{module}/{block}"
        let evaluated = BrickDiscoveryEngine.evaluateTokens(in: template, moduleName: "Auth", blockName: "UseCase")
        #expect(evaluated == "App/Sources/Features/auth/usecase")
    }

    @Test func discoverBlocksInDirectory() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let modulesDir = tempDir.appendingPathComponent("Bricks/Generatives/Architecture")
        let customBlockDir = modulesDir.appendingPathComponent("CustomForm")
        try FileManager.default.createDirectory(at: customBlockDir, withIntermediateDirectories: true)

        let metadataYAML = """
        name: customform
        category: architecture
        description: "Custom Form Validator"
        defaultPath: "App/Sources/Forms/{module}"
        """
        try metadataYAML.write(to: customBlockDir.appendingPathComponent("brick.yml"), atomically: true, encoding: .utf8)
        try "struct __MODULE_NAME__Form {}".write(to: customBlockDir.appendingPathComponent("__MODULE_NAME__Form.swift"), atomically: true, encoding: .utf8)

        let engine = BrickDiscoveryEngine()
        let discovered = engine.discoverBricks(in: tempDir.path, category: .feature)

        #expect(!discovered.isEmpty)
        #expect(discovered.contains { $0.commandName == "customform" })
    }

    @Test func resolveBrickPathSmartNamespace() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let networkBrickDir = tempDir.appendingPathComponent("Bricks/Singletons/Network")
        try FileManager.default.createDirectory(at: networkBrickDir, withIntermediateDirectories: true)
        try "name: network\ninstantiation: singleton".write(to: networkBrickDir.appendingPathComponent("brick.yml"), atomically: true, encoding: .utf8)

        let engine = BrickDiscoveryEngine()
        let resolvedShort = engine.resolveBrickPath(named: "network", in: tempDir.path)
        #expect(resolvedShort != nil)
        #expect(resolvedShort?.lowercased().hasSuffix("network") == true)
    }

    @Test func resolveBrickPathCategorySlashNamespace() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let networkBrickDir = tempDir.appendingPathComponent("Bricks/Singletons/Network")
        try FileManager.default.createDirectory(at: networkBrickDir, withIntermediateDirectories: true)
        try "name: network\ninstantiation: singleton".write(to: networkBrickDir.appendingPathComponent("brick.yml"), atomically: true, encoding: .utf8)

        let sceneBrickDir = tempDir.appendingPathComponent("Bricks/Generatives/Architecture/Scene")
        try FileManager.default.createDirectory(at: sceneBrickDir, withIntermediateDirectories: true)
        try "name: scene\ninstantiation: generative".write(to: sceneBrickDir.appendingPathComponent("brick.yml"), atomically: true, encoding: .utf8)

        let engine = BrickDiscoveryEngine()
        let resolvedCoreNetwork = engine.resolveBrickPath(named: "core/network", in: tempDir.path)
        #expect(resolvedCoreNetwork != nil)
        #expect(resolvedCoreNetwork?.lowercased().hasSuffix("network") == true)

        let resolvedFeatureScene = engine.resolveBrickPath(named: "feature/scene", in: tempDir.path)
        #expect(resolvedFeatureScene != nil)
        #expect(resolvedFeatureScene?.lowercased().hasSuffix("scene") == true)
    }

    @Test func brickYmlIsNotCopiedToGeneratedProject() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let config = SwiftBlockConfig(projectName: "TestApp")
        try config.save(to: tempDir.path)

        let mockModulesDir = tempDir.appendingPathComponent("MockModules")
        let mockSceneDir = mockModulesDir.appendingPathComponent("Scene")
        try FileManager.default.createDirectory(at: mockSceneDir, withIntermediateDirectories: true)

        try "name: scene".write(to: mockSceneDir.appendingPathComponent("brick.yml"), atomically: true, encoding: .utf8)
        try "struct __MODULE_NAME__View {}".write(to: mockSceneDir.appendingPathComponent("__MODULE_NAME__View.swift"), atomically: true, encoding: .utf8)

        let options = BrickGeneratorOptions(
            type: .scene,
            name: "Home",
            projectRootPath: tempDir.path,
            modulesTemplatePath: mockModulesDir.path
        )

        let generator = BrickGenerator()
        let generatedPath = try generator.generateBrick(options: options)

        let generatedView = "\(generatedPath)/HomeView.swift"
        let generatedBlockYml = "\(generatedPath)/brick.yml"

        #expect(FileManager.default.fileExists(atPath: generatedView))
        #expect(!FileManager.default.fileExists(atPath: generatedBlockYml))
    }
}
