import Foundation
import Testing
@testable import SwiftBlockCore

struct CodeInjectorTests {
    @Test func markerBasedCodeInjection() throws {
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

        #expect(injected == true)
        let updatedContent = try String(contentsOfFile: targetFile, encoding: .utf8)
        #expect(updatedContent.contains("let profileService = ProfileService()"))
    }

    @Test func duplicatePrevention() throws {
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

        #expect(injected == false)
    }

    @Test func fallbackBraceInjection() throws {
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

        #expect(injected == true)
        let updatedContent = try String(contentsOfFile: targetFile, encoding: .utf8)
        #expect(updatedContent.contains("case profile"))
    }

    @Test func manifestInjectionParsing() {
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
        #expect(manifest.injections.count == 1)
        #expect(manifest.injections[0].target == "App/Sources/AppMain.swift")
        #expect(manifest.injections[0].marker == "// MARK: - Routes")
        #expect(manifest.injections[0].content == "case .{{moduleName.lowercased()}}")
    }

    @Test func dryRunInjection() throws {
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

        #expect(injected == true)
        let contentUnchanged = try String(contentsOfFile: targetFile, encoding: .utf8)
        #expect(contentUnchanged == initialContent)
    }

    @Test func pathTraversalRejection() throws {
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

        #expect(injected == false)
        let contentUnchanged = try String(contentsOfFile: outsideFile, encoding: .utf8)
        #expect(contentUnchanged == "sensitive content")
    }
}
