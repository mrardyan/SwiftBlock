import Foundation

/// Generates environment-specific `.xcconfig` files (Development, Staging, Production).
public class EnvironmentConfigGenerator {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// Generates `.xcconfig` files in the `Configs/` directory if the Config core block is enabled.
    public func generateConfigs(in projectPath: String, config: SwiftBlockConfig) throws {
        guard config.coreBlocks.contains(.config) else { return }

        let configsDir = "\(projectPath)/Configs"
        try fileManager.createDirectory(atPath: configsDir, withIntermediateDirectories: true)

        let devContent = """
// Development Environment Configuration
APP_ENVIRONMENT = development
APP_NAME_SUFFIX =  (Dev)
BUNDLE_ID_SUFFIX = .dev
BASE_URL = https:/$()/dev-api.example.com
API_KEY = dev_sample_api_key_12345
"""

        let stagingContent = """
// Staging Environment Configuration
APP_ENVIRONMENT = staging
APP_NAME_SUFFIX =  (Staging)
BUNDLE_ID_SUFFIX = .staging
BASE_URL = https:/$()/staging-api.example.com
API_KEY = staging_sample_api_key_67890
"""

        let prodContent = """
// Production Environment Configuration
APP_ENVIRONMENT = production
APP_NAME_SUFFIX =
BUNDLE_ID_SUFFIX =
BASE_URL = https:/$()/api.example.com
API_KEY = prod_sample_api_key_99999
"""

        try writeConfigFile(content: devContent, to: "\(configsDir)/Development.xcconfig")
        try writeConfigFile(content: stagingContent, to: "\(configsDir)/Staging.xcconfig")
        try writeConfigFile(content: prodContent, to: "\(configsDir)/Production.xcconfig")
    }

    private func writeConfigFile(content: String, to path: String) throws {
        let trimmed = content.trimmingCharacters(in: .newlines) + "\n"
        try trimmed.write(toFile: path, atomically: true, encoding: .utf8)
    }
}
