import Foundation
import Testing
@testable import SwiftBlockCore

struct SwiftBlockConfigTests {

    @Test func defaultInitPaths() {
        let config = SwiftBlockConfig(projectName: "TestApp")
        #expect(config.projectName == "TestApp")
        #expect(config.bundlePrefix == "com.company")
        #expect(config.paths.path(for: .scene) == "App/Sources/Features")
        #expect(config.paths.path(for: .storage) == "App/Sources/Core/Storage")
    }

    @Test func customPathSubscriptAndSetPath() {
        var paths = SwiftBlockConfig.ModulePaths()
        #expect(paths[.scene] == "App/Sources/Features")

        paths[.scene] = "Custom/Features"
        #expect(paths[.scene] == "Custom/Features")
        #expect(paths.path(for: .scene) == "Custom/Features")
    }

    @Test func codableEncodingAndDecodingDictionary() throws {
        var config = SwiftBlockConfig(projectName: "CustomApp", bundlePrefix: "com.company")
        config.paths[.scene] = "Sources/Scenes"

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(SwiftBlockConfig.self, from: data)

        #expect(decoded.projectName == "CustomApp")
        #expect(decoded.bundlePrefix == "com.company")
        #expect(decoded.paths.path(for: .scene) == "Sources/Scenes")
        #expect(decoded.paths.path(for: .storage) == "App/Sources/Core/Storage")
    }

    @Test func legacyKeyedJSONDecoding() throws {
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

        #expect(decoded.projectName == "LegacyApp")
        #expect(decoded.paths.path(for: .scene) == "Legacy/Features")
        #expect(decoded.paths.path(for: .usecase) == "Legacy/Domain")
        #expect(decoded.paths.path(for: .repository) == "App/Sources/Data/Repositories")
    }

    @Test func yamlQuotedHashTagParsing() {
        let yamlContent = """
        projectName: "HashtagApp #1"
        bundlePrefix: "#com.company"
        url: "https://example.com/#tag"
        """
        let parsed = SimpleYAMLParser.parse(yamlContent)
        #expect(parsed["projectName"] as? String == "HashtagApp #1")
        #expect(parsed["bundlePrefix"] as? String == "#com.company")
        #expect(parsed["url"] as? String == "https://example.com/#tag")
    }

    @Test func yamlRoundtripPreservesAllFields() throws {
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
        #expect(loaded.projectName == "RoundTripApp")
        #expect(loaded.bundlePrefix == "com.roundtrip")
        #expect(loaded.organization == "technical-first")
        #expect(loaded.generatorTool == .xcodegen)
        #expect(loaded.guardrails.swiftlint == false)
        #expect(loaded.guardrails.swiftformat == true)
        #expect(loaded.guardrails.precommit == false)
        #expect(loaded.guardrails.periphery == true)
        #expect(loaded.guardrails.gitleaks == false)
        #expect(loaded.guardrails.danger == true)
        #expect(loaded.guardrails.swiftgen == false)
        #expect(loaded.guardrails.licenseplist == true)
        #expect(loaded.cicd.provider == .gitlabCI)
        #expect(loaded.coreBlocks == [.network, .config])
        #expect(loaded.gitInit == false)
        #expect(loaded.testFramework == .xctest)
    }
}
