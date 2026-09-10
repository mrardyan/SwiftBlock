import Foundation
import Testing
@testable import SwiftBlockCore

struct E2ETests {

    @Test func testE2ETuistSPMCoreAndSPMFeatureMatrix() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("E2E_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let projectPath = tempDir.appendingPathComponent("TuistSPMApp").path

        let config = SwiftBlockConfig(
            projectName: "TuistSPMApp",
            bundlePrefix: "com.mycompany",
            packaging: PackagingConfig(feature: "spm", core: "spm"),
            organization: "feature-first",
            generatorTool: .tuist,
            guardrails: GuardrailsConfig.all,
            cicd: CICDConfig(provider: .githubActions),
            gitInit: true
        )

        let options = ProjectGeneratorOptions(
            projectName: "TuistSPMApp",
            bundlePrefix: "com.mycompany",
            templatePath: "/usr/local/share/swiftblock/Blocks/Projects/BaseProject-SwiftUI",
            outputPath: projectPath,
            customConfig: config
        )

        // 1. Generate Base Project
        let projectGen = ProjectGenerator()
        
        // Prepare mock template if share directory does not exist in unit test runner environment
        let mockTemplate = tempDir.appendingPathComponent("MockTemplate").path
        try FileManager.default.createDirectory(atPath: "\(mockTemplate)/App/Sources", withIntermediateDirectories: true)
        try "// Main App".write(toFile: "\(mockTemplate)/App/Sources/Main.swift", atomically: true, encoding: .utf8)
        
        var finalOptions = options
        finalOptions.templatePath = mockTemplate

        try projectGen.generateProject(options: finalOptions)

        // 2. Validate Core SPM package is created with non-empty Swift source
        let corePackageFile = "\(projectPath)/Packages/Core/Package.swift"
        let coreSwiftFile = "\(projectPath)/Packages/Core/Sources/Core/Core.swift"
        #expect(FileManager.default.fileExists(atPath: corePackageFile))
        #expect(FileManager.default.fileExists(atPath: coreSwiftFile))

        let coreSwiftContent = try String(contentsOfFile: coreSwiftFile, encoding: .utf8)
        #expect(coreSwiftContent.contains("public struct CoreModule"))

        // 3. Validate Tuist Project.swift manifest
        let manifestFile = "\(projectPath)/Project.swift"
        #expect(FileManager.default.fileExists(atPath: manifestFile))
        let manifestContent = try String(contentsOfFile: manifestFile, encoding: .utf8)
        #expect(manifestContent.contains("name: \"TuistSPMApp\""))
        #expect(manifestContent.contains("bundleId: \"com.mycompany.TuistSPMApp\""))
        #expect(manifestContent.contains("Packages/Core"))

        // 4. Validate Environment Setup Files
        #expect(FileManager.default.fileExists(atPath: "\(projectPath)/Makefile"))
        #expect(FileManager.default.fileExists(atPath: "\(projectPath)/.mise.toml"))
        #expect(FileManager.default.fileExists(atPath: "\(projectPath)/Scripts/setup.sh"))

        // 5. Validate Guardrail configs
        #expect(FileManager.default.fileExists(atPath: "\(projectPath)/.swiftlint.yml"))
        #expect(FileManager.default.fileExists(atPath: "\(projectPath)/.swiftformat"))
        #expect(FileManager.default.fileExists(atPath: "\(projectPath)/.pre-commit-config.yaml"))
        #expect(FileManager.default.fileExists(atPath: "\(projectPath)/.periphery.yml"))
        #expect(FileManager.default.fileExists(atPath: "\(projectPath)/Dangerfile.swift"))
        #expect(FileManager.default.fileExists(atPath: "\(projectPath)/swiftgen.yml"))

        // 6. Validate CI/CD pipeline
        #expect(FileManager.default.fileExists(atPath: "\(projectPath)/.github/workflows/ci.yml"))

        // 7. Validate Git repository
        #expect(FileManager.default.fileExists(atPath: "\(projectPath)/.git"))
        #expect(FileManager.default.fileExists(atPath: "\(projectPath)/.gitignore"))

        // 8. Test adding a Feature Module (Scene)
        let moduleGen = ModuleGenerator()
        
        let mockModuleTemplate = tempDir.appendingPathComponent("MockModuleTemplate").path
        try FileManager.default.createDirectory(atPath: "\(mockModuleTemplate)/Scene", withIntermediateDirectories: true)
        try "// Scene View".write(toFile: "\(mockModuleTemplate)/Scene/__MODULE_NAME__View.swift", atomically: true, encoding: .utf8)

        let moduleOptions = ModuleGeneratorOptions(
            type: .scene,
            moduleName: "Home",
            projectRootPath: projectPath,
            modulesTemplatePath: mockModuleTemplate
        )
        let generatedModulePath = try moduleGen.generateModule(options: moduleOptions)
        #expect(FileManager.default.fileExists(atPath: generatedModulePath))

        // Validate SPM feature package if SPM strategy selected
        let pkgGen = LocalPackageGenerator()
        try pkgGen.generateFeaturePackage(moduleName: "Home", in: projectPath, config: config)
        let featureSwiftFile = "\(projectPath)/Packages/HomeFeature/Sources/HomeFeature/HomeFeature.swift"
        #expect(FileManager.default.fileExists(atPath: featureSwiftFile))
    }

    @Test func testE2EXcodeGenMonolithicMatrix() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("E2E_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let projectPath = tempDir.appendingPathComponent("XcodeGenMonoApp").path

        let config = SwiftBlockConfig(
            projectName: "XcodeGenMonoApp",
            bundlePrefix: "com.testorg",
            packaging: PackagingConfig(feature: "monolithic", core: "monolithic"),
            organization: "technical-first",
            generatorTool: .xcodegen,
            guardrails: GuardrailsConfig(
                swiftlint: true,
                swiftformat: true,
                precommit: false,
                periphery: false,
                gitleaks: false,
                danger: false,
                swiftgen: false,
                licenseplist: false
            ),
            cicd: CICDConfig(provider: .xcodeCloud),
            gitInit: false
        )

        let mockTemplate = tempDir.appendingPathComponent("MockTemplate").path
        try FileManager.default.createDirectory(atPath: "\(mockTemplate)/App/Sources", withIntermediateDirectories: true)
        try "// Main App".write(toFile: "\(mockTemplate)/App/Sources/Main.swift", atomically: true, encoding: .utf8)

        let options = ProjectGeneratorOptions(
            projectName: "XcodeGenMonoApp",
            bundlePrefix: "com.testorg",
            templatePath: mockTemplate,
            outputPath: projectPath,
            customConfig: config
        )

        let projectGen = ProjectGenerator()
        try projectGen.generateProject(options: options)

        // 1. Validate XcodeGen project.yml
        let projectYml = "\(projectPath)/project.yml"
        #expect(FileManager.default.fileExists(atPath: projectYml))
        let content = try String(contentsOfFile: projectYml, encoding: .utf8)
        #expect(content.contains("name: XcodeGenMonoApp"))
        #expect(content.contains("bundleIdPrefix: com.testorg"))

        // 2. Validate Xcode Cloud CI script
        #expect(FileManager.default.fileExists(atPath: "\(projectPath)/ci_scripts/ci_post_clone.sh"))

        // 3. Validate selective guardrails (.swiftlint.yml present, Dangerfile.swift absent)
        #expect(FileManager.default.fileExists(atPath: "\(projectPath)/.swiftlint.yml"))
        #expect(!FileManager.default.fileExists(atPath: "\(projectPath)/Dangerfile.swift"))

        // 4. Validate gitInit == false
        #expect(!FileManager.default.fileExists(atPath: "\(projectPath)/.git"))
    }
}
