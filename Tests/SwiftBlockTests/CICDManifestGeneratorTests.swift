import Foundation
@testable import SwiftBlockCore
import XCTest

final class CICDManifestGeneratorTests: XCTestCase {
    func testGenerateGitHubActions() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let config = SwiftBlockConfig(
            projectName: "CICDApp",
            bundlePrefix: "com.test",
            cicd: CICDConfig(provider: .githubActions)
        )

        let generator = CICDManifestGenerator()
        try generator.generateCICDPipeline(in: tempDir.path, config: config)

        let workflow = tempDir.appendingPathComponent(".github/workflows/ci.yml")
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflow.path))

        let content = try String(contentsOf: workflow, encoding: .utf8)
        XCTAssertTrue(content.contains("name: CI"))
        XCTAssertTrue(content.contains("xcodebuild test"))
    }

    func testGenerateGitLabCI() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let config = SwiftBlockConfig(
            projectName: "GitLabApp",
            bundlePrefix: "com.test",
            cicd: CICDConfig(provider: .gitlabCI)
        )

        let generator = CICDManifestGenerator()
        try generator.generateCICDPipeline(in: tempDir.path, config: config)

        let workflow = tempDir.appendingPathComponent(".gitlab-ci.yml")
        XCTAssertTrue(FileManager.default.fileExists(atPath: workflow.path))

        let content = try String(contentsOf: workflow, encoding: .utf8)
        XCTAssertTrue(content.contains("stages:"))
        XCTAssertTrue(content.contains("xcodebuild test"))
    }

    func testGenerateXcodeCloud() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let config = SwiftBlockConfig(
            projectName: "XcodeCloudApp",
            bundlePrefix: "com.test",
            cicd: CICDConfig(provider: .xcodeCloud)
        )

        let generator = CICDManifestGenerator()
        try generator.generateCICDPipeline(in: tempDir.path, config: config)

        let script = tempDir.appendingPathComponent("ci_scripts/ci_post_clone.sh")
        XCTAssertTrue(FileManager.default.fileExists(atPath: script.path))

        let content = try String(contentsOf: script, encoding: .utf8)
        XCTAssertTrue(content.contains("#!/usr/bin/env bash"))
        XCTAssertTrue(content.contains("mise install"))
    }
}
