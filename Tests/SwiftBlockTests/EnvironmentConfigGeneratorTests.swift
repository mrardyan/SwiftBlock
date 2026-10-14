import Foundation
@testable import SwiftBlockCore
import XCTest

final class EnvironmentConfigGeneratorTests: XCTestCase {
    func testGenerateConfigsWhenConfigBlockEnabled() throws {
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

        XCTAssertTrue(FileManager.default.fileExists(atPath: devConfig.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: stagingConfig.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: prodConfig.path))

        let devContent = try String(contentsOf: devConfig, encoding: .utf8)
        XCTAssertTrue(devContent.contains("APP_ENVIRONMENT = development"))
        XCTAssertTrue(devContent.contains("BUNDLE_ID_SUFFIX = .dev"))

        let stagingContent = try String(contentsOf: stagingConfig, encoding: .utf8)
        XCTAssertTrue(stagingContent.contains("APP_ENVIRONMENT = staging"))
        XCTAssertTrue(stagingContent.contains("BUNDLE_ID_SUFFIX = .staging"))

        let prodContent = try String(contentsOf: prodConfig, encoding: .utf8)
        XCTAssertTrue(prodContent.contains("APP_ENVIRONMENT = production"))
        XCTAssertTrue(prodContent.contains("BUNDLE_ID_SUFFIX ="))

        // Single trailing newline verification
        XCTAssertTrue(devContent.hasSuffix("\n"))
        XCTAssertFalse(devContent.hasSuffix("\n\n"))
    }

    func testSkipConfigsWhenConfigBlockDisabled() throws {
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
        XCTAssertFalse(FileManager.default.fileExists(atPath: configsDir.path))
    }
}
