import Foundation
import Testing
@testable import IOSGenCore

struct ProjectGeneratorTests {

    @Test func placeholderReplacement() throws {
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
        #expect(updatedContent.contains("MyAwesomeApp"))
        #expect(updatedContent.contains("com.example.MyAwesomeApp"))
        #expect(!updatedContent.contains("__PROJECT_NAME__"))
        #expect(!updatedContent.contains("__BUNDLE_PREFIX__"))
    }

    @Test func templateNotFoundThrowsError() {
        let generator = ProjectGenerator()
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        let options = ProjectGeneratorOptions(
            projectName: "TestApp",
            templatePath: "/path/that/does/not/exist/templates",
            outputPath: tempDir.appendingPathComponent("TestApp").path
        )

        #expect(throws: ProjectGeneratorError.self) {
            try generator.generateProject(options: options)
        }
    }

    @Test func successfulGeneration() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        // Create mock template folder
        let mockTemplateURL = tempDir.appendingPathComponent("MockTemplate")
        try FileManager.default.createDirectory(at: mockTemplateURL, withIntermediateDirectories: true)

        let templateMainFile = mockTemplateURL.appendingPathComponent("Main.swift")
        let templateContent = "struct __PROJECT_NAME__App {}"
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
        #expect(generatedFileExists)

        let generatedContent = try String(contentsOf: outputURL.appendingPathComponent("Main.swift"), encoding: .utf8)
        #expect(generatedContent == "struct GeneratedAppApp {}")
    }
}
