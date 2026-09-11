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

    @Test func testE2EKitCreationAndExecutionMatrix() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("E2E_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let projectPath = tempDir.appendingPathComponent("KitApp").path

        // 1. Initialize project & config
        var config = SwiftBlockConfig(
            projectName: "KitApp",
            bundlePrefix: "com.testorg",
            packaging: PackagingConfig(feature: "monolithic", core: "monolithic"),
            organization: "feature-first",
            generatorTool: .tuist
        )

        let mockTemplate = tempDir.appendingPathComponent("MockTemplate").path
        try FileManager.default.createDirectory(atPath: "\(mockTemplate)/App/Sources", withIntermediateDirectories: true)
        try "// Main App".write(toFile: "\(mockTemplate)/App/Sources/Main.swift", atomically: true, encoding: .utf8)

        let mockModuleTemplate = tempDir.appendingPathComponent("MockModuleTemplate").path
        let blockTypes = ["Scene", "Usecase", "Repository", "Service", "Mapper"]
        for block in blockTypes {
            try FileManager.default.createDirectory(atPath: "\(mockModuleTemplate)/\(block)", withIntermediateDirectories: true)
            try "// \(block)".write(toFile: "\(mockModuleTemplate)/\(block)/__MODULE_NAME__\(block).swift", atomically: true, encoding: .utf8)
        }

        let options = ProjectGeneratorOptions(
            projectName: "KitApp",
            bundlePrefix: "com.testorg",
            templatePath: mockTemplate,
            outputPath: projectPath,
            customConfig: config
        )

        let projectGen = ProjectGenerator()
        try projectGen.generateProject(options: options)

        // 2. Add and save a custom kit to .swiftblock
        config.kits["custom_auth"] = ["scene", "usecase", "service"]
        try config.save(to: projectPath)

        let loadedConfig = try SwiftBlockConfig.load(from: projectPath)
        #expect(loadedConfig.kits["custom_auth"] == ["scene", "usecase", "service"])
        #expect(loadedConfig.kits["feature"] == ["scene", "usecase", "repository", "mapper"])

        // 3. Execute custom kit 'custom_auth' for module 'Auth'
        let engine = KitEngine()
        let resultAuth = try engine.executeKit(
            name: "custom_auth",
            moduleName: "Auth",
            config: loadedConfig,
            templatePath: mockModuleTemplate,
            projectPath: projectPath
        )

        #expect(resultAuth.kitName == "custom_auth")
        #expect(resultAuth.moduleName == "Auth")
        #expect(resultAuth.generatedBricks == [.scene, .usecase, .service])
        #expect(FileManager.default.fileExists(atPath: "\(projectPath)/App/Sources/Features/auth/scene/AuthScene.swift"))
        #expect(FileManager.default.fileExists(atPath: "\(projectPath)/App/Sources/Features/auth/usecase/AuthUsecase.swift"))
        #expect(FileManager.default.fileExists(atPath: "\(projectPath)/App/Sources/Features/auth/service/AuthService.swift"))

        // 4. Execute built-in kit 'feature' for module 'Settings'
        let resultSettings = try engine.executeKit(
            name: "feature",
            moduleName: "Settings",
            config: loadedConfig,
            templatePath: mockModuleTemplate,
            projectPath: projectPath
        )

        #expect(resultSettings.kitName == "feature")
        #expect(resultSettings.moduleName == "Settings")
        #expect(resultSettings.generatedBricks == [.scene, .usecase, .repository, .mapper])
        #expect(FileManager.default.fileExists(atPath: "\(projectPath)/App/Sources/Features/settings/scene/SettingsScene.swift"))
        #expect(FileManager.default.fileExists(atPath: "\(projectPath)/App/Sources/Features/settings/usecase/SettingsUsecase.swift"))
        #expect(FileManager.default.fileExists(atPath: "\(projectPath)/App/Sources/Features/settings/repository/SettingsRepository.swift"))
        #expect(FileManager.default.fileExists(atPath: "\(projectPath)/App/Sources/Features/settings/mapper/SettingsMapper.swift"))
    }

    @Test func testE2EWizardMatrixFullPermutations() throws {
        let ciProviders: [CICDProvider] = [.githubActions, .gitlabCI, .bitrise, .xcodeCloud, .none]
        let buildTools: [ProjectGeneratorTool] = [.tuist, .xcodegen]
        let orgStrategies = ["feature-first", "technical-first"]

        for tool in buildTools {
            for provider in ciProviders {
                for org in orgStrategies {
                    let tempDir = FileManager.default.temporaryDirectory
                        .appendingPathComponent("E2E_Matrix_\(UUID().uuidString)", isDirectory: true)
                    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
                    defer {
                        try? FileManager.default.removeItem(at: tempDir)
                    }

                    let projName = "MatrixApp"
                    let projectPath = tempDir.appendingPathComponent(projName).path

                    let config = SwiftBlockConfig(
                        projectName: projName,
                        bundlePrefix: "com.matrix",
                        packaging: PackagingConfig(feature: "spm", core: "spm"),
                        organization: org,
                        generatorTool: tool,
                        guardrails: GuardrailsConfig.all,
                        cicd: CICDConfig(provider: provider),
                        gitInit: true
                    )

                    let mockTemplate = tempDir.appendingPathComponent("MockTemplate").path
                    try FileManager.default.createDirectory(atPath: "\(mockTemplate)/App/Sources", withIntermediateDirectories: true)
                    try "// Main App".write(toFile: "\(mockTemplate)/App/Sources/Main.swift", atomically: true, encoding: .utf8)
                    try FileManager.default.createDirectory(atPath: "\(mockTemplate)/App/Tests", withIntermediateDirectories: true)
                    try "// Test".write(toFile: "\(mockTemplate)/App/Tests/__PROJECT_NAME__Tests.swift", atomically: true, encoding: .utf8)

                    let options = ProjectGeneratorOptions(
                        projectName: projName,
                        bundlePrefix: "com.matrix",
                        templatePath: mockTemplate,
                        outputPath: projectPath,
                        customConfig: config
                    )

                    let projectGen = ProjectGenerator()
                    try projectGen.generateProject(options: options)

                    // 1. Verify Manifest
                    if tool == .tuist {
                        #expect(FileManager.default.fileExists(atPath: "\(projectPath)/Project.swift"))
                    } else {
                        #expect(FileManager.default.fileExists(atPath: "\(projectPath)/project.yml"))
                    }

                    // 2. Verify CI/CD
                    switch provider {
                    case .githubActions:
                        #expect(FileManager.default.fileExists(atPath: "\(projectPath)/.github/workflows/ci.yml"))
                    case .gitlabCI:
                        #expect(FileManager.default.fileExists(atPath: "\(projectPath)/.gitlab-ci.yml"))
                    case .bitrise:
                        #expect(FileManager.default.fileExists(atPath: "\(projectPath)/bitrise.yml"))
                    case .xcodeCloud:
                        #expect(FileManager.default.fileExists(atPath: "\(projectPath)/ci_scripts/ci_post_clone.sh"))
                    case .none:
                        #expect(!FileManager.default.fileExists(atPath: "\(projectPath)/.github/workflows/ci.yml"))
                        #expect(!FileManager.default.fileExists(atPath: "\(projectPath)/.gitlab-ci.yml"))
                        #expect(!FileManager.default.fileExists(atPath: "\(projectPath)/bitrise.yml"))
                        #expect(!FileManager.default.fileExists(atPath: "\(projectPath)/ci_scripts/ci_post_clone.sh"))
                    }

                    // 3. Verify .swiftblock config
                    let loaded = try SwiftBlockConfig.load(from: projectPath)
                    #expect(loaded.projectName == projName)
                    #expect(loaded.generatorTool == tool)
                    #expect(loaded.cicd.provider == provider)
                    #expect(loaded.organization == org)

                    // 4. Verify starter unit test file
                    #expect(FileManager.default.fileExists(atPath: "\(projectPath)/App/Tests/MatrixAppTests.swift"))
                }
            }
        }
    }
}

