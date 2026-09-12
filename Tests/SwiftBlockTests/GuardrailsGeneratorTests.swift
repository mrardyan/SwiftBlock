import Foundation
import Testing
@testable import SwiftBlockCore

struct GuardrailsGeneratorTests {

    @Test func injectAllGuardrails() throws {
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

        #expect(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent(".swiftlint.yml").path))
        #expect(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent(".swiftformat").path))
        #expect(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent(".pre-commit-config.yaml").path))
        #expect(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent(".periphery.yml").path))
        #expect(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("Dangerfile.swift").path))
        #expect(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("swiftgen.yml").path))
    }

    @Test func injectSelectiveGuardrails() throws {
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

        #expect(FileManager.default.fileExists(atPath: tempDir.appendingPathComponent(".swiftlint.yml").path))
        #expect(!FileManager.default.fileExists(atPath: tempDir.appendingPathComponent(".swiftformat").path))
        #expect(!FileManager.default.fileExists(atPath: tempDir.appendingPathComponent(".pre-commit-config.yaml").path))
    }
}
