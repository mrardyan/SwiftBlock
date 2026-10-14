import Foundation
@testable import SwiftBlockCore
import XCTest

final class ProjectGeneratorTests: XCTestCase {
    func testPlaceholderReplacement() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let sampleFile = tempDir.appendingPathComponent("Sample.swift")
        let content = """
        // Project __PROJECT_NAME__
        struct __PROJECT_NAME__App: App {}
        let bundle = "__BUNDLE_PREFIX__.__PROJECT_NAME__"
        """
        try content.write(to: sampleFile, atomically: true, encoding: .utf8)

        let generator = ProjectGenerator()
        try generator.replacePlaceholders(
            in: tempDir.path,
            projectName: "MyAwesomeApp",
            bundlePrefix: "com.example"
        )

        let updatedContent = try String(contentsOf: sampleFile, encoding: .utf8)
        XCTAssertTrue(updatedContent.contains("MyAwesomeApp"))
        XCTAssertTrue(updatedContent.contains("com.example.MyAwesomeApp"))
        XCTAssertFalse(updatedContent.contains("__PROJECT_NAME__"))
        XCTAssertFalse(updatedContent.contains("__BUNDLE_PREFIX__"))
    }

    func testFolderNamePlaceholderReplacement() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let subFolder = tempDir.appendingPathComponent("__PROJECT_NAME__Tests")
        try FileManager.default.createDirectory(at: subFolder, withIntermediateDirectories: true)
        let sampleFile = subFolder.appendingPathComponent("__PROJECT_NAME__Tests.swift")
        try "class __PROJECT_NAME__Tests {}".write(to: sampleFile, atomically: true, encoding: .utf8)

        let generator = ProjectGenerator()
        try generator.renamePaths(in: tempDir.path, projectName: "FooApp", bundlePrefix: "com.foo")

        let expectedSubFolder = tempDir.appendingPathComponent("FooAppTests")
        let expectedFile = expectedSubFolder.appendingPathComponent("FooAppTests.swift")

        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedSubFolder.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: expectedFile.path))
    }

    func testDryRunModeDoesNotWriteToDisk() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let mockTemplateURL = tempDir.appendingPathComponent("MockTemplate")
        try FileManager.default.createDirectory(at: mockTemplateURL, withIntermediateDirectories: true)

        let outputURL = tempDir.appendingPathComponent("DryRunApp")
        let options = ProjectGeneratorOptions(
            projectName: "DryRunApp",
            templatePath: mockTemplateURL.path,
            outputPath: outputURL.path,
            isDryRun: true
        )

        let generator = ProjectGenerator()
        try generator.generateProject(options: options)

        XCTAssertFalse(FileManager.default.fileExists(atPath: outputURL.path))
    }

    func testTemplateNotFoundThrowsError() {
        let generator = ProjectGenerator()
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        let options = ProjectGeneratorOptions(
            projectName: "TestApp",
            templatePath: "/path/that/does/not/exist/templates",
            outputPath: tempDir.appendingPathComponent("TestApp").path
        )

        XCTAssertThrowsError(try generator.generateProject(options: options))
    }

    func testSuccessfulGeneration() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let mockTemplateURL = tempDir.appendingPathComponent("MockTemplate")
        try FileManager.default.createDirectory(at: mockTemplateURL, withIntermediateDirectories: true)

        let templateMainFile = mockTemplateURL.appendingPathComponent("Main.swift")
        let templateContent = "struct __PROJECT_NAME__App {}\n"
        try templateContent.write(to: templateMainFile, atomically: true, encoding: .utf8)

        let outputURL = tempDir.appendingPathComponent("GeneratedApp")
        let options = ProjectGeneratorOptions(
            projectName: "GeneratedApp",
            bundlePrefix: "com.mycompany",
            templatePath: mockTemplateURL.path,
            outputPath: outputURL.path
        )

        let generator = ProjectGenerator()
        try generator.generateProject(options: options)

        let generatedFileExists = FileManager.default.fileExists(atPath: outputURL.appendingPathComponent("Main.swift").path)
        XCTAssertTrue(generatedFileExists)

        let generatedContent = try String(contentsOfFile: outputURL.appendingPathComponent("Main.swift").path, encoding: .utf8)
        XCTAssertEqual(generatedContent, "struct GeneratedAppApp {}\n")
    }

    func testProjectGeneratorErrorDescriptions() {
        let err1 = ProjectGeneratorError.templateNotFound("/path/to/template")
        XCTAssertEqual(err1.errorDescription, "Template not found at /path/to/template")

        let err2 = ProjectGeneratorError.destinationAlreadyExists("/path/to/dest")
        XCTAssertEqual(
            err2.errorDescription,
            "Directory already exists at /path/to/dest. Please specify a different project name or remove the existing folder."
        )

        let err3 = ProjectGeneratorError.generationFailed("Disk full")
        XCTAssertEqual(err3.errorDescription, "Failed to generate project: Disk full")
    }

    func testDestinationAlreadyExistsThrowsErrorAndPreservesDirectory() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let mockTemplateURL = tempDir.appendingPathComponent("MockTemplate")
        try FileManager.default.createDirectory(at: mockTemplateURL, withIntermediateDirectories: true)

        let existingFolderURL = tempDir.appendingPathComponent("ExistingApp")
        try FileManager.default.createDirectory(at: existingFolderURL, withIntermediateDirectories: true)
        let dummyFile = existingFolderURL.appendingPathComponent("ImportantUserFile.txt")
        try "do not delete".write(to: dummyFile, atomically: true, encoding: .utf8)

        let options = ProjectGeneratorOptions(
            projectName: "ExistingApp",
            templatePath: mockTemplateURL.path,
            outputPath: existingFolderURL.path
        )

        let generator = ProjectGenerator()

        XCTAssertThrowsError(try generator.generateProject(options: options))

        XCTAssertTrue(FileManager.default.fileExists(atPath: existingFolderURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: dummyFile.path))
    }

    func testReplacePlaceholdersIgnoresUnsupportedFiles() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let binFile = tempDir.appendingPathComponent("image.png")
        let rawBytes = Data([0x89, 0x50, 0x4E, 0x47])
        try rawBytes.write(to: binFile)

        let generator = ProjectGenerator()
        try generator.replacePlaceholders(
            in: tempDir.path,
            projectName: "MyAwesomeApp",
            bundlePrefix: "com.example"
        )

        let contentAfter = try Data(contentsOf: binFile)
        XCTAssertEqual(contentAfter, rawBytes)
    }

    func testCoreSwiftExecutableInjections() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let config = SwiftBlockConfig(
            projectName: "CoreTestApp",
            coreBlocks: [.storage, .logger, .config]
        )

        let pkgGen = LocalPackageGenerator()
        try pkgGen.generateCorePackage(in: tempDir.path, config: config)

        let coreSwiftFile = tempDir.appendingPathComponent("Packages/Core/Sources/Core/Core.swift").path
        XCTAssertTrue(FileManager.default.fileExists(atPath: coreSwiftFile))

        let content = try String(contentsOfFile: coreSwiftFile, encoding: .utf8)
        XCTAssertTrue(content.contains("AppStorage()"))
        XCTAssertTrue(content.contains("AppLogger()"))
        XCTAssertTrue(content.contains("AppConfig()"))
    }

    func testGenerateVaporBaseplate() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let localVaporDir = "\(FileManager.default.currentDirectoryPath)/Baseplates/Vapor"
        guard FileManager.default.fileExists(atPath: localVaporDir) else {
            return
        }

        let outputURL = tempDir.appendingPathComponent("MyVaporServer")
        let options = ProjectGeneratorOptions(
            projectName: "MyVaporServer",
            bundlePrefix: "com.company.vapor",
            templatePath: localVaporDir,
            outputPath: outputURL.path,
            baseplateName: "vapor"
        )

        let generator = ProjectGenerator()
        try generator.generateProject(options: options)

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.appendingPathComponent("Package.swift").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.appendingPathComponent("Dockerfile").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.appendingPathComponent("docker-compose.yml").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.appendingPathComponent("Sources/App/entrypoint.swift").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.appendingPathComponent("Sources/App/Controllers/HealthController.swift").path))

        let packageContent = try String(contentsOfFile: outputURL.appendingPathComponent("Package.swift").path, encoding: .utf8)
        XCTAssertTrue(packageContent.contains("MyVaporServer"))
        XCTAssertFalse(packageContent.contains("__PROJECT_NAME__"))

        let healthContent = try String(contentsOfFile: outputURL.appendingPathComponent("Sources/App/Controllers/HealthController.swift").path, encoding: .utf8)
        XCTAssertTrue(healthContent.contains("MyVaporServer"))
        XCTAssertFalse(healthContent.contains("__PROJECT_NAME__"))
    }
}
