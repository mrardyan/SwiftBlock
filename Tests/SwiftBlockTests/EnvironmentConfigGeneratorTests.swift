import Foundation
import Testing
@testable import SwiftBlockCore

struct EnvironmentConfigGeneratorTests {

    @Test func generateConfigsWhenConfigBlockEnabled() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let config = SwiftBlockConfig(
            projectName: "ConfigApp",
            bundlePrefix: "com.company",
            coreBlocks: [.config]
        )

        let generator = EnvironmentConfigGenerator()
        try generator.generateConfigs(in: tempDir.path, config: config)

        let devConfig = tempDir.appendingPathComponent("Configs/Development.xcconfig")
        let stagingConfig = tempDir.appendingPathComponent("Configs/Staging.xcconfig")
        let prodConfig = tempDir.appendingPathComponent("Configs/Production.xcconfig")

        #expect(FileManager.default.fileExists(atPath: devConfig.path))
        #expect(FileManager.default.fileExists(atPath: stagingConfig.path))
        #expect(FileManager.default.fileExists(atPath: prodConfig.path))

        let devContent = try String(contentsOf: devConfig, encoding: .utf8)
        #expect(devContent.contains("APP_ENVIRONMENT = development"))
        #expect(devContent.contains("BUNDLE_ID_SUFFIX = .dev"))

        let stagingContent = try String(contentsOf: stagingConfig, encoding: .utf8)
        #expect(stagingContent.contains("APP_ENVIRONMENT = staging"))
        #expect(stagingContent.contains("BUNDLE_ID_SUFFIX = .staging"))

        let prodContent = try String(contentsOf: prodConfig, encoding: .utf8)
        #expect(prodContent.contains("APP_ENVIRONMENT = production"))
        #expect(prodContent.contains("BUNDLE_ID_SUFFIX ="))

        // Single trailing newline verification
        #expect(devContent.hasSuffix("\n"))
        #expect(!devContent.hasSuffix("\n\n"))
    }

    @Test func skipConfigsWhenConfigBlockDisabled() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let config = SwiftBlockConfig(
            projectName: "NoConfigApp",
            bundlePrefix: "com.company",
            coreBlocks: [.storage]
        )

        let generator = EnvironmentConfigGenerator()
        try generator.generateConfigs(in: tempDir.path, config: config)

        let configsDir = tempDir.appendingPathComponent("Configs")
        #expect(!FileManager.default.fileExists(atPath: configsDir.path))
    }
}
