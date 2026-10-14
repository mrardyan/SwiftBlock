import Foundation
@testable import SwiftBlockCore
import XCTest

final class CodeInjectorTests: XCTestCase {
    func testMarkerBasedCodeInjection() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let targetFile = "\(tempDir)/DependencyContainer.swift"
        let initialContent = """
        import Foundation

        final class DependencyContainer {
            // MARK: - Register Services
            func setup() {}
        }
        """
        try initialContent.write(toFile: targetFile, atomically: true, encoding: .utf8)

        let spec = InjectionSpec(
            target: "DependencyContainer.swift",
            marker: "// MARK: - Register Services",
            content: "    let {{moduleName.lowercased()}}Service = {{moduleName}}Service()"
        )

        let injected = try CodeInjector.inject(
            spec: spec,
            variables: [:],
            projectName: "TestApp",
            moduleName: "Profile",
            projectRootPath: tempDir
        )

        XCTAssertEqual(injected, true)
        let updatedContent = try String(contentsOfFile: targetFile, encoding: .utf8)
        XCTAssertTrue(updatedContent.contains("let profileService = ProfileService()"))
    }

    func testDuplicatePrevention() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let targetFile = "\(tempDir)/AppMain.swift"
        let initialContent = """
        import SwiftUI

        struct AppMain: App {
            var body: some Scene {
                WindowGroup {
                    ProfileView()
                }
            }
        }
        """
        try initialContent.write(toFile: targetFile, atomically: true, encoding: .utf8)

        let spec = InjectionSpec(
            target: "AppMain.swift",
            marker: nil,
            content: "ProfileView()"
        )

        let injected = try CodeInjector.inject(
            spec: spec,
            variables: [:],
            projectName: "TestApp",
            moduleName: "Profile",
            projectRootPath: tempDir
        )

        XCTAssertEqual(injected, false)
    }

    func testFallbackBraceInjection() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let targetFile = "\(tempDir)/Routes.swift"
        let initialContent = """
        enum Route {
            case home
        }
        """
        try initialContent.write(toFile: targetFile, atomically: true, encoding: .utf8)

        let spec = InjectionSpec(
            target: "Routes.swift",
            marker: nil,
            content: "case profile"
        )

        let injected = try CodeInjector.inject(
            spec: spec,
            variables: [:],
            projectName: "TestApp",
            moduleName: "Profile",
            projectRootPath: tempDir
        )

        XCTAssertEqual(injected, true)
        let updatedContent = try String(contentsOfFile: targetFile, encoding: .utf8)
        XCTAssertTrue(updatedContent.contains("case profile"))
    }

    func testManifestInjectionParsing() {
        let yamlContent = """
        name: scene
        category: architecture
        instantiation: generative
        injections:
          - target: "App/Sources/AppMain.swift"
            marker: "// MARK: - Routes"
            content: "case .{{moduleName.lowercased()}}"
        """

        let manifest = BrickManifest.parseYAML(yamlContent, folderName: "scene")
        XCTAssertEqual(manifest.injections.count, 1)
        XCTAssertEqual(manifest.injections[0].target, "App/Sources/AppMain.swift")
        XCTAssertEqual(manifest.injections[0].marker, "// MARK: - Routes")
        XCTAssertEqual(manifest.injections[0].content, "case .{{moduleName.lowercased()}}")
    }

    func testDryRunInjection() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let targetFile = "\(tempDir)/Config.swift"
        let initialContent = "struct Config {}"
        try initialContent.write(toFile: targetFile, atomically: true, encoding: .utf8)

        let spec = InjectionSpec(
            target: "Config.swift",
            marker: nil,
            content: "static let timeout = 30"
        )

        let injected = try CodeInjector.inject(
            spec: spec,
            variables: [:],
            projectName: "TestApp",
            moduleName: nil,
            projectRootPath: tempDir,
            isDryRun: true
        )

        XCTAssertEqual(injected, true)
        let contentUnchanged = try String(contentsOfFile: targetFile, encoding: .utf8)
        XCTAssertEqual(contentUnchanged, initialContent)
    }

    func testPathTraversalRejection() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        let projectDir = "\(tempDir)/Project"
        try FileManager.default.createDirectory(atPath: projectDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let outsideFile = "\(tempDir)/outside.txt"
        try "sensitive content".write(toFile: outsideFile, atomically: true, encoding: .utf8)

        let spec = InjectionSpec(
            target: "../outside.txt",
            marker: nil,
            content: "injected text"
        )

        let injected = try CodeInjector.inject(
            spec: spec,
            variables: [:],
            projectName: "TestApp",
            moduleName: nil,
            projectRootPath: projectDir
        )

        XCTAssertEqual(injected, false)
        let contentUnchanged = try String(contentsOfFile: outsideFile, encoding: .utf8)
        XCTAssertEqual(contentUnchanged, "sensitive content")
    }

    func testMultipleMarkersAndNestedBraces() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let targetFile = "\(tempDir)/Nested.swift"
        let initialContent = """
        struct Outer {
            // MARK: - Section
            func first() {
                // MARK: - Section
                let x = 1
            }
        }
        """
        try initialContent.write(toFile: targetFile, atomically: true, encoding: .utf8)

        let spec = InjectionSpec(
            target: "Nested.swift",
            marker: "// MARK: - Section",
            content: "let injectedFirst = true"
        )

        let injected = try CodeInjector.inject(
            spec: spec,
            variables: [:],
            projectName: "TestApp",
            moduleName: nil,
            projectRootPath: tempDir
        )

        XCTAssertEqual(injected, true)
        let updatedContent = try String(contentsOfFile: targetFile, encoding: .utf8)
        let lines = updatedContent.components(separatedBy: "\n")
        XCTAssertTrue(lines[2].contains("let injectedFirst = true"))
    }
}
