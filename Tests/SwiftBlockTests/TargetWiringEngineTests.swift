import XCTest
@testable import SwiftBlockCore

final class TargetWiringEngineTests: XCTestCase {
    var fileManager: FileManager!
    var tempDirectoryURL: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        fileManager = FileManager.default
        tempDirectoryURL = fileManager.temporaryDirectory.appendingPathComponent("TargetWiring_\(UUID().uuidString)")
        try fileManager.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if fileManager.fileExists(atPath: tempDirectoryURL.path) {
            try? fileManager.removeItem(at: tempDirectoryURL)
        }
        try super.tearDownWithError()
    }

    func testTuistTargetWiring() throws {
        let manifestPath = tempDirectoryURL.appendingPathComponent("Project.swift").path
        let initialManifest = """
        import ProjectDescription

        let project = Project(
            name: "TestApp",
            targets: [
                Target.target(name: "App")
            ]
        )
        """
        try initialManifest.write(toFile: manifestPath, atomically: true, encoding: .utf8)

        let engine = ProjectTargetWiringEngine(fileManager: fileManager)
        let wired = try engine.wireFeatureTarget(moduleName: "Profile", projectPath: tempDirectoryURL.path)

        XCTAssertTrue(wired)
        let updatedContent = try String(contentsOfFile: manifestPath, encoding: .utf8)
        XCTAssertTrue(updatedContent.contains("Target.target("))
        XCTAssertTrue(updatedContent.contains("name: \"Profile\""))
        XCTAssertTrue(updatedContent.contains("sources: [\"App/Sources/Features/Profile/**\"]"))
    }

    func testXcodeGenTargetWiring() throws {
        let manifestPath = tempDirectoryURL.appendingPathComponent("project.yml").path
        let initialManifest = """
        name: TestApp
        targets:
          App:
            type: application
        """
        try initialManifest.write(toFile: manifestPath, atomically: true, encoding: .utf8)

        let engine = ProjectTargetWiringEngine(fileManager: fileManager)
        let wired = try engine.wireFeatureTarget(moduleName: "Checkout", projectPath: tempDirectoryURL.path)

        XCTAssertTrue(wired)
        let updatedContent = try String(contentsOfFile: manifestPath, encoding: .utf8)
        XCTAssertTrue(updatedContent.contains("Checkout:"))
        XCTAssertTrue(updatedContent.contains("path: App/Sources/Features/Checkout"))
    }

    func testDuplicateTargetWiringSkipped() throws {
        let manifestPath = tempDirectoryURL.appendingPathComponent("Project.swift").path
        let initialManifest = """
        import ProjectDescription

        let project = Project(
            name: "TestApp",
            targets: [
                Target.target(name: "Profile")
            ]
        )
        """
        try initialManifest.write(toFile: manifestPath, atomically: true, encoding: .utf8)

        let engine = ProjectTargetWiringEngine(fileManager: fileManager)
        let wired = try engine.wireFeatureTarget(moduleName: "Profile", projectPath: tempDirectoryURL.path)

        XCTAssertFalse(wired)
    }

    func testStructuralScopeCodeInjection() throws {
        let targetFilePath = tempDirectoryURL.appendingPathComponent("AppCoordinator.swift").path
        let fileContent = """
        import Foundation

        final class AppCoordinator {
            func registerDependencies() {
                // Initial setup
            }
        }
        """
        try fileContent.write(toFile: targetFilePath, atomically: true, encoding: .utf8)

        let spec = InjectionSpec(
            target: "AppCoordinator.swift",
            scope: "func registerDependencies()",
            content: "container.register(ProfileViewModel.self)"
        )

        let injected = try CodeInjector.inject(
            spec: spec,
            projectRootPath: tempDirectoryURL.path
        )

        XCTAssertTrue(injected)
        let result = try String(contentsOfFile: targetFilePath, encoding: .utf8)
        XCTAssertTrue(result.contains("container.register(ProfileViewModel.self)"))
    }
}
