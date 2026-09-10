import ArgumentParser
import Foundation
import SwiftBlockCore

@main
struct SwiftBlock: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swiftblock",
        abstract: "Swift project and architecture module generator CLI",
        subcommands: [Init.self, New.self, Add.self, CoreCommand.self]
    )
}

struct Init: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Initialize a new SwiftUI project using Tuist, SwiftLint, SwiftFormat, and Makefile"
    )

    @Argument(help: "Project name (optional, triggers wizard if omitted)")
    var projectName: String?

    @Option(name: [.customShort("b"), .long], help: "Bundle identifier prefix (default: com.example)")
    var bundlePrefix: String = "com.example"

    @Option(name: [.customShort("t"), .long], help: "Custom project template path")
    var templatePath: String = "/usr/local/share/swiftblock/Blocks/Projects/BaseProject-SwiftUI"

    @Flag(name: .long, help: "Simulate project generation without writing to disk")
    var dryRun: Bool = false

    func run() throws {
        if let projectName = projectName, !projectName.isEmpty {
            try executeInitProject(projectName: projectName, bundlePrefix: bundlePrefix, templatePath: templatePath, isDryRun: dryRun)
        } else {
            let options = try InteractiveWizard.runProjectWizard(defaultTemplatePath: templatePath)
            var finalOptions = options
            finalOptions.isDryRun = dryRun
            try executeWithOptions(options: finalOptions)
        }
    }
}

struct New: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "new",
        abstract: "Create a new SwiftUI project (alias for 'init')"
    )

    @Argument(help: "Project name (optional, triggers wizard if omitted)")
    var projectName: String?

    @Option(name: [.customShort("b"), .long], help: "Bundle identifier prefix (default: com.example)")
    var bundlePrefix: String = "com.example"

    @Option(name: [.customShort("t"), .long], help: "Custom project template path")
    var templatePath: String = "/usr/local/share/swiftblock/Blocks/Projects/BaseProject-SwiftUI"

    @Flag(name: .long, help: "Simulate project generation without writing to disk")
    var dryRun: Bool = false

    func run() throws {
        if let projectName = projectName, !projectName.isEmpty {
            try executeInitProject(projectName: projectName, bundlePrefix: bundlePrefix, templatePath: templatePath, isDryRun: dryRun)
        } else {
            let options = try InteractiveWizard.runProjectWizard(defaultTemplatePath: templatePath)
            var finalOptions = options
            finalOptions.isDryRun = dryRun
            try executeWithOptions(options: finalOptions)
        }
    }
}

private func executeInitProject(projectName: String, bundlePrefix: String, templatePath: String, isDryRun: Bool) throws {
    let options = ProjectGeneratorOptions(
        projectName: projectName,
        bundlePrefix: bundlePrefix,
        templatePath: templatePath,
        isDryRun: isDryRun
    )
    try executeWithOptions(options: options)
}

private func executeWithOptions(options: ProjectGeneratorOptions) throws {
    print("🛠️ Generating project: \(options.projectName)")
    let generator = ProjectGenerator()

    do {
        try generator.generateProject(options: options)
        if !options.isDryRun {
            print("✅ Project created at \(options.outputPath)")
            print("🔁 Placeholders replaced with \(options.projectName) (bundle prefix: \(options.bundlePrefix))")
        }
    } catch {
        print("❌ \(error.localizedDescription)")
        throw ExitCode.failure
    }
}

struct Add: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add",
        abstract: "Add a feature architecture block to current project",
        subcommands: [
            AddScene.self,
            AddUseCase.self,
            AddRepository.self,
            AddService.self,
            AddEntity.self,
            AddCoordinator.self,
            AddComponent.self,
            AddMapper.self,
            AddValidator.self
        ]
    )

    @Option(name: [.customShort("t"), .long], help: "Custom modules template path")
    var templatePath: String = "/usr/local/share/swiftblock/Blocks/Modules"

    @Flag(name: .long, help: "Simulate module generation without writing to disk")
    var dryRun: Bool = false

    func run() throws {
        let options = try InteractiveWizard.runModuleWizard(defaultTemplatePath: templatePath)
        var finalOptions = options
        finalOptions.isDryRun = dryRun
        try executeAddModuleWithOptions(options: finalOptions)
    }
}

struct AddScene: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "scene",
        abstract: "Add a new MVVM Scene (View + ViewModel + State)"
    )

    @Argument(help: "Scene module name")
    var name: String

    @Option(name: [.customShort("t"), .long], help: "Custom modules template path")
    var templatePath: String = "/usr/local/share/swiftblock/Blocks/Modules"

    @Flag(name: .long, help: "Simulate module generation without writing to disk")
    var dryRun: Bool = false

    func run() throws {
        try executeAddModule(type: .scene, moduleName: name, templatePath: templatePath, isDryRun: dryRun)
    }
}

struct AddUseCase: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "usecase",
        abstract: "Add a new Domain UseCase (Protocol + Default Implementation)"
    )

    @Argument(help: "UseCase module name")
    var name: String

    @Option(name: [.customShort("t"), .long], help: "Custom modules template path")
    var templatePath: String = "/usr/local/share/swiftblock/Blocks/Modules"

    @Flag(name: .long, help: "Simulate module generation without writing to disk")
    var dryRun: Bool = false

    func run() throws {
        try executeAddModule(type: .usecase, moduleName: name, templatePath: templatePath, isDryRun: dryRun)
    }
}

struct AddRepository: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "repository",
        abstract: "Add a new Data Repository (Protocol + Default Implementation)"
    )

    @Argument(help: "Repository module name")
    var name: String

    @Option(name: [.customShort("t"), .long], help: "Custom modules template path")
    var templatePath: String = "/usr/local/share/swiftblock/Blocks/Modules"

    @Flag(name: .long, help: "Simulate module generation without writing to disk")
    var dryRun: Bool = false

    func run() throws {
        try executeAddModule(type: .repository, moduleName: name, templatePath: templatePath, isDryRun: dryRun)
    }
}

struct AddService: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "service",
        abstract: "Add a new API Service (Protocol + Default Implementation)"
    )

    @Argument(help: "Service module name")
    var name: String

    @Option(name: [.customShort("t"), .long], help: "Custom modules template path")
    var templatePath: String = "/usr/local/share/swiftblock/Blocks/Modules"

    @Flag(name: .long, help: "Simulate module generation without writing to disk")
    var dryRun: Bool = false

    func run() throws {
        try executeAddModule(type: .service, moduleName: name, templatePath: templatePath, isDryRun: dryRun)
    }
}

struct AddEntity: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "entity",
        abstract: "Add a new Domain Entity / DTO Model"
    )

    @Argument(help: "Entity module name")
    var name: String

    @Option(name: [.customShort("t"), .long], help: "Custom modules template path")
    var templatePath: String = "/usr/local/share/swiftblock/Blocks/Modules"

    @Flag(name: .long, help: "Simulate module generation without writing to disk")
    var dryRun: Bool = false

    func run() throws {
        try executeAddModule(type: .entity, moduleName: name, templatePath: templatePath, isDryRun: dryRun)
    }
}

struct AddCoordinator: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "coordinator",
        abstract: "Add a new Navigation Coordinator (MVVM-C Flow Router)"
    )

    @Argument(help: "Coordinator module name")
    var name: String

    @Option(name: [.customShort("t"), .long], help: "Custom modules template path")
    var templatePath: String = "/usr/local/share/swiftblock/Blocks/Modules"

    @Flag(name: .long, help: "Simulate module generation without writing to disk")
    var dryRun: Bool = false

    func run() throws {
        try executeAddModule(type: .coordinator, moduleName: name, templatePath: templatePath, isDryRun: dryRun)
    }
}

struct AddComponent: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "component",
        abstract: "Add a new Reusable UI Component Block"
    )

    @Argument(help: "Component module name")
    var name: String

    @Option(name: [.customShort("t"), .long], help: "Custom modules template path")
    var templatePath: String = "/usr/local/share/swiftblock/Blocks/Modules"

    @Flag(name: .long, help: "Simulate module generation without writing to disk")
    var dryRun: Bool = false

    func run() throws {
        try executeAddModule(type: .component, moduleName: name, templatePath: templatePath, isDryRun: dryRun)
    }
}

struct AddMapper: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mapper",
        abstract: "Add a new Data Mapper / DTO Transformer Block"
    )

    @Argument(help: "Mapper module name")
    var name: String

    @Option(name: [.customShort("t"), .long], help: "Custom modules template path")
    var templatePath: String = "/usr/local/share/swiftblock/Blocks/Modules"

    @Flag(name: .long, help: "Simulate module generation without writing to disk")
    var dryRun: Bool = false

    func run() throws {
        try executeAddModule(type: .mapper, moduleName: name, templatePath: templatePath, isDryRun: dryRun)
    }
}

struct AddValidator: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "validator",
        abstract: "Add a new Form Input Field Validator Block"
    )

    @Argument(help: "Validator module name")
    var name: String

    @Option(name: [.customShort("t"), .long], help: "Custom modules template path")
    var templatePath: String = "/usr/local/share/swiftblock/Blocks/Modules"

    @Flag(name: .long, help: "Simulate module generation without writing to disk")
    var dryRun: Bool = false

    func run() throws {
        try executeAddModule(type: .validator, moduleName: name, templatePath: templatePath, isDryRun: dryRun)
    }
}

struct CoreCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "core",
        abstract: "Add a core foundation block to current project (Storage, Network, Logger, Analytics, Config, Auth, FeatureFlag)",
        subcommands: [
            CoreStorage.self,
            CoreNetwork.self,
            CoreLogger.self,
            CoreAnalytics.self,
            CoreConfig.self,
            CoreAuth.self,
            CoreFeatureFlag.self
        ]
    )

    @Option(name: [.customShort("t"), .long], help: "Custom core templates path")
    var templatePath: String = "/usr/local/share/swiftblock/Blocks/Core"

    @Flag(name: .long, help: "Simulate block generation without writing to disk")
    var dryRun: Bool = false

    func run() throws {
        let options = try InteractiveWizard.runCoreWizard(defaultTemplatePath: templatePath)
        var finalOptions = options
        finalOptions.isDryRun = dryRun
        try executeAddModuleWithOptions(options: finalOptions)
    }
}

struct CoreStorage: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "storage",
        abstract: "Add a new Local Persistence Storage Block"
    )

    @Argument(help: "Storage block name")
    var name: String

    @Option(name: [.customShort("t"), .long], help: "Custom core templates path")
    var templatePath: String = "/usr/local/share/swiftblock/Blocks/Core"

    @Flag(name: .long, help: "Simulate block generation without writing to disk")
    var dryRun: Bool = false

    func run() throws {
        try executeAddModule(type: .storage, moduleName: name, templatePath: templatePath, isDryRun: dryRun)
    }
}

struct CoreNetwork: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "network",
        abstract: "Add a new Network Client / HTTP Engine Block"
    )

    @Argument(help: "Network block name")
    var name: String

    @Option(name: [.customShort("t"), .long], help: "Custom core templates path")
    var templatePath: String = "/usr/local/share/swiftblock/Blocks/Core"

    @Flag(name: .long, help: "Simulate block generation without writing to disk")
    var dryRun: Bool = false

    func run() throws {
        try executeAddModule(type: .network, moduleName: name, templatePath: templatePath, isDryRun: dryRun)
    }
}

struct CoreLogger: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "logger",
        abstract: "Add a new Unified Logger Block"
    )

    @Argument(help: "Logger block name")
    var name: String

    @Option(name: [.customShort("t"), .long], help: "Custom core templates path")
    var templatePath: String = "/usr/local/share/swiftblock/Blocks/Core"

    @Flag(name: .long, help: "Simulate block generation without writing to disk")
    var dryRun: Bool = false

    func run() throws {
        try executeAddModule(type: .logger, moduleName: name, templatePath: templatePath, isDryRun: dryRun)
    }
}

struct CoreAnalytics: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "analytics",
        abstract: "Add a new Event Analytics Engine Block"
    )

    @Argument(help: "Analytics block name")
    var name: String

    @Option(name: [.customShort("t"), .long], help: "Custom core templates path")
    var templatePath: String = "/usr/local/share/swiftblock/Blocks/Core"

    @Flag(name: .long, help: "Simulate block generation without writing to disk")
    var dryRun: Bool = false

    func run() throws {
        try executeAddModule(type: .analytics, moduleName: name, templatePath: templatePath, isDryRun: dryRun)
    }
}

struct CoreConfig: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "config",
        abstract: "Add a new Environment Config & Feature Flags Block"
    )

    @Argument(help: "Config block name")
    var name: String

    @Option(name: [.customShort("t"), .long], help: "Custom core templates path")
    var templatePath: String = "/usr/local/share/swiftblock/Blocks/Core"

    @Flag(name: .long, help: "Simulate block generation without writing to disk")
    var dryRun: Bool = false

    func run() throws {
        try executeAddModule(type: .config, moduleName: name, templatePath: templatePath, isDryRun: dryRun)
    }
}

struct CoreAuth: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "auth",
        abstract: "Add a new User Session & Token State Manager Block"
    )

    @Argument(help: "Auth block name")
    var name: String

    @Option(name: [.customShort("t"), .long], help: "Custom core templates path")
    var templatePath: String = "/usr/local/share/swiftblock/Blocks/Core"

    @Flag(name: .long, help: "Simulate block generation without writing to disk")
    var dryRun: Bool = false

    func run() throws {
        try executeAddModule(type: .auth, moduleName: name, templatePath: templatePath, isDryRun: dryRun)
    }
}

struct CoreFeatureFlag: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "featureflag",
        abstract: "Add a new Feature Flags & Remote Toggles Engine Block"
    )

    @Argument(help: "FeatureFlag block name")
    var name: String

    @Option(name: [.customShort("t"), .long], help: "Custom core templates path")
    var templatePath: String = "/usr/local/share/swiftblock/Blocks/Core"

    @Flag(name: .long, help: "Simulate block generation without writing to disk")
    var dryRun: Bool = false

    func run() throws {
        try executeAddModule(type: .featureflag, moduleName: name, templatePath: templatePath, isDryRun: dryRun)
    }
}


private func executeAddModule(type: ModuleType, moduleName: String, templatePath: String, isDryRun: Bool) throws {
    let options = ModuleGeneratorOptions(
        type: type,
        moduleName: moduleName,
        modulesTemplatePath: templatePath,
        isDryRun: isDryRun
    )
    try executeAddModuleWithOptions(options: options)
}

private func executeAddModuleWithOptions(options: ModuleGeneratorOptions) throws {
    print("🧩 Adding \(options.type.rawValue) block: \(options.moduleName)")
    let generator = ModuleGenerator()

    do {
        let generatedPath = try generator.generateModule(options: options)
        if !options.isDryRun {
            print("✅ Generated \(options.type.rawValue) block '\(options.moduleName)' at \(generatedPath)")
        }
    } catch {
        print("❌ \(error.localizedDescription)")
        throw ExitCode.failure
    }
}

