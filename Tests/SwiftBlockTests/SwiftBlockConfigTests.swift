import Foundation
@testable import SwiftBlockCore
import XCTest

final class SwiftBlockConfigTests: XCTestCase {
    func testDefaultInitPaths() {
        let config = SwiftBlockConfig(projectName: "TestApp")
        XCTAssertEqual(config.projectName, "TestApp")
        XCTAssertEqual(config.bundlePrefix, "com.company")
        XCTAssertEqual(config.paths.path(for: .scene), "App/Sources/Features")
        XCTAssertEqual(config.paths.path(for: .storage), "App/Sources/Core/Storage")
    }

    func testCustomPathSubscriptAndSetPath() {
        var paths = SwiftBlockConfig.ModulePaths()
        XCTAssertEqual(paths[.scene], "App/Sources/Features")

        paths[.scene] = "Custom/Features"
        XCTAssertEqual(paths[.scene], "Custom/Features")
        XCTAssertEqual(paths.path(for: .scene), "Custom/Features")
    }

    func testCodableEncodingAndDecodingDictionary() throws {
        var config = SwiftBlockConfig(projectName: "CustomApp", bundlePrefix: "com.company")
        config.paths[.scene] = "Sources/Scenes"

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(SwiftBlockConfig.self, from: data)

        XCTAssertEqual(decoded.projectName, "CustomApp")
        XCTAssertEqual(decoded.bundlePrefix, "com.company")
        XCTAssertEqual(decoded.paths.path(for: .scene), "Sources/Scenes")
        XCTAssertEqual(decoded.paths.path(for: .storage), "App/Sources/Core/Storage")
    }

    func testLegacyKeyedJSONDecoding() throws {
        let jsonString = """
        {
            "projectName": "LegacyApp",
            "bundlePrefix": "org.legacy",
            "paths": {
                "scene": "Legacy/Features",
                "usecase": "Legacy/Domain"
            }
        }
        """
        let data = jsonString.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(SwiftBlockConfig.self, from: data)

        XCTAssertEqual(decoded.projectName, "LegacyApp")
        XCTAssertEqual(decoded.paths.path(for: .scene), "Legacy/Features")
        XCTAssertEqual(decoded.paths.path(for: .usecase), "Legacy/Domain")
        XCTAssertEqual(decoded.paths.path(for: .repository), "App/Sources/Data/Repositories")
    }

    func testYamlQuotedHashTagParsing() {
        let yamlContent = """
        projectName: "HashtagApp #1"
        bundlePrefix: "#com.company"
        url: "https://example.com/#tag"
        """
        let parsed = SimpleYAMLParser.parse(yamlContent)
        XCTAssertEqual(parsed["projectName"] as? String, "HashtagApp #1")
        XCTAssertEqual(parsed["bundlePrefix"] as? String, "#com.company")
        XCTAssertEqual(parsed["url"] as? String, "https://example.com/#tag")
    }

    func testYamlRoundtripPreservesAllFields() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ConfigRoundtrip_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        var config = SwiftBlockConfig(
            projectName: "RoundTripApp",
            bundlePrefix: "com.roundtrip",
            organization: "technical-first",
            generatorTool: .xcodegen,
            guardrails: GuardrailsConfig(
                swiftlint: false, swiftformat: true, precommit: false, periphery: true,
                gitleaks: false, danger: true, swiftgen: false, licenseplist: true
            ),
            cicd: CICDConfig(provider: .gitlabCI),
            coreBlocks: [.network, .config],
            gitInit: false,
            testFramework: .xctest
        )
        config.pathTemplates["feature"] = "App/Sources/Features/{module}/{block}"
        try config.save(to: tempDir.path)

        let loaded = try SwiftBlockConfig.load(from: tempDir.path)
        XCTAssertEqual(loaded.projectName, "RoundTripApp")
        XCTAssertEqual(loaded.bundlePrefix, "com.roundtrip")
        XCTAssertEqual(loaded.organization, "technical-first")
        XCTAssertEqual(loaded.generatorTool, .xcodegen)
        XCTAssertEqual(loaded.guardrails.swiftlint, false)
        XCTAssertEqual(loaded.guardrails.swiftformat, true)
        XCTAssertEqual(loaded.guardrails.precommit, false)
        XCTAssertEqual(loaded.guardrails.periphery, true)
        XCTAssertEqual(loaded.guardrails.gitleaks, false)
        XCTAssertEqual(loaded.guardrails.danger, true)
        XCTAssertEqual(loaded.guardrails.swiftgen, false)
        XCTAssertEqual(loaded.guardrails.licenseplist, true)
        XCTAssertEqual(loaded.cicd.provider, .gitlabCI)
        XCTAssertEqual(loaded.coreBlocks, [.network, .config])
        XCTAssertEqual(loaded.gitInit, false)
        XCTAssertEqual(loaded.testFramework, .xctest)
    }
}
