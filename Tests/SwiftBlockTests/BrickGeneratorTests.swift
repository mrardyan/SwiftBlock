import Foundation
import Testing
@testable import SwiftBlockCore

struct BrickGeneratorTests {

    @Test func generateSceneBrick() throws {
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
        try "struct __MODULE_NAME__View {}\n".write(to: viewTemplate, atomically: true, encoding: .utf8)

        let options = BrickGeneratorOptions(
            type: .scene,
            name: "Home",
            projectRootPath: tempDir.path,
            modulesTemplatePath: mockModulesURL.path
        )

        let generator = BrickGenerator()
        let generatedPath = try generator.generateBrick(options: options)

        let expectedViewPath = "\(generatedPath)/HomeView.swift"
        #expect(FileManager.default.fileExists(atPath: expectedViewPath))
        let content = try String(contentsOfFile: expectedViewPath, encoding: .utf8)
        #expect(content == "struct HomeView {}\n")
    }

    @Test func generateUseCaseBrick() throws {
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
        try "protocol __MODULE_NAME__UseCase {}\n".write(to: ucTemplate, atomically: true, encoding: .utf8)

        let options = BrickGeneratorOptions(
            type: .usecase,
            name: "Authenticate",
            projectRootPath: tempDir.path,
            modulesTemplatePath: mockModulesURL.path
        )

        let generator = BrickGenerator()
        let generatedPath = try generator.generateBrick(options: options)

        let expectedPath = "\(generatedPath)/AuthenticateUseCase.swift"
        #expect(FileManager.default.fileExists(atPath: expectedPath))
    }

    @Test func brickDryRunModeDoesNotWriteToDisk() throws {
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

        let options = BrickGeneratorOptions(
            type: .scene,
            name: "DryRunHome",
            projectRootPath: tempDir.path,
            modulesTemplatePath: mockModulesURL.path,
            isDryRun: true
        )

        let generator = BrickGenerator()
        let generatedPath = try generator.generateBrick(options: options)

        #expect(!FileManager.default.fileExists(atPath: generatedPath))
    }

    @Test func brickGenerationFailsWithoutConfig() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        let options = BrickGeneratorOptions(
            type: .scene,
            name: "Home",
            projectRootPath: tempDir.path
        )

        let generator = BrickGenerator()
        #expect(throws: SwiftBlockConfigError.self) {
            try generator.generateBrick(options: options)
        }
    }

    @Test func brickGeneratorErrorDescriptions() {
        let err1 = BrickGeneratorError.templateNotFound("/path/1")
        #expect(err1.errorDescription == "Brick template not found at /path/1")

        let err2 = BrickGeneratorError.brickAlreadyExists("/path/2")
        #expect(err2.errorDescription == "Brick already exists at /path/2")

        let err3 = BrickGeneratorError.generationFailed("Failed")
        #expect(err3.errorDescription == "Failed to generate brick: Failed")

        let configErr = SwiftBlockConfigError.configNotFound("/path/3")
        #expect(configErr.errorDescription == "Not a valid SwiftBlock project root (.swiftblock not found at /path/3)")
    }

    @Test func brickTemplateNotFoundThrows() throws {
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

        let options = BrickGeneratorOptions(
            type: .repository,
            name: "User",
            projectRootPath: tempDir.path,
            modulesTemplatePath: mockModulesURL.path
        )

        let generator = BrickGenerator()
        #expect(throws: BrickGeneratorError.self) {
            try generator.generateBrick(options: options)
        }
    }

    @Test func brickAlreadyExistsThrows() throws {
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
        let existingModuleDir = tempDir.appendingPathComponent("App/Sources/Features/Network/Service")
        try FileManager.default.createDirectory(at: existingModuleDir, withIntermediateDirectories: true)

        let options = BrickGeneratorOptions(
            type: .service,
            name: "Network",
            projectRootPath: tempDir.path,
            modulesTemplatePath: mockModulesURL.path
        )

        let generator = BrickGenerator()
        #expect(throws: BrickGeneratorError.self) {
            try generator.generateBrick(options: options)
        }
    }

    @Test func generateBrickWithNestedDirectories() throws {
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
        try "struct __MODULE_NAME__Header {}\n".write(to: componentFile, atomically: true, encoding: .utf8)

        let options = BrickGeneratorOptions(
            type: .scene,
            name: "Profile",
            projectRootPath: tempDir.path,
            modulesTemplatePath: mockModulesURL.path
        )

        let generator = BrickGenerator()
        let generatedPath = try generator.generateBrick(options: options)

        let expectedComponentPath = "\(generatedPath)/Components/ProfileHeader.swift"
        #expect(FileManager.default.fileExists(atPath: expectedComponentPath))
        let content = try String(contentsOfFile: expectedComponentPath, encoding: .utf8)
        #expect(content == "struct ProfileHeader {}\n")
    }

    @Test func generateNewBricks() throws {
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

        let types: [(Brick, String)] = [
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

            let options = BrickGeneratorOptions(
                type: type,
                name: "Sample",
                projectRootPath: tempDir.path,
                modulesTemplatePath: mockModulesURL.path
            )

            let generator = BrickGenerator()
            let generatedPath = try generator.generateBrick(options: options)
            #expect(FileManager.default.fileExists(atPath: "\(generatedPath)/SampleTest.swift"))
        }
    }

    @Test func defaultBrickGeneratorOptionsTemplatePaths() {
        let featureOpt = BrickGeneratorOptions(type: .scene, name: "Test")
        #expect(!featureOpt.modulesTemplatePath.isEmpty)

        let coreOpt = BrickGeneratorOptions(type: .network, name: "Test")
        #expect(!coreOpt.modulesTemplatePath.isEmpty)
    }

    @Test func testComposableUnitTestsGenerationForCoreAndFeatureBricks() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let config = SwiftBlockConfig(projectName: "TestApp")
        let configData = try JSONEncoder().encode(config)
        try configData.write(to: tempDir.appendingPathComponent(".swiftblock"))

        let mockCoreURL = tempDir.appendingPathComponent("MockCore")
        let mockStorageURL = mockCoreURL.appendingPathComponent("Storage")
        try FileManager.default.createDirectory(at: mockStorageURL, withIntermediateDirectories: true)
        try "// Source".write(to: mockStorageURL.appendingPathComponent("__MODULE_NAME__.swift"), atomically: true, encoding: .utf8)
        try "// Test".write(to: mockStorageURL.appendingPathComponent("__MODULE_NAME__Tests.swift"), atomically: true, encoding: .utf8)

        let coreOptions = BrickGeneratorOptions(
            type: .storage,
            name: "AppStorage",
            projectRootPath: tempDir.path,
            modulesTemplatePath: mockCoreURL.path
        )

        let generator = BrickGenerator()
        let corePath = try generator.generateBrick(options: coreOptions)

        #expect(FileManager.default.fileExists(atPath: "\(corePath)/AppStorage.swift"))
        #expect(FileManager.default.fileExists(atPath: "\(tempDir.path)/App/Tests/Core/storage/AppStorageTests.swift"))

        let mockModulesURL = tempDir.appendingPathComponent("MockModules")
        let mockSceneURL = mockModulesURL.appendingPathComponent("Scene")
        try FileManager.default.createDirectory(at: mockSceneURL, withIntermediateDirectories: true)
        try "// Source".write(to: mockSceneURL.appendingPathComponent("__MODULE_NAME__View.swift"), atomically: true, encoding: .utf8)
        try "// Test".write(to: mockSceneURL.appendingPathComponent("__MODULE_NAME__Tests.swift"), atomically: true, encoding: .utf8)

        let featureOptions = BrickGeneratorOptions(
            type: .scene,
            name: "Profile",
            projectRootPath: tempDir.path,
            modulesTemplatePath: mockModulesURL.path
        )

        let featurePath = try generator.generateBrick(options: featureOptions)
        #expect(FileManager.default.fileExists(atPath: "\(featurePath)/ProfileView.swift"))
        #expect(FileManager.default.fileExists(atPath: "\(tempDir.path)/App/Tests/Features/profile/scene/ProfileTests.swift"))
    }

    @Test func brickGenerationRollbackOnFailure() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("Rollback_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let config = SwiftBlockConfig(projectName: "TestApp")
        try config.save(to: tempDir.path)

        // Invalid options targeting non-existent template
        let options = BrickGeneratorOptions(
            type: .scene,
            name: "RollbackTest",
            projectRootPath: tempDir.path,
            modulesTemplatePath: "\(tempDir.path)/NonExistentTemplate"
        )

        let generator = BrickGenerator()
        #expect(throws: BrickGeneratorError.self) {
            try generator.generateBrick(options: options)
        }

        let targetDir = "\(tempDir.path)/App/Sources/Features/rollbacktest"
        #expect(!FileManager.default.fileExists(atPath: targetDir))
    }
}
