import Foundation

public class GuardrailsGenerator {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func generateGuardrails(in projectPath: String, config: SwiftBlockConfig) throws {
        let guardrails = config.guardrails

        // 1. SwiftLint (.swiftlint.yml)
        if guardrails.swiftlint {
            let swiftlintPath = "\(projectPath)/.swiftlint.yml"
            if !fileManager.fileExists(atPath: swiftlintPath) {
                let content = """
disabled_rules:
  - trailing_whitespace
opt_in_rules:
  - empty_count
  - force_unwrapping
included:
  - App
  - Packages
"""
                let trimmedContent = content.trimmingCharacters(in: .newlines) + "\n"
                try trimmedContent.write(toFile: swiftlintPath, atomically: true, encoding: .utf8)
            }
        }

        // 2. SwiftFormat (.swiftformat)
        if guardrails.swiftformat {
            let swiftformatPath = "\(projectPath)/.swiftformat"
            if !fileManager.fileExists(atPath: swiftformatPath) {
                let content = """
--indent 4
--allman false
--swiftversion 6.0
--exclude **/Generated/**
"""
                let trimmedContent = content.trimmingCharacters(in: .newlines) + "\n"
                try trimmedContent.write(toFile: swiftformatPath, atomically: true, encoding: .utf8)
            }
        }

        // 3. Pre-commit (.pre-commit-config.yaml)
        if guardrails.precommit {
            let precommitPath = "\(projectPath)/.pre-commit-config.yaml"
            if !fileManager.fileExists(atPath: precommitPath) {
                var repos: [String] = []

                if guardrails.gitleaks {
                    repos.append("""
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.21.0
    hooks:
      - id: gitleaks
""")
                }

                if guardrails.swiftlint {
                    repos.append("""
  - repo: https://github.com/realm/SwiftLint
    rev: 0.57.0
    hooks:
      - id: swiftlint
""")
                }

                if guardrails.swiftformat {
                    repos.append("""
  - repo: https://github.com/nicklockwood/SwiftFormat
    rev: 0.54.0
    hooks:
      - id: swiftformat
""")
                }

                let content = """
repos:
\(repos.joined(separator: "\n"))
"""
                let trimmedContent = content.trimmingCharacters(in: .newlines) + "\n"
                try trimmedContent.write(toFile: precommitPath, atomically: true, encoding: .utf8)
            }
        }

        // 4. Periphery (.periphery.yml)
        if guardrails.periphery {
            let peripheryPath = "\(projectPath)/.periphery.yml"
            if !fileManager.fileExists(atPath: peripheryPath) {
                let content = """
project: \(config.projectName).xcodeproj
schemes:
  - \(config.projectName)
targets:
  - \(config.projectName)
"""
                let trimmedContent = content.trimmingCharacters(in: .newlines) + "\n"
                try trimmedContent.write(toFile: peripheryPath, atomically: true, encoding: .utf8)
            }
        }

        // 5. Danger (Dangerfile.swift)
        if guardrails.danger {
            let dangerPath = "\(projectPath)/Dangerfile.swift"
            if !fileManager.fileExists(atPath: dangerPath) {
                let content = """
import Danger

let danger = Danger()

// Warn if PR title is too short
if danger.github.pullRequest.title.count < 10 {
    warn("PR title is quite short. Please provide a clear description.")
}

// Encourage unit tests for new code
let editedFiles = danger.git.modifiedFiles + danger.git.createdFiles
let hasSourceChanges = editedFiles.contains { $0.hasPrefix("App/Sources") }
let hasTestChanges = editedFiles.contains { $0.hasPrefix("App/Tests") }

if hasSourceChanges && !hasTestChanges {
    warn("Source files were modified, but no test files were updated. Please add unit tests.")
}
"""
                let trimmedContent = content.trimmingCharacters(in: .newlines) + "\n"
                try trimmedContent.write(toFile: dangerPath, atomically: true, encoding: .utf8)
            }
        }

        // 6. SwiftGen (swiftgen.yml)
        if guardrails.swiftgen {
            let swiftgenPath = "\(projectPath)/swiftgen.yml"
            if !fileManager.fileExists(atPath: swiftgenPath) {
                let content = """
xcassets:
  inputs:
    - App/Resources/Assets.xcassets
  outputs:
    - templateName: swift5
      output: App/Sources/Generated/XCAssets+Generated.swift
"""
                let trimmedContent = content.trimmingCharacters(in: .newlines) + "\n"
                try trimmedContent.write(toFile: swiftgenPath, atomically: true, encoding: .utf8)
            }
        }
    }
}
