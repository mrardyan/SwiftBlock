import Foundation
@testable import SwiftBlockCore
import XCTest

final class DoctorEngineTests: XCTestCase {
    func testToolCheck() {
        let engine = DoctorEngine()
        let result = engine.checkTool("git")
        XCTAssertEqual(result.name, "git")
        XCTAssertEqual(result.isInstalled, true)
    }

    func testGlobalContextDiagnosis() {
        let engine = DoctorEngine()
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        try? FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let report = engine.diagnose(projectRootPath: tempDir)
        XCTAssertEqual(report.isProjectFolder, false)
        XCTAssertEqual(report.manifestFound, nil)
        XCTAssertGreaterThanOrEqual(report.toolChecks.count, 5)
    }

    func testProjectFolderDiagnosis() throws {
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

        XCTAssertEqual(report.isProjectFolder, true)
        XCTAssertEqual(report.configValid, true)
        XCTAssertEqual(report.manifestFound, "Tuist (Project.swift)")
    }

    func testDependencyGraphAnalyzer() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        let sourcesDir = "\(tempDir)/App/Sources/Core"
        try FileManager.default.createDirectory(atPath: sourcesDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let placeholderFile = "\(sourcesDir)/Unused.swift"
        try "// TODO: Implementation required".write(toFile: placeholderFile, atomically: true, encoding: .utf8)

        let engine = DoctorEngine()
        let issues = engine.analyzeDependencyGraph(projectRootPath: tempDir)
        XCTAssertEqual(issues.count, 1)
        XCTAssertTrue(issues[0].filePath.contains("Unused.swift"))
    }
}
