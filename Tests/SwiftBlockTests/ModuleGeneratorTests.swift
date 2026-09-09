import Foundation
import Testing
@testable import SwiftBlockCore

struct ModuleGeneratorTests {

    @Test func generateSceneModule() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        // Write mock .swiftblock config
        let config = SwiftBlockConfig(projectName: "TestApp")
        let configData = try JSONEncoder().encode(config)
        try configData.write(to: tempDir.appendingPathComponent(".swiftblock"))

        // Write mock modules template folder
        let mockModulesURL = tempDir.appendingPathComponent("MockModules")
        let mockSceneURL = mockModulesURL.appendingPathComponent("Scene")
        try FileManager.default.createDirectory(at: mockSceneURL, withIntermediateDirectories: true)

        let viewTemplate = mockSceneURL.appendingPathComponent("__MODULE_NAME__View.swift")
        try "struct __MODULE_NAME__View {}".write(to: viewTemplate, atomically: true, encoding: .utf8)

        let options = ModuleGeneratorOptions(
            type: .scene,
            moduleName: "Home",
            projectRootPath: tempDir.path,
            modulesTemplatePath: mockModulesURL.path
        )

        let generator = ModuleGenerator()
        let generatedPath = try generator.generateModule(options: options)

        let expectedViewPath = "\(generatedPath)/HomeView.swift"
        #expect(FileManager.default.fileExists(atPath: expectedViewPath))
        let content = try String(contentsOfFile: expectedViewPath, encoding: .utf8)
        #expect(content == "struct HomeView {}")
    }

    @Test func generateUseCaseModule() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let config = SwiftBlockConfig(projectName: "TestApp")
        let configData = try JSONEncoder().encode(config)
        try configData.write(to: tempDir.appendingPathComponent(".swiftblock"))

        let mockModulesURL = tempDir.appendingPathComponent("MockModules")
        let mockUseCaseURL = mockModulesURL.appendingPathComponent("Usecase")
        try FileManager.default.createDirectory(at: mockUseCaseURL, withIntermediateDirectories: true)

        let ucTemplate = mockUseCaseURL.appendingPathComponent("__MODULE_NAME__UseCase.swift")
        try "protocol __MODULE_NAME__UseCase {}".write(to: ucTemplate, atomically: true, encoding: .utf8)

        let options = ModuleGeneratorOptions(
            type: .usecase,
            moduleName: "Authenticate",
            projectRootPath: tempDir.path,
            modulesTemplatePath: mockModulesURL.path
        )

        let generator = ModuleGenerator()
        let generatedPath = try generator.generateModule(options: options)

        let expectedPath = "\(generatedPath)/AuthenticateUseCase.swift"
        #expect(FileManager.default.fileExists(atPath: expectedPath))
    }

    @Test func moduleDryRunModeDoesNotWriteToDisk() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let config = SwiftBlockConfig(projectName: "TestApp")
        let configData = try JSONEncoder().encode(config)
        try configData.write(to: tempDir.appendingPathComponent(".swiftblock"))

        let mockModulesURL = tempDir.appendingPathComponent("MockModules")
        let mockSceneURL = mockModulesURL.appendingPathComponent("Scene")
        try FileManager.default.createDirectory(at: mockSceneURL, withIntermediateDirectories: true)

        let options = ModuleGeneratorOptions(
            type: .scene,
            moduleName: "DryRunHome",
            projectRootPath: tempDir.path,
            modulesTemplatePath: mockModulesURL.path,
            isDryRun: true
        )

        let generator = ModuleGenerator()
        let generatedPath = try generator.generateModule(options: options)

        #expect(!FileManager.default.fileExists(atPath: generatedPath))
    }

    @Test func moduleGenerationFailsWithoutConfig() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        let options = ModuleGeneratorOptions(
            type: .scene,
            moduleName: "Home",
            projectRootPath: tempDir.path
        )

        let generator = ModuleGenerator()
        #expect(throws: SwiftBlockConfigError.self) {
            try generator.generateModule(options: options)
        }
    }
}
