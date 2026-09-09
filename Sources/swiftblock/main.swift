import ArgumentParser
import Foundation
import SwiftBlockCore

@main
struct SwiftBlock: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swiftblock",
        abstract: "Swift project and architecture module generator CLI",
        subcommands: [Init.self, Add.self]
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
    var templatePath: String = "/usr/local/share/swiftblock/Templates/Projects/BaseProject-SwiftUI"

    func run() throws {
        print("🛠️ Generating project: \(projectName)")

        let options = ProjectGeneratorOptions(
            projectName: projectName,
            bundlePrefix: bundlePrefix,
            templatePath: templatePath
        )

        let generator = ProjectGenerator()

        do {
            try generator.generateProject(options: options)
            print("✅ Project created at \(options.outputPath)")
            print("🔁 Placeholders replaced with \(projectName) (bundle prefix: \(bundlePrefix))")
        } catch {
            print("❌ \(error.localizedDescription)")
            throw ExitCode.failure
        }
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
    var templatePath: String = "/usr/local/share/swiftblock/Templates/Modules"

    func run() throws {
        try executeAddModule(type: .scene, moduleName: name, templatePath: templatePath)
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
    var templatePath: String = "/usr/local/share/swiftblock/Templates/Modules"

    func run() throws {
        try executeAddModule(type: .usecase, moduleName: name, templatePath: templatePath)
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
    var templatePath: String = "/usr/local/share/swiftblock/Templates/Modules"

    func run() throws {
        try executeAddModule(type: .repository, moduleName: name, templatePath: templatePath)
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
    var templatePath: String = "/usr/local/share/swiftblock/Templates/Modules"

    func run() throws {
        try executeAddModule(type: .service, moduleName: name, templatePath: templatePath)
    }
}

private func executeAddModule(type: ModuleType, moduleName: String, templatePath: String) throws {
    print("🧩 Adding \(type.rawValue) module: \(moduleName)")

    let options = ModuleGeneratorOptions(
        type: type,
        moduleName: moduleName,
        modulesTemplatePath: templatePath
    )

    let generator = ModuleGenerator()

    do {
        let generatedPath = try generator.generateModule(options: options)
        print("✅ Generated \(type.rawValue) module '\(moduleName)' at \(generatedPath)")
    } catch {
        print("❌ \(error.localizedDescription)")
        throw ExitCode.failure
    }
}
