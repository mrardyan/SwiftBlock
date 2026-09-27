import Foundation
@testable import SwiftBlockCore
import XCTest

final class BoxPublisherTests: XCTestCase {
    func testValidateValidBrickManifest() throws {
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

        XCTAssertEqual(report.isValid, true)
        XCTAssertTrue(report.errors.isEmpty)
        XCTAssertEqual(report.manifest?.name, "analytics")
    }

    func testValidateValidFlavorsDependenciesAndBalancedConditionals() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("BoxPubValidFlavor_\(UUID().uuidString)", isDirectory: true).path
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let manifest = """
        name: repository
        description: Clean Architecture Repository Pattern
        dependencies:
          mandatory:
            - name: transforming
              description: "Model transformation and mapping protocol"
          optional:
            - name: storage
              description: "Local persistence database engine"
          conflicts:
            - name: legacyrepository
        flavors:
          strategy:
            prompt: Select strategy
            default: offline-first
            options:
              - id: remote-only
                title: Remote Only
              - id: offline-first
                title: Offline First
                dependencies:
                  optional:
                    - name: storage
        """
        try manifest.write(toFile: "\(tempDir)/brick.yml", atomically: true, encoding: .utf8)

        let balanced = """
        import Foundation
        public final class DefaultRepository {
        {{#if strategy == 'offline-first'}}
            private var cache: [String] = []
        {{else}}
            private let remoteOnly = true
        {{/if}}
        {{#unless isLegacy}}
            public func fetch() {}
        {{/unless}}
        }
        """
        try balanced.write(toFile: "\(tempDir)/DefaultRepository.swift", atomically: true, encoding: .utf8)

        let publisher = BoxPublisher()
        let report = try publisher.validateBox(at: tempDir)

        XCTAssertEqual(report.isValid, true)
        XCTAssertTrue(report.errors.isEmpty)
        XCTAssertEqual(report.manifest?.dependencies.mandatory.first?.name, "transforming")
        XCTAssertEqual(report.manifest?.dependencies.conflicts, ["legacyrepository"])
        XCTAssertEqual(report.manifest?.flavors["strategy"]?.defaultValue, "offline-first")
    }

    func testValidateInvalidBrickManifestMissingFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("BoxPubInvalid_\(UUID().uuidString)", isDirectory: true).path
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let publisher = BoxPublisher()
        let report = try publisher.validateBox(at: tempDir)

        XCTAssertEqual(report.isValid, false)
        XCTAssertEqual(report.errors.count, 1)
        XCTAssertTrue(report.errors[0].contains("No valid brick.yml"))
    }

    func testPublishDryRunMode() throws {
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

        XCTAssertEqual(result.boxName, "storage")
        XCTAssertEqual(result.tag, "v1.2.0")
        XCTAssertEqual(result.isDryRun, true)
    }

    func testPublishFailsOutsideGitRepository() throws {
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
        XCTAssertThrowsError(try publisher.publishBox(at: tempDir, tag: "1.0.0", isDryRun: false))
    }

    func testValidateInvalidFlavorsAndDependencies() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("BoxPubInvalidFlavor_\(UUID().uuidString)", isDirectory: true).path
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let manifest = """
        name: mybrick
        description: Test Brick
        dependencies:
          mandatory:
            - name: storage
          conflicts:
            - name: storage
        flavors:
          driver:
            prompt: Choose driver
            default: nonexistent
            options:
              - id: coredata
                title: CoreData
        """
        try manifest.write(toFile: "\(tempDir)/brick.yml", atomically: true, encoding: .utf8)

        let invalidSwift = """
        {{#if driver == 'coredata'}}
        // Missing endif
        """
        try invalidSwift.write(toFile: "\(tempDir)/MyFile.swift", atomically: true, encoding: .utf8)

        let publisher = BoxPublisher()
        let report = try publisher.validateBox(at: tempDir)

        XCTAssertEqual(report.isValid, false)
        XCTAssertTrue(report.errors.contains { $0.contains("default value 'nonexistent' does not match") })
        XCTAssertTrue(report.errors.contains { $0.contains("Contradictory dependency: [storage]") })
        XCTAssertTrue(report.errors.contains { $0.contains("Mismatched '{{#if}}' tags") })
    }
}
