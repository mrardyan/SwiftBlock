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

        let content = """
name: \(config.projectName)
options:
  bundleIdPrefix: \(config.bundlePrefix)
  deploymentTarget:
    iOS: \(versions.iOSDeploymentTarget)

\(packagesBlock)

targets:
  \(config.projectName):
    type: application
    platform: iOS
    sources:
      - App/Sources
      - App/Resources
    dependencies:
\(targetPackagesDependencies)
\(postBuildScripts)

  \(config.projectName)Tests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - App/Tests
    dependencies:
      - target: \(config.projectName)
"""

        let trimmedContent = content.trimmingCharacters(in: .newlines) + "\n"
        try trimmedContent.write(toFile: manifestPath, atomically: true, encoding: .utf8)
    }

    public func addModuleDependency(moduleName: String, type: ModuleType, config: SwiftBlockConfig, projectPath: String) throws {
        // XcodeGen resolves sources recursively from App/Sources and Packages
    }
}
