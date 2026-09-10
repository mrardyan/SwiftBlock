import Foundation

public class EnvironmentSetupGenerator {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func generateSetupFiles(in projectPath: String, config: SwiftBlockConfig) throws {
        let versions = DependencyVersionRegistry.resolve(overrides: config.toolVersions)

        // 1. Generate .mise.toml
        try generateMiseToml(in: projectPath, config: config, versions: versions)

        // 2. Generate Makefile
        try generateMakefile(in: projectPath, config: config, versions: versions)

        // 3. Generate Scripts/setup.sh
        try generateSetupScript(in: projectPath, config: config, versions: versions)
    }

    private func generateMiseToml(in projectPath: String, config: SwiftBlockConfig, versions: DependencyVersionRegistry) throws {
        var tools: [String] = ["[tools]"]

        if config.generatorTool == .tuist {
            tools.append("tuist = \"\(versions.tuist)\"")
        } else {
            tools.append("xcodegen = \"\(versions.xcodegen)\"")
        }

        if config.guardrails.swiftlint { tools.append("swiftlint = \"\(versions.swiftlint)\"") }
        if config.guardrails.swiftformat { tools.append("swiftformat = \"\(versions.swiftformat)\"") }
        if config.guardrails.periphery { tools.append("periphery = \"\(versions.periphery)\"") }
        if config.guardrails.gitleaks { tools.append("gitleaks = \"\(versions.gitleaks)\"") }
        if config.guardrails.precommit { tools.append("pre-commit = \"\(versions.precommit)\"") }
        if config.guardrails.swiftgen { tools.append("swiftgen = \"\(versions.swiftgen)\"") }
        if config.guardrails.licenseplist { tools.append("license-plist = \"\(versions.licenseplist)\"") }

        let content = tools.joined(separator: "\n").trimmingCharacters(in: .newlines) + "\n"
        try content.write(toFile: "\(projectPath)/.mise.toml", atomically: true, encoding: .utf8)
    }

    private func generateMakefile(in projectPath: String, config: SwiftBlockConfig, versions: DependencyVersionRegistry) throws {
        let generateCmd = config.generatorTool == .tuist ? "tuist generate --no-open" : "xcodegen generate"
        var targets: [String] = []
        var helpLines: [String] = [
            "  make setup             Setup environment (install tools, hooks & generate project)",
            "  make generate          Generate project via \(config.generatorTool.rawValue)"
        ]

        targets.append("""
.PHONY: setup
setup:
	@echo "◆ Setting up environment..."
	@bash Scripts/setup.sh
""")

        targets.append("""
.PHONY: generate
generate:
	@echo "◆ Generating project via \(config.generatorTool.rawValue)..."
	@\(generateCmd)
""")

        if config.guardrails.swiftformat {
            helpLines.append("  make format            Format Swift code via SwiftFormat")
            targets.append("""
.PHONY: format
format:
	@echo "◆ Formatting Swift code..."
	@swiftformat .
""")
        }

        if config.guardrails.swiftlint {
            helpLines.append("  make lint              Lint Swift code via SwiftLint")
            targets.append("""
.PHONY: lint
lint:
	@echo "◆ Linting Swift code..."
	@swiftlint
""")
        }

        if config.guardrails.periphery {
            helpLines.append("  make periphery         Scan for unused Swift code via Periphery")
            targets.append("""
.PHONY: periphery
periphery:
	@echo "◆ Scanning for unused code..."
	@periphery scan
""")
        }

        if config.guardrails.swiftgen {
            helpLines.append("  make generate-assets   Generate type-safe assets via SwiftGen")
            targets.append("""
.PHONY: generate-assets
generate-assets:
	@echo "◆ Generating type-safe assets..."
	@swiftgen
""")
        }

        if config.guardrails.licenseplist {
            helpLines.append("  make generate-licenses Generate open source licenses via LicensePlist")
            targets.append("""
.PHONY: generate-licenses
generate-licenses:
	@echo "◆ Generating open source licenses..."
	@license-plist --output-path App/Resources/Settings.bundle
""")
        }

        helpLines.append("  make test              Run unit tests via xcodebuild")
        targets.append("""
.PHONY: test
test:
	@echo "◆ Running tests..."
	@xcodebuild test -scheme \(config.projectName) -destination 'platform=iOS Simulator,name=iPhone 15'
""")

        let helpTarget = """
.PHONY: help
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
\(helpLines.map { "\t@echo \"\($0)\"" }.joined(separator: "\n"))
"""

        let content = ([helpTarget] + targets).joined(separator: "\n\n").trimmingCharacters(in: .newlines) + "\n"
        try content.write(toFile: "\(projectPath)/Makefile", atomically: true, encoding: .utf8)
    }

    private func generateSetupScript(in projectPath: String, config: SwiftBlockConfig, versions: DependencyVersionRegistry) throws {
        let scriptsDir = "\(projectPath)/Scripts"
        try fileManager.createDirectory(atPath: scriptsDir, withIntermediateDirectories: true)

        var setupSteps: [String] = []

        var requiredToolChecks: [(binary: String, brewFormula: String)] = []
        if config.generatorTool == .tuist {
            requiredToolChecks.append(("tuist", "tuist"))
        } else {
            requiredToolChecks.append(("xcodegen", "xcodegen"))
        }

        if config.guardrails.swiftlint { requiredToolChecks.append(("swiftlint", "swiftlint")) }
        if config.guardrails.swiftformat { requiredToolChecks.append(("swiftformat", "swiftformat")) }
        if config.guardrails.periphery { requiredToolChecks.append(("periphery", "peripheryapp/periphery/periphery")) }
        if config.guardrails.gitleaks { requiredToolChecks.append(("gitleaks", "gitleaks")) }
        if config.guardrails.precommit { requiredToolChecks.append(("pre-commit", "pre-commit")) }
        if config.guardrails.swiftgen { requiredToolChecks.append(("swiftgen", "swiftgen")) }
        if config.guardrails.licenseplist { requiredToolChecks.append(("license-plist", "licenseplist")) }

        let checkStatements = requiredToolChecks.map { item in
            "which \(item.binary) > /dev/null 2>&1 || MISSING_TOOLS=\"$MISSING_TOOLS \(item.brewFormula)\""
        }.joined(separator: "\n")

        setupSteps.append("""
if which mise > /dev/null 2>&1; then
    echo "◆ Installing tool dependencies via mise..."
    if [ -z "$GITHUB_TOKEN" ] && which gh > /dev/null 2>&1; then
        export GITHUB_TOKEN=$(gh auth token 2>/dev/null || true)
    fi
    mise install 2>/dev/null || true
fi

MISSING_TOOLS=""
\(checkStatements)

if [ -n "$MISSING_TOOLS" ]; then
    if which brew > /dev/null 2>&1; then
        echo "◆ Installing missing tools via Homebrew:$MISSING_TOOLS..."
        brew install $MISSING_TOOLS
    fi
fi
""")

        if config.guardrails.precommit {
            setupSteps.append("""
if which pre-commit > /dev/null 2>&1; then
    echo "◆ Installing git pre-commit hooks..."
    pre-commit install
fi
""")
        }

        let generateCmd = config.generatorTool == .tuist ? "tuist generate --no-open" : "xcodegen generate"
        setupSteps.append("""
echo "◆ Generating project..."
\(generateCmd)
""")

        let scriptContent = """
#!/usr/bin/env bash
set -e

echo "◆ Setting up \(config.projectName)..."
\(setupSteps.joined(separator: "\n\n"))
echo "✔ Setup complete!"
"""

        let setupPath = "\(scriptsDir)/setup.sh"
        let trimmedScript = scriptContent.trimmingCharacters(in: .newlines) + "\n"
        try trimmedScript.write(toFile: setupPath, atomically: true, encoding: .utf8)
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: setupPath)
    }
}
