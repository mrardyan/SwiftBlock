import Foundation
@testable import SwiftBlockCore
import XCTest

final class BrickGeneratorTests: XCTestCase {
    func testGenerateSceneBrick() throws {
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
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedViewPath))
        let content = try String(contentsOfFile: expectedViewPath, encoding: .utf8)
        XCTAssertEqual(content, "struct HomeView {}\n")
    }

    func testGenerateUseCaseBrick() throws {
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
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedPath))
    }

    func testBrickDryRunModeDoesNotWriteToDisk() throws {
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

        XCTAssertFalse(FileManager.default.fileExists(atPath: generatedPath))
    }

    func testBrickGenerationFailsWithoutConfig() {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        let options = BrickGeneratorOptions(
            type: .scene,
            name: "Home",
            projectRootPath: tempDir.path
        )

        let generator = BrickGenerator()
        XCTAssertThrowsError(try generator.generateBrick(options: options))
    }

    func testBrickGeneratorErrorDescriptions() {
        let err1 = BrickGeneratorError.templateNotFound("/path/1")
        XCTAssertEqual(err1.errorDescription, "Brick template not found at /path/1")

        let err2 = BrickGeneratorError.brickAlreadyExists("/path/2")
        XCTAssertEqual(err2.errorDescription, "Brick already exists at /path/2")

        let err3 = BrickGeneratorError.generationFailed("Failed")
        XCTAssertEqual(err3.errorDescription, "Failed to generate brick: Failed")

        let configErr = SwiftBlockConfigError.configNotFound("/path/3")
        XCTAssertEqual(configErr.errorDescription, "Not a valid SwiftBlock project root (.swiftblock not found at /path/3)")
    }

    func testBrickTemplateNotFoundThrows() throws {
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
        XCTAssertThrowsError(try generator.generateBrick(options: options))
    }

    func testBrickAlreadyExistsThrows() throws {
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
        XCTAssertThrowsError(try generator.generateBrick(options: options))
    }

    func testGenerateBrickWithNestedDirectories() throws {
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
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedComponentPath))
        let content = try String(contentsOfFile: expectedComponentPath, encoding: .utf8)
        XCTAssertEqual(content, "struct ProfileHeader {}\n")
    }

    func testGenerateNewBricks() throws {
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
            (.analytics, "Analytics"),
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
            XCTAssertTrue(FileManager.default.fileExists(atPath: "\(generatedPath)/SampleTest.swift"))
        }
    }

    func testDefaultBrickGeneratorOptionsTemplatePaths() {
        let featureOpt = BrickGeneratorOptions(type: .scene, name: "Test")
        XCTAssertFalse(featureOpt.modulesTemplatePath.isEmpty)

        let coreOpt = BrickGeneratorOptions(type: .network, name: "Test")
        XCTAssertFalse(coreOpt.modulesTemplatePath.isEmpty)
    }

    func testComposableUnitTestsGenerationForCoreAndFeatureBricks() throws {
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

        XCTAssertTrue(FileManager.default.fileExists(atPath: "\(corePath)/AppStorage.swift"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: "\(tempDir.path)/App/Tests/Core/storage/AppStorageTests.swift"))

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
        XCTAssertTrue(FileManager.default.fileExists(atPath: "\(featurePath)/ProfileView.swift"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: "\(tempDir.path)/App/Tests/Features/profile/scene/ProfileTests.swift"))
    }

    func testBrickGenerationRollbackOnFailure() throws {
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
        XCTAssertThrowsError(try generator.generateBrick(options: options))

        let targetDir = "\(tempDir.path)/App/Sources/Features/rollbacktest"
        XCTAssertFalse(FileManager.default.fileExists(atPath: targetDir))
    }

    func testManifestDefaultPathHonoredForCustomBrick() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("CustomBrick_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let config = SwiftBlockConfig(projectName: "TestApp")
        try config.save(to: tempDir.path)

        let customBrick = tempDir.appendingPathComponent("Widget", isDirectory: true)
        try FileManager.default.createDirectory(at: customBrick, withIntermediateDirectories: true)
        let manifest = """
        name: widget
        instantiation: singleton
        defaultPath: "App/Sources/Core/Widgets/{block}"
        """
        try manifest.write(toFile: customBrick.appendingPathComponent("brick.yml").path, atomically: true, encoding: .utf8)
        try "public struct Widget {}\n".write(toFile: customBrick.appendingPathComponent("__MODULE_NAME__.swift").path, atomically: true, encoding: .utf8)

        let options = BrickGeneratorOptions(
            type: Brick(rawValue: "widget"),
            name: "Widget",
            projectRootPath: tempDir.path,
            modulesTemplatePath: customBrick.path
        )

        let generator = BrickGenerator()
        let generatedPath = try generator.generateBrick(options: options)

        XCTAssertTrue(FileManager.default.fileExists(atPath: "\(generatedPath)/Widget.swift"))
        XCTAssertTrue(generatedPath.hasSuffix("App/Sources/Core/Widgets/widget"))
    }

    func testBaseplateMismatchThrows() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("BaseplateMismatch_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        // Vapor (SPM) project config
        let vaporConfig = SwiftBlockConfig(projectName: "VaporApp", generatorTool: .spm)
        try vaporConfig.save(to: tempDir.path)

        let authBrick = tempDir.appendingPathComponent("Auth", isDirectory: true)
        try FileManager.default.createDirectory(at: authBrick, withIntermediateDirectories: true)
        let manifest = """
        name: auth
        instantiation: singleton
        baseplates:
          - swiftui
        """
        try manifest.write(toFile: authBrick.appendingPathComponent("brick.yml").path, atomically: true, encoding: .utf8)
        try "// Auth".write(toFile: authBrick.appendingPathComponent("__MODULE_NAME__.swift").path, atomically: true, encoding: .utf8)

        let options = BrickGeneratorOptions(
            type: .auth,
            name: "UserAuth",
            projectRootPath: tempDir.path,
            modulesTemplatePath: authBrick.path
        )

        let generator = BrickGenerator()
        XCTAssertThrowsError(try generator.generateBrick(options: options))
    }

    func testDiscoveredCoreBrickSnapsToCorePath() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("DiscoveredCore_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let config = SwiftBlockConfig(projectName: "TestApp")
        try config.save(to: tempDir.path)

        // `cache` is auto-discovered (not curated): its manifest category drives categorization.
        XCTAssertEqual(Brick(rawValue: "cache").category, .core)

        let templateRoot = tempDir.appendingPathComponent("Templates", isDirectory: true)
        let cacheTemplate = templateRoot.appendingPathComponent("Cache", isDirectory: true)
        try FileManager.default.createDirectory(at: cacheTemplate, withIntermediateDirectories: true)
        let manifest = """
        name: cache
        category: infrastructure
        instantiation: singleton
        defaultPath: "App/Sources/Core/Cache"
        """
        try manifest.write(toFile: cacheTemplate.appendingPathComponent("brick.yml").path, atomically: true, encoding: .utf8)
        try "// Cache".write(toFile: cacheTemplate.appendingPathComponent("__MODULE_NAME__.swift").path, atomically: true, encoding: .utf8)

        let options = BrickGeneratorOptions(
            type: Brick(rawValue: "cache"),
            name: "Cache",
            projectRootPath: tempDir.path,
            modulesTemplatePath: templateRoot.path
        )

        let generator = BrickGenerator()
        let generatedPath = try generator.generateBrick(options: options)
        XCTAssertTrue(generatedPath.hasSuffix("App/Sources/Core/Cache"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: "\(generatedPath)/Cache.swift"))
    }

    func testVaporProjectPlacesTestsUnderAppTests() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("VaporTests_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let vaporConfig = SwiftBlockConfig(projectName: "VaporApp", generatorTool: .spm, testFramework: .xctest)
        try vaporConfig.save(to: tempDir.path)

        let sceneTemplate = tempDir.appendingPathComponent("Scene", isDirectory: true)
        try FileManager.default.createDirectory(at: sceneTemplate, withIntermediateDirectories: true)
        try "// Scene".write(toFile: sceneTemplate.appendingPathComponent("__MODULE_NAME__View.swift").path, atomically: true, encoding: .utf8)
        try "import XCTest\n@testable import __APP_MODULE__\n".write(
            toFile: sceneTemplate.appendingPathComponent("__MODULE_NAME__Tests.swift").path,
            atomically: true,
            encoding: .utf8
        )

        let options = BrickGeneratorOptions(
            type: .scene,
            name: "Order",
            projectRootPath: tempDir.path,
            modulesTemplatePath: tempDir.path
        )

        let generator = BrickGenerator()
        try generator.generateBrick(options: options)

        let vaporTestPath = "\(tempDir.path)/Tests/AppTests/Features/order/scene/OrderTests.swift"
        XCTAssertTrue(FileManager.default.fileExists(atPath: vaporTestPath))
        let content = try String(contentsOfFile: vaporTestPath, encoding: .utf8)
        XCTAssertTrue(content.contains("@testable import App"))
    }
}
