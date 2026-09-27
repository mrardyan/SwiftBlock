import Foundation
@testable import SwiftBlockCore
import XCTest

final class ProjectRefactoringEngineTests: XCTestCase {
    func testRenameTuistProject() throws {
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
            func testSample() {}
        }
        """
        try oldTest.write(toFile: "\(testDir)/OldAppNameTests.swift", atomically: true, encoding: .utf8)

        // Execute refactoring
        let engine = ProjectRefactoringEngine()
        let result = try engine.renameProject(projectPath: tempDir, newName: "NewSuperApp")

        XCTAssertEqual(result.oldName, "OldAppName")
        XCTAssertEqual(result.newName, "NewSuperApp")

        // Verify config
        let updatedConfig = try SwiftBlockConfig.load(from: tempDir)
        XCTAssertEqual(updatedConfig.projectName, "NewSuperApp")

        // Verify Project.swift
        let updatedManifest = try String(contentsOfFile: "\(tempDir)/Project.swift", encoding: .utf8)
        XCTAssertTrue(updatedManifest.contains("name: \"NewSuperApp\""))
        XCTAssertTrue(updatedManifest.contains("bundleId: \"com.test.NewSuperApp\""))

        // Verify Main.swift
        let updatedMain = try String(contentsOfFile: "\(appDir)/Main.swift", encoding: .utf8)
        XCTAssertTrue(updatedMain.contains("struct NewSuperAppApp: App"))

        // Verify renamed test file
        let newTestFile = "\(testDir)/NewSuperAppTests.swift"
        XCTAssertTrue(FileManager.default.fileExists(atPath: newTestFile))
        let updatedTestContent = try String(contentsOfFile: newTestFile, encoding: .utf8)
        XCTAssertTrue(updatedTestContent.contains("@testable import NewSuperApp"))
        XCTAssertTrue(updatedTestContent.contains("struct NewSuperAppTests"))
    }

    func testRenameDryRunMode() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("RenameDryRun_\(UUID().uuidString)", isDirectory: true).path
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let config = SwiftBlockConfig(projectName: "AppOne", bundlePrefix: "com.test")
        try config.save(to: tempDir)

        let engine = ProjectRefactoringEngine()
        let result = try engine.renameProject(projectPath: tempDir, newName: "AppTwo", isDryRun: true)

        XCTAssertEqual(result.isDryRun, true)
        XCTAssertEqual(result.oldName, "AppOne")
        XCTAssertEqual(result.newName, "AppTwo")

        let configUnchanged = try SwiftBlockConfig.load(from: tempDir)
        XCTAssertEqual(configUnchanged.projectName, "AppOne")
    }

    func testRenameInvalidNameThrowsError() throws {
        let engine = ProjectRefactoringEngine()
        XCTAssertThrowsError(try engine.renameProject(newName: "123 Invalid Name!"))
    }

    func testRenameFromSubdirectoryFallback() throws {
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

        XCTAssertEqual(result.oldName, "NestedApp")
        XCTAssertEqual(result.newName, "RenamedNestedApp")

        let updatedConfig = try SwiftBlockConfig.load(from: tempDir)
        XCTAssertEqual(updatedConfig.projectName, "RenamedNestedApp")
    }
}
