import ArgumentParser
import Foundation
import SwiftBlockCore

@main
struct SwiftBlock: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swiftblock",
        abstract: "Swift project and architecture module generator CLI",
        subcommands: [Init.self, New.self, Add.self]
    )
}

struct Init: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Initialize a new SwiftUI project using Tuist, SwiftLint, SwiftFormat, and Makefile"
    )

    @Argument(help: "Project name")
    var projectName: String

    @Option(name: [.customShort("b"), .long], help: "Bundle identifier prefix (default: io.ardyan)")
    var bundlePrefix: String = "io.ardyan"

    @Option(name: [.customShort("t"), .long], help: "Custom project template path")
    var templatePath: String = "/usr/local/share/swiftblock/Blocks/Projects/BaseProject-SwiftUI"

    @Flag(name: .long, help: "Simulate project generation without writing to disk")
    var dryRun: Bool = false

    func run() throws {
        try executeInitProject(projectName: projectName, bundlePrefix: bundlePrefix, templatePath: templatePath, isDryRun: dryRun)
    }
}

struct New: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "new",
        abstract: "Create a new SwiftUI project (alias for 'init')"
    )

    @Argument(help: "Project name")
    var projectName: String

    @Option(name: [.customShort("b"), .long], help: "Bundle identifier prefix (default: io.ardyan)")
    var bundlePrefix: String = "io.ardyan"

    @Option(name: [.customShort("t"), .long], help: "Custom project template path")
    var templatePath: String = "/usr/local/share/swiftblock/Blocks/Projects/BaseProject-SwiftUI"

    @Flag(name: .long, help: "Simulate project generation without writing to disk")
    var dryRun: Bool = false

    func run() throws {
        try executeInitProject(projectName: projectName, bundlePrefix: bundlePrefix, templatePath: templatePath, isDryRun: dryRun)
    }
}

private func executeInitProject(projectName: String, bundlePrefix: String, templatePath: String, isDryRun: Bool) throws {
    print("🛠️ Generating project: \(projectName)")

    let options = ProjectGeneratorOptions(
        projectName: projectName,
        bundlePrefix: bundlePrefix,
        templatePath: templatePath,
        isDryRun: isDryRun
    )

    let generator = ProjectGenerator()

    do {
        try generator.generateProject(options: options)
        if !isDryRun {
            print("✅ Project created at \(options.outputPath)")
            print("🔁 Placeholders replaced with \(projectName) (bundle prefix: \(bundlePrefix))")
        }
    } catch {
        print("❌ \(error.localizedDescription)")
        throw ExitCode.failure
    }
}

struct Add: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add",
        abstract: "Add a new architecture module block to current project",
        subcommands: [AddScene.self, AddUseCase.self, AddRepository.self, AddService.self]
    )
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

private func executeAddModule(type: ModuleType, moduleName: String, templatePath: String, isDryRun: Bool) throws {
    print("🧩 Adding \(type.rawValue) module: \(moduleName)")

    let options = ModuleGeneratorOptions(
        type: type,
        moduleName: moduleName,
        modulesTemplatePath: templatePath,
        isDryRun: isDryRun
    )

    let generator = ModuleGenerator()

    do {
        let generatedPath = try generator.generateModule(options: options)
        if !isDryRun {
            print("✅ Generated \(type.rawValue) module '\(moduleName)' at \(generatedPath)")
        }
    } catch {
        print("❌ \(error.localizedDescription)")
        throw ExitCode.failure
    }
}
