import Foundation
import Testing
@testable import SwiftBlockCore

struct BoxPublisherTests {

    @Test func validateValidBrickManifest() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("BoxPubVal_\(UUID().uuidString)", isDirectory: true).path
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let manifest = """
        name: analytics
        instantiation: singleton
        description: Telemetry Analytics Brick
        injections:
          - target: "App/Sources/AppDelegate.swift"
            marker: "// MARK: - Setup"
            content: "Analytics.configure()"
        """
        try manifest.write(toFile: "\(tempDir)/brick.yml", atomically: true, encoding: .utf8)

        let publisher = BoxPublisher()
        let report = try publisher.validateBox(at: tempDir)

        #expect(report.isValid == true)
        #expect(report.errors.isEmpty)
        #expect(report.manifest?.name == "analytics")
    }

    @Test func validateInvalidBrickManifestMissingFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("BoxPubInvalid_\(UUID().uuidString)", isDirectory: true).path
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let publisher = BoxPublisher()
        let report = try publisher.validateBox(at: tempDir)

        #expect(report.isValid == false)
        #expect(report.errors.count == 1)
        #expect(report.errors[0].contains("No valid brick.yml"))
    }

    @Test func publishDryRunMode() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("BoxPubDryRun_\(UUID().uuidString)", isDirectory: true).path
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        // Create git directory marker
        try FileManager.default.createDirectory(atPath: "\(tempDir)/.git", withIntermediateDirectories: true)

        let manifest = """
        name: storage
        instantiation: singleton
        description: Local Store Brick
        """
        try manifest.write(toFile: "\(tempDir)/brick.yml", atomically: true, encoding: .utf8)

        let publisher = BoxPublisher()
        let result = try publisher.publishBox(at: tempDir, tag: "1.2.0", remote: "origin", isDryRun: true)

        #expect(result.boxName == "storage")
        #expect(result.tag == "v1.2.0")
        #expect(result.isDryRun == true)
    }

    @Test func publishFailsOutsideGitRepository() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("BoxPubNoGit_\(UUID().uuidString)", isDirectory: true).path
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let manifest = """
        name: network
        instantiation: singleton
        """
        try manifest.write(toFile: "\(tempDir)/brick.yml", atomically: true, encoding: .utf8)

        let publisher = BoxPublisher()
        #expect(throws: BoxPublisherError.self) {
            try publisher.publishBox(at: tempDir, tag: "1.0.0", isDryRun: false)
        }
    }
}
