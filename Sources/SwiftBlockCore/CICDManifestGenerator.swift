import Foundation

public class CICDManifestGenerator {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func generateCICDPipeline(in projectPath: String, config: SwiftBlockConfig) throws {
        switch config.cicd.provider {
        case .githubActions:
            try generateGitHubActions(in: projectPath, config: config)
        case .gitlabCI:
            try generateGitLabCI(in: projectPath, config: config)
        case .bitrise:
            try generateBitrise(in: projectPath, config: config)
        case .xcodeCloud:
            try generateXcodeCloud(in: projectPath, config: config)
        case .none:
            break
        }
    }

    private func generateGitHubActions(in projectPath: String, config: SwiftBlockConfig) throws {
        let workflowsDir = "\(projectPath)/.github/workflows"
        try fileManager.createDirectory(atPath: workflowsDir, withIntermediateDirectories: true)

        let ciPath = "\(workflowsDir)/ci.yml"
        let generateCmd = config.generatorTool == .tuist ? "tuist generate" : "xcodegen generate"

        var steps: [String] = [
            """
      - name: Checkout Code
        uses: actions/checkout@v4
""",
            """
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.4.app
""",
            """
      - name: Install Tooling via mise
        uses: jdx/mise-action@v2
""",
            """
      - name: Generate Project Manifests
        run: \(generateCmd)
"""
        ]

        if config.guardrails.swiftlint {
            steps.append("""
      - name: Run SwiftLint
        run: swiftlint
""")
        }

        if config.guardrails.swiftformat {
            steps.append("""
      - name: Check SwiftFormat
        run: swiftformat --lint .
""")
        }

        steps.append("""
      - name: Run Unit Tests
        run: xcodebuild test -scheme \(config.projectName) -destination 'platform=iOS Simulator,name=iPhone 15'
""")

        if config.guardrails.danger {
            steps.append("""
      - name: Run Danger
        if: github.event_name == 'pull_request'
        run: danger-swift ci
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
""")
        }

        let content = """
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  build-and-test:
    runs-on: macos-14
    steps:
\(steps.joined(separator: "\n\n"))
"""

        try content.write(toFile: ciPath, atomically: true, encoding: .utf8)
    }

    private func generateGitLabCI(in projectPath: String, config: SwiftBlockConfig) throws {
        let ciPath = "\(projectPath)/.gitlab-ci.yml"
        let generateCmd = config.generatorTool == .tuist ? "tuist generate" : "xcodegen generate"

        let content = """
stages:
  - build
  - test

build_job:
  stage: build
  tags:
    - saas-macos-medium-m1
  script:
    - mise install
    - \(generateCmd)
    - xcodebuild build -scheme \(config.projectName) -destination 'platform=iOS Simulator,name=iPhone 15'

test_job:
  stage: test
  tags:
    - saas-macos-medium-m1
  script:
    - mise install
    - \(generateCmd)
    - xcodebuild test -scheme \(config.projectName) -destination 'platform=iOS Simulator,name=iPhone 15'
"""
        try content.write(toFile: ciPath, atomically: true, encoding: .utf8)
    }

    private func generateBitrise(in projectPath: String, config: SwiftBlockConfig) throws {
        let ciPath = "\(projectPath)/bitrise.yml"
        let generateCmd = config.generatorTool == .tuist ? "tuist generate" : "xcodegen generate"

        let content = """
format_version: "11"
default_step_lib_source: https://github.com/bitrise-io/bitrise-steplib.git
workflows:
  primary:
    steps:
      - activate-ssh-key@4: {}
      - git-clone-repository@1: {}
      - script@1:
          title: Setup Environment & Generate Project
          inputs:
            - content: |-
                mise install
                \(generateCmd)
      - xcode-test@5:
          inputs:
            - project_path: \(config.projectName).xcodeproj
            - scheme: \(config.projectName)
"""
        try content.write(toFile: ciPath, atomically: true, encoding: .utf8)
    }

    private func generateXcodeCloud(in projectPath: String, config: SwiftBlockConfig) throws {
        let scriptsDir = "\(projectPath)/ci_scripts"
        try fileManager.createDirectory(atPath: scriptsDir, withIntermediateDirectories: true)

        let scriptPath = "\(scriptsDir)/ci_post_clone.sh"
        let generateCmd = config.generatorTool == .tuist ? "tuist generate" : "xcodegen generate"

        let content = """
#!/usr/bin/env bash
set -e

echo "🚀 Xcode Cloud Post-Clone Setup..."
if which mise > /dev/null; then
    mise install
fi

\(generateCmd)
"""
        try content.write(toFile: scriptPath, atomically: true, encoding: .utf8)
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptPath)
    }
}
