import Foundation
@testable import SwiftBlockCore
import XCTest

final class BrickDiscoveryEngineTests: XCTestCase {
    func testEvaluateTokens() {
        let template = "App/Sources/Features/{module}/{block}"
        let evaluated = BrickDiscoveryEngine.evaluateTokens(in: template, moduleName: "Auth", blockName: "UseCase")
        XCTAssertEqual(evaluated, "App/Sources/Features/auth/usecase")
    }

    func testDiscoverBlocksInDirectory() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let modulesDir = tempDir.appendingPathComponent("Bricks/Feature")
        let customBlockDir = modulesDir.appendingPathComponent("CustomForm")
        try FileManager.default.createDirectory(at: customBlockDir, withIntermediateDirectories: true)

        let metadataYAML = """
        name: customform
        category: feature
        description: "Custom Form Validator"
        defaultPath: "App/Sources/Forms/{module}"
        """
        try metadataYAML.write(to: customBlockDir.appendingPathComponent("brick.yml"), atomically: true, encoding: .utf8)
        try "struct __MODULE_NAME__Form {}".write(to: customBlockDir.appendingPathComponent("__MODULE_NAME__Form.swift"), atomically: true, encoding: .utf8)

        let engine = BrickDiscoveryEngine()
        let discovered = engine.discoverBricks(in: tempDir.path, category: .feature)

        XCTAssertFalse(discovered.isEmpty)
        XCTAssertTrue(discovered.contains { $0.commandName == "customform" })
    }

    func testResolveBrickPathSmartNamespace() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let networkBrickDir = tempDir.appendingPathComponent("Bricks/Core/Network")
        try FileManager.default.createDirectory(at: networkBrickDir, withIntermediateDirectories: true)
        try "name: network\ninstantiation: singleton".write(to: networkBrickDir.appendingPathComponent("brick.yml"), atomically: true, encoding: .utf8)

        let engine = BrickDiscoveryEngine()
        let resolvedShort = engine.resolveBrickPath(named: "network", in: tempDir.path)
        XCTAssertNotEqual(resolvedShort, nil)
        XCTAssertEqual(resolvedShort?.lowercased().hasSuffix("network"), true)
    }

    func testResolveBrickPathCategorySlashNamespace() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let networkBrickDir = tempDir.appendingPathComponent("Bricks/Core/Network")
        try FileManager.default.createDirectory(at: networkBrickDir, withIntermediateDirectories: true)
        try "name: network\ninstantiation: singleton".write(to: networkBrickDir.appendingPathComponent("brick.yml"), atomically: true, encoding: .utf8)

        let sceneBrickDir = tempDir.appendingPathComponent("Bricks/Feature/Scene")
        try FileManager.default.createDirectory(at: sceneBrickDir, withIntermediateDirectories: true)
        try "name: scene\ninstantiation: generative".write(to: sceneBrickDir.appendingPathComponent("brick.yml"), atomically: true, encoding: .utf8)

        let engine = BrickDiscoveryEngine()
        let resolvedCoreNetwork = engine.resolveBrickPath(named: "core/network", in: tempDir.path)
        XCTAssertNotEqual(resolvedCoreNetwork, nil)
        XCTAssertEqual(resolvedCoreNetwork?.lowercased().hasSuffix("network"), true)

        let resolvedFeatureScene = engine.resolveBrickPath(named: "feature/scene", in: tempDir.path)
        XCTAssertNotEqual(resolvedFeatureScene, nil)
        XCTAssertEqual(resolvedFeatureScene?.lowercased().hasSuffix("scene"), true)
    }

    func testResolveNestedSubpathNamespace() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let emailBrickDir = tempDir.appendingPathComponent("Bricks/Utils/Validator/Email")
        try FileManager.default.createDirectory(at: emailBrickDir, withIntermediateDirectories: true)
        try "name: email\ninstantiation: singleton".write(to: emailBrickDir.appendingPathComponent("brick.yml"), atomically: true, encoding: .utf8)

        let currencyBrickDir = tempDir.appendingPathComponent("Bricks/Utils/Formatter/Currency")
        try FileManager.default.createDirectory(at: currencyBrickDir, withIntermediateDirectories: true)
        try "name: currency\ninstantiation: singleton".write(to: currencyBrickDir.appendingPathComponent("brick.yml"), atomically: true, encoding: .utf8)

        let engine = BrickDiscoveryEngine()
        let resolvedEmail = engine.resolveBrickPath(named: "utils/validator/email", in: tempDir.path)
        XCTAssertNotEqual(resolvedEmail, nil)
        XCTAssertEqual(resolvedEmail?.lowercased().hasSuffix("validator/email"), true)

        let resolvedCurrency = engine.resolveBrickPath(named: "utils/formatter/currency", in: tempDir.path)
        XCTAssertNotEqual(resolvedCurrency, nil)
        XCTAssertEqual(resolvedCurrency?.lowercased().hasSuffix("formatter/currency"), true)
    }

    func testBrickYmlIsNotCopiedToGeneratedProject() throws {
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

        XCTAssertTrue(FileManager.default.fileExists(atPath: generatedView))
        XCTAssertFalse(FileManager.default.fileExists(atPath: generatedBlockYml))
    }
}
