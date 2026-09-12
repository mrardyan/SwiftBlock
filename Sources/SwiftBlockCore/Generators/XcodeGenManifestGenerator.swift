import Foundation

public class XcodeGenManifestGenerator: ProjectManifestGenerator {
    public init() {}

    public func generateManifest(config: SwiftBlockConfig, projectPath: String) throws {
        let versions = DependencyVersionRegistry.resolve(overrides: config.toolVersions)
        let manifestPath = "\(projectPath)/project.yml"

        var packagesBlock = ""
        var targetPackagesDependencies = ""

        if config.packaging.core == "spm" {
            packagesBlock = """
packages:
  Core:
    path: Packages/Core
"""
            targetPackagesDependencies = """
      - package: Core
"""
        }

        var postBuildScripts = ""
        if config.guardrails.swiftlint {
            postBuildScripts = """
    postBuildScripts:
      - name: Run SwiftLint
        script: |
          if [[ "$(uname -m)" == arm64 ]]; then
              export PATH="/opt/homebrew/bin:$PATH"
          fi
          if which swiftlint > /dev/null; then
            swiftlint
          fi
"""
        }

        var configsBlock = ""
        var targetConfigSettings = ""
        var schemesBlock = ""

        if config.coreBlocks.contains(.config) {
            configsBlock = """
configs:
  Development: debug
  Staging: debug
  Production: release
"""
            targetConfigSettings = """
    configFiles:
      Development: Configs/Development.xcconfig
      Staging: Configs/Staging.xcconfig
      Production: Configs/Production.xcconfig
    info:
      path: App/Info.plist
      properties:
        APP_ENVIRONMENT: "$(APP_ENVIRONMENT)"
        BASE_URL: "$(BASE_URL)"
        API_KEY: "$(API_KEY)"
        CFBundleDisplayName: "$(TARGET_NAME)$(APP_NAME_SUFFIX)"
"""
            schemesBlock = """

schemes:
  \(config.projectName)-Dev:
    build:
      targets:
        \(config.projectName): all
    run:
      config: Development
  \(config.projectName)-Stg:
    build:
      targets:
        \(config.projectName): all
    run:
      config: Staging
  \(config.projectName):
    build:
      targets:
        \(config.projectName): all
    run:
      config: Production
"""
        }

        let targetConfigSettingsSection = targetConfigSettings.isEmpty ? "" : "\(targetConfigSettings)\n"
        let targetDepsSection = targetPackagesDependencies.isEmpty ? "" : "    dependencies:\n\(targetPackagesDependencies)\n"

        let content = """
name: \(config.projectName)
options:
  bundleIdPrefix: \(config.bundlePrefix)
  deploymentTarget:
    iOS: \(versions.iOSDeploymentTarget)

\(configsBlock)
\(packagesBlock)

targets:
  \(config.projectName):
    type: application
    platform: iOS
\(targetConfigSettingsSection)    sources:
      - App/Sources
      - App/Resources
\(targetDepsSection)\(postBuildScripts)

  \(config.projectName)Tests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - App/Tests
    dependencies:
      - target: \(config.projectName)
\(schemesBlock)
"""

        let trimmedContent = content.trimmingCharacters(in: .newlines) + "\n"
        try trimmedContent.write(toFile: manifestPath, atomically: true, encoding: .utf8)
    }

    public func addModuleDependency(moduleName: String, type: ModuleType, config: SwiftBlockConfig, projectPath: String) throws {
        // XcodeGen resolves sources recursively from App/Sources and Packages
    }
}
