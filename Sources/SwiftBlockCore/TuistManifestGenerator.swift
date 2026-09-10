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

        var infoPlistProps = """
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
"""
        var targetSettings = ""
        var schemesBlock = ""

        if config.coreBlocks.contains(.config) {
            infoPlistProps += """
                    "APP_ENVIRONMENT": "$(APP_ENVIRONMENT)",
                    "BASE_URL": "$(BASE_URL)",
                    "API_KEY": "$(API_KEY)",
                    "CFBundleDisplayName": "$(TARGET_NAME)$(APP_NAME_SUFFIX)",
"""
            targetSettings = """
            settings: .settings(
                configurations: [
                    .debug(name: "Development", xcconfig: "Configs/Development.xcconfig"),
                    .debug(name: "Staging", xcconfig: "Configs/Staging.xcconfig"),
                    .release(name: "Production", xcconfig: "Configs/Production.xcconfig"),
                ]
            ),
"""
            schemesBlock = """
    schemes: [
        .scheme(
            name: "\(config.projectName)-Dev",
            shared: true,
            buildAction: .buildAction(targets: ["\(config.projectName)"]),
            testAction: .targets(["\(config.projectName)Tests"]),
            runAction: .runAction(configuration: "Development")
        ),
        .scheme(
            name: "\(config.projectName)-Staging",
            shared: true,
            buildAction: .buildAction(targets: ["\(config.projectName)"]),
            testAction: .targets(["\(config.projectName)Tests"]),
            runAction: .runAction(configuration: "Staging")
        ),
        .scheme(
            name: "\(config.projectName)-Prod",
            shared: true,
            buildAction: .buildAction(targets: ["\(config.projectName)"]),
            testAction: .targets(["\(config.projectName)Tests"]),
            runAction: .runAction(configuration: "Production")
        ),
    ],
"""
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
\(infoPlistProps)
                ]
            ),
            sources: ["App/Sources/**"],
            resources: ["App/Resources/**"],
            \(scriptsString)
            \(targetSettings)dependencies: [\(dependenciesString)]
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
    ],
\(schemesBlock)
)
"""

        let trimmedContent = content.trimmingCharacters(in: .newlines) + "\n"
        try trimmedContent.write(toFile: manifestPath, atomically: true, encoding: .utf8)
    }

    public func addModuleDependency(moduleName: String, type: ModuleType, config: SwiftBlockConfig, projectPath: String) throws {
        // Tuist auto-resolves sources dynamically via "App/Sources/**" and "Packages/**"
    }
}
