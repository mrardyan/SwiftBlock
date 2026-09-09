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

    @Test func moduleGeneratorErrorDescriptions() {
        let err1 = ModuleGeneratorError.templateNotFound("/path/1")
        #expect(err1.errorDescription == "Module template not found at /path/1")

        let err2 = ModuleGeneratorError.moduleAlreadyExists("/path/2")
        #expect(err2.errorDescription == "Module already exists at /path/2")

        let err3 = ModuleGeneratorError.generationFailed("Failed")
        #expect(err3.errorDescription == "Failed to generate module: Failed")

        let configErr = SwiftBlockConfigError.configNotFound("/path/3")
        #expect(configErr.errorDescription == "Not a valid SwiftBlock project root (.swiftblock not found at /path/3)")
    }

    @Test func moduleTemplateNotFoundThrows() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let config = SwiftBlockConfig(projectName: "TestApp")
        let configData = try JSONEncoder().encode(config)
        try configData.write(to: tempDir.appendingPathComponent(".swiftblock"))

        let mockModulesURL = tempDir.appendingPathComponent("EmptyModules")
        try FileManager.default.createDirectory(at: mockModulesURL, withIntermediateDirectories: true)

        let options = ModuleGeneratorOptions(
            type: .repository,
            moduleName: "User",
            projectRootPath: tempDir.path,
            modulesTemplatePath: mockModulesURL.path
        )

        let generator = ModuleGenerator()
        #expect(throws: ModuleGeneratorError.self) {
            try generator.generateModule(options: options)
        }
    }

    @Test func moduleAlreadyExistsThrows() throws {
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
        let mockServiceURL = mockModulesURL.appendingPathComponent("Service")
        try FileManager.default.createDirectory(at: mockServiceURL, withIntermediateDirectories: true)

        // Pre-create the module destination folder
        let existingModuleDir = tempDir.appendingPathComponent("App/Sources/Data/Services/Network")
        try FileManager.default.createDirectory(at: existingModuleDir, withIntermediateDirectories: true)

        let options = ModuleGeneratorOptions(
            type: .service,
            moduleName: "Network",
            projectRootPath: tempDir.path,
            modulesTemplatePath: mockModulesURL.path
        )

        let generator = ModuleGenerator()
        #expect(throws: ModuleGeneratorError.self) {
            try generator.generateModule(options: options)
        }
    }

    @Test func generateModuleWithNestedDirectories() throws {
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
        let subDirURL = mockSceneURL.appendingPathComponent("Components")
        try FileManager.default.createDirectory(at: subDirURL, withIntermediateDirectories: true)

        let componentFile = subDirURL.appendingPathComponent("__MODULE_NAME__Header.swift")
        try "struct __MODULE_NAME__Header {}".write(to: componentFile, atomically: true, encoding: .utf8)

        let options = ModuleGeneratorOptions(
            type: .scene,
            moduleName: "Profile",
            projectRootPath: tempDir.path,
            modulesTemplatePath: mockModulesURL.path
        )

        let generator = ModuleGenerator()
        let generatedPath = try generator.generateModule(options: options)

        let expectedComponentPath = "\(generatedPath)/Components/ProfileHeader.swift"
        #expect(FileManager.default.fileExists(atPath: expectedComponentPath))
        let content = try String(contentsOfFile: expectedComponentPath, encoding: .utf8)
        #expect(content == "struct ProfileHeader {}")
    }

    @Test func generateNewModuleTypes() throws {
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

        let types: [(ModuleType, String)] = [
            (.entity, "Entity"),
            (.coordinator, "Coordinator"),
            (.component, "Component"),
            (.storage, "Storage"),
            (.network, "Network"),
            (.logger, "Logger"),
            (.analytics, "Analytics")
        ]

        for (type, folderName) in types {
            let folderURL = mockModulesURL.appendingPathComponent(folderName)
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            let fileURL = folderURL.appendingPathComponent("__MODULE_NAME__Test.swift")
            try "// \(type.rawValue)".write(to: fileURL, atomically: true, encoding: .utf8)

            let options = ModuleGeneratorOptions(
                type: type,
                moduleName: "Sample",
                projectRootPath: tempDir.path,
                modulesTemplatePath: mockModulesURL.path
            )

            let generator = ModuleGenerator()
            let generatedPath = try generator.generateModule(options: options)
            #expect(FileManager.default.fileExists(atPath: "\(generatedPath)/SampleTest.swift"))
        }
    }

    @Test func defaultModuleGeneratorOptionsTemplatePaths() {
        let featureOpt = ModuleGeneratorOptions(type: .scene, moduleName: "Test")
        #expect(featureOpt.modulesTemplatePath == "/usr/local/share/swiftblock/Blocks/Modules")

        let coreOpt = ModuleGeneratorOptions(type: .network, moduleName: "Test")
        #expect(coreOpt.modulesTemplatePath == "/usr/local/share/swiftblock/Blocks/Core")
    }
}



