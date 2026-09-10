import Foundation

public class TuistManifestGenerator: ProjectManifestGenerator {
    public init() {}

    public func generateManifest(config: SwiftBlockConfig, projectPath: String) throws {
        let manifestPath = "\(projectPath)/Project.swift"

        var targetDependencies: [String] = []

        if config.packaging.core == "spm" {
            targetDependencies.append("            .package(product: \"Core\", type: .runtime)")
        }

        let dependenciesString = targetDependencies.isEmpty ? "" : "\n\(targetDependencies.joined(separator: ",\n"))\n        "

        var packagesString = ""
        if config.packaging.core == "spm" {
            packagesString = "\n    packages: [\n        .package(path: \"Packages/Core\")\n    ],"
        }

        var scriptsString = ""
        if config.guardrails.swiftlint {
            scriptsString = """
            scripts: [
                .post(
                    script: \"\"\"
if [[ "$(uname -m)" == arm64 ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
fi
if which swiftlint > /dev/null; then
  swiftlint
else
  echo "warning: SwiftLint not installed"
fi
\"\"\",
                    name: "Run SwiftLint",
                    basedOnDependencyAnalysis: false
                )
            ],
"""
        } else {
            scriptsString = "scripts: [],"
        }

        let content = """
import ProjectDescription

let project = Project(
    name: "\(config.projectName)",\(packagesString)
    targets: [
        .target(
            name: "\(config.projectName)",
            destinations: .iOS,
            product: .app,
            bundleId: "\(config.bundlePrefix).\(config.projectName)",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: ["App/Sources/**"],
            resources: ["App/Resources/**"],
            \(scriptsString)
            dependencies: [\(dependenciesString)]
        ),
        .target(
            name: "\(config.projectName)Tests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "\(config.bundlePrefix).\(config.projectName)Tests",
            infoPlist: .default,
            sources: ["App/Tests/**"],
            resources: [],
            dependencies: [.target(name: "\(config.projectName)")]
        ),
    ]
)
"""

        let trimmedContent = content.trimmingCharacters(in: .newlines) + "\n"
        try trimmedContent.write(toFile: manifestPath, atomically: true, encoding: .utf8)
    }

    public func addModuleDependency(moduleName: String, type: ModuleType, config: SwiftBlockConfig, projectPath: String) throws {
        // Tuist auto-resolves sources dynamically via "App/Sources/**" and "Packages/**"
    }
}
