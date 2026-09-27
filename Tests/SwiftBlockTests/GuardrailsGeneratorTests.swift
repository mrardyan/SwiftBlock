import Foundation
@testable import SwiftBlockCore
import XCTest

final class GuardrailsGeneratorTests: XCTestCase {
    func testInjectAllGuardrails() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let config = SwiftBlockConfig(
            projectName: "GuardrailsTestApp",
            bundlePrefix: "com.test",
            guardrails: GuardrailsConfig(
                swiftlint: true,
                swiftformat: true,
                precommit: true,
                periphery: true,
                gitleaks: true,
                danger: true,
                swiftgen: true,
                licenseplist: true
            )
        )

        let generator = GuardrailsGenerator()
        try generator.generateGuardrails(in: tempDir.path, config: config)

        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent(".swiftlint.yml").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent(".swiftformat").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent(".pre-commit-config.yaml").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent(".periphery.yml").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("Dangerfile.swift").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("swiftgen.yml").path))
    }

    func testInjectSelectiveGuardrails() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let config = SwiftBlockConfig(
            projectName: "SelectiveGuardrailsApp",
            bundlePrefix: "com.test",
            guardrails: GuardrailsConfig(
                swiftlint: true,
                swiftformat: false,
                precommit: false,
                periphery: false,
                gitleaks: false,
                danger: false,
                swiftgen: false,
                licenseplist: false
            )
        )

        let generator = GuardrailsGenerator()
        try generator.generateGuardrails(in: tempDir.path, config: config)

        XCTAssertTrue(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent(".swiftlint.yml").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent(".swiftformat").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent(".pre-commit-config.yaml").path))
    }
}
