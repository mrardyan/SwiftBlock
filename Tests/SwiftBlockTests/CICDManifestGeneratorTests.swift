import Foundation
import Testing
@testable import SwiftBlockCore

struct CICDManifestGeneratorTests {

    @Test func generateGitHubActions() throws {
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
        #expect(FileManager.default.fileExists(atPath: workflow.path))

        let content = try String(contentsOf: workflow, encoding: .utf8)
        #expect(content.contains("name: CI"))
        #expect(content.contains("xcodebuild test"))
    }

    @Test func generateGitLabCI() throws {
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
        #expect(FileManager.default.fileExists(atPath: workflow.path))

        let content = try String(contentsOf: workflow, encoding: .utf8)
        #expect(content.contains("stages:"))
        #expect(content.contains("xcodebuild test"))
    }

    @Test func generateXcodeCloud() throws {
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
        #expect(FileManager.default.fileExists(atPath: script.path))

        let content = try String(contentsOf: script, encoding: .utf8)
        #expect(content.contains("#!/usr/bin/env bash"))
        #expect(content.contains("mise install"))
    }
}
