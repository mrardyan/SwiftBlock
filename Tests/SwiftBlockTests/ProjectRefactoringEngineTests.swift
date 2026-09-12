import Foundation
import Testing
@testable import SwiftBlockCore

struct ProjectRefactoringEngineTests {

    @Test func renameTuistProject() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RenameTuist_\(UUID().uuidString)", isDirectory: true).path
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        // Setup mock project
        let config = SwiftBlockConfig(projectName: "OldAppName", bundlePrefix: "com.test", generatorTool: .tuist)
        try config.save(to: tempDir)

        let projectSwift = """
        import ProjectDescription

        let project = Project(
            name: "OldAppName",
            targets: [
                .target(name: "OldAppName", bundleId: "com.test.OldAppName")
            ]
        )
        """
        try projectSwift.write(toFile: "\(tempDir)/Project.swift", atomically: true, encoding: .utf8)

        let appDir = "\(tempDir)/App/Sources"
        let testDir = "\(tempDir)/App/Tests"
        try FileManager.default.createDirectory(atPath: appDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(atPath: testDir, withIntermediateDirectories: true)

        let mainApp = """
        import SwiftUI

        @main
        struct OldAppNameApp: App {
            var body: some Scene {
                WindowGroup {
                    ContentView()
                }
            }
        }
        """
        try mainApp.write(toFile: "\(appDir)/Main.swift", atomically: true, encoding: .utf8)

        let oldTest = """
        import Testing
        @testable import OldAppName

        struct OldAppNameTests {
            @Test func sample() {}
        }
        """
        try oldTest.write(toFile: "\(testDir)/OldAppNameTests.swift", atomically: true, encoding: .utf8)

        // Execute refactoring
        let engine = ProjectRefactoringEngine()
        let result = try engine.renameProject(projectPath: tempDir, newName: "NewSuperApp")

        #expect(result.oldName == "OldAppName")
        #expect(result.newName == "NewSuperApp")

        // Verify config
        let updatedConfig = try SwiftBlockConfig.load(from: tempDir)
        #expect(updatedConfig.projectName == "NewSuperApp")

        // Verify Project.swift
        let updatedManifest = try String(contentsOfFile: "\(tempDir)/Project.swift", encoding: .utf8)
        #expect(updatedManifest.contains("name: \"NewSuperApp\""))
        #expect(updatedManifest.contains("bundleId: \"com.test.NewSuperApp\""))

        // Verify Main.swift
        let updatedMain = try String(contentsOfFile: "\(appDir)/Main.swift", encoding: .utf8)
        #expect(updatedMain.contains("struct NewSuperAppApp: App"))

        // Verify renamed test file
        let newTestFile = "\(testDir)/NewSuperAppTests.swift"
        #expect(FileManager.default.fileExists(atPath: newTestFile))
        let updatedTestContent = try String(contentsOfFile: newTestFile, encoding: .utf8)
        #expect(updatedTestContent.contains("@testable import NewSuperApp"))
        #expect(updatedTestContent.contains("struct NewSuperAppTests"))
    }

    @Test func renameDryRunMode() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RenameDryRun_\(UUID().uuidString)", isDirectory: true).path
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let config = SwiftBlockConfig(projectName: "AppOne", bundlePrefix: "com.test")
        try config.save(to: tempDir)

        let engine = ProjectRefactoringEngine()
        let result = try engine.renameProject(projectPath: tempDir, newName: "AppTwo", isDryRun: true)

        #expect(result.isDryRun == true)
        #expect(result.oldName == "AppOne")
        #expect(result.newName == "AppTwo")

        let configUnchanged = try SwiftBlockConfig.load(from: tempDir)
        #expect(configUnchanged.projectName == "AppOne")
    }

    @Test func renameInvalidNameThrowsError() throws {
        let engine = ProjectRefactoringEngine()
        #expect(throws: ProjectRefactoringError.self) {
            try engine.renameProject(newName: "123 Invalid Name!")
        }
    }

    @Test func renameFromSubdirectoryFallback() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RenameSubdir_\(UUID().uuidString)", isDirectory: true).path
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let config = SwiftBlockConfig(projectName: "NestedApp", bundlePrefix: "com.test")
        try config.save(to: tempDir)

        let subDir = "\(tempDir)/App/Sources/Features/Home"
        try FileManager.default.createDirectory(atPath: subDir, withIntermediateDirectories: true)

        let engine = ProjectRefactoringEngine()
        let result = try engine.renameProject(projectPath: subDir, newName: "RenamedNestedApp")

        #expect(result.oldName == "NestedApp")
        #expect(result.newName == "RenamedNestedApp")

        let updatedConfig = try SwiftBlockConfig.load(from: tempDir)
        #expect(updatedConfig.projectName == "RenamedNestedApp")
    }
}
