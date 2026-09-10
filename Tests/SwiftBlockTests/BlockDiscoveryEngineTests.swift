import Foundation
import Testing
@testable import SwiftBlockCore

struct BlockDiscoveryEngineTests {

    @Test func evaluateTokens() {
        let template = "App/Sources/Features/{module}/{block}"
        let evaluated = BlockDiscoveryEngine.evaluateTokens(in: template, moduleName: "Auth", blockName: "UseCase")
        #expect(evaluated == "App/Sources/Features/auth/usecase")
    }

    @Test func discoverBlocksInDirectory() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let modulesDir = tempDir.appendingPathComponent("Modules")
        let customBlockDir = modulesDir.appendingPathComponent("CustomForm")
        try FileManager.default.createDirectory(at: customBlockDir, withIntermediateDirectories: true)

        let metadataJSON = """
        {
            "title": "CustomForm",
            "description": "Custom Form Validator",
            "defaultOutputPath": "App/Sources/Forms/{module}"
        }
        """
        try metadataJSON.write(to: customBlockDir.appendingPathComponent("block.json"), atomically: true, encoding: .utf8)
        try "struct __MODULE_NAME__Form {}".write(to: customBlockDir.appendingPathComponent("__MODULE_NAME__Form.swift"), atomically: true, encoding: .utf8)

        let engine = BlockDiscoveryEngine()
        let discovered = engine.discoverBlocks(in: tempDir.path, category: .feature)

        #expect(discovered.count == 1)
        #expect(discovered.first?.title == "CustomForm")
        #expect(discovered.first?.commandName == "customform")
        #expect(discovered.first?.defaultOutputPath == "App/Sources/Forms/{module}")
    }

    @Test func blockJsonIsNotCopiedToGeneratedProject() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        // Setup mock config
        let config = SwiftBlockConfig(
            projectName: "TestApp",
            packaging: PackagingConfig(feature: "monolithic", core: "spm"),
            pathTemplates: [
                "feature": "App/Sources/Features/{module}/{block}",
                "core": "Packages/Core/Sources/{block}"
            ]
        )
        let configData = try JSONEncoder().encode(config)
        try configData.write(to: tempDir.appendingPathComponent(".swiftblock"))

        // Setup mock template with block.json
        let mockModulesDir = tempDir.appendingPathComponent("MockModules")
        let mockSceneDir = mockModulesDir.appendingPathComponent("Scene")
        try FileManager.default.createDirectory(at: mockSceneDir, withIntermediateDirectories: true)

        try "{\"title\": \"Scene\"}".write(to: mockSceneDir.appendingPathComponent("block.json"), atomically: true, encoding: .utf8)
        try "struct __MODULE_NAME__View {}".write(to: mockSceneDir.appendingPathComponent("__MODULE_NAME__View.swift"), atomically: true, encoding: .utf8)

        let options = ModuleGeneratorOptions(
            type: .scene,
            moduleName: "Home",
            projectRootPath: tempDir.path,
            modulesTemplatePath: mockModulesDir.path
        )

        let generator = ModuleGenerator()
        let generatedPath = try generator.generateModule(options: options)

        let generatedView = "\(generatedPath)/HomeView.swift"
        let generatedBlockJson = "\(generatedPath)/block.json"

        #expect(FileManager.default.fileExists(atPath: generatedView))
        #expect(!FileManager.default.fileExists(atPath: generatedBlockJson))
    }
}
