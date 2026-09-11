import Foundation
import Testing
@testable import SwiftBlockCore

struct DoctorEngineTests {
    @Test func toolCheck() {
        let engine = DoctorEngine()
        let result = engine.checkTool("git")
        #expect(result.name == "git")
        #expect(result.isInstalled == true)
    }

    @Test func globalContextDiagnosis() {
        let engine = DoctorEngine()
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        try? FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let report = engine.diagnose(projectRootPath: tempDir)
        #expect(report.isProjectFolder == false)
        #expect(report.manifestFound == nil)
        #expect(report.toolChecks.count >= 5)
    }

    @Test func projectFolderDiagnosis() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        try FileManager.default.createDirectory(atPath: "\(tempDir)/.swiftblock", withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let configContent = """
        projectName: DoctorApp
        bundlePrefix: com.doctor
        generatorTool: tuist
        """
        try configContent.write(toFile: "\(tempDir)/.swiftblock/config.yml", atomically: true, encoding: .utf8)
        try "import ProjectDescription".write(toFile: "\(tempDir)/Project.swift", atomically: true, encoding: .utf8)

        let engine = DoctorEngine()
        let report = engine.diagnose(projectRootPath: tempDir)

        #expect(report.isProjectFolder == true)
        #expect(report.configValid == true)
        #expect(report.manifestFound == "Tuist (Project.swift)")
    }

    @Test func dependencyGraphAnalyzer() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        let sourcesDir = "\(tempDir)/App/Sources/Core"
        try FileManager.default.createDirectory(atPath: sourcesDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let placeholderFile = "\(sourcesDir)/Unused.swift"
        try "// TODO: Implementation required".write(toFile: placeholderFile, atomically: true, encoding: .utf8)

        let engine = DoctorEngine()
        let issues = engine.analyzeDependencyGraph(projectRootPath: tempDir)
        #expect(issues.count == 1)
        #expect(issues[0].filePath.contains("Unused.swift"))
    }
}
