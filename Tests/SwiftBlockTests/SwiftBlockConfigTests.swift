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
}
