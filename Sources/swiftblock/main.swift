import ArgumentParser
import Foundation
import SwiftBlockCore

@main
struct SwiftBlock: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swiftblock",
        abstract: "Swift building blocks to create anything: project and architecture generator CLI",
        subcommands: [
            BaseplateCommand.self,
            SnapCommand.self,
            KitCommand.self,
            BoxCommand.self,
            DoctorCommand.self,
            // Keep aliases accessible at root level
            Init.self,
            New.self,
            Add.self,
            CoreCommand.self
        ],
        defaultSubcommand: DoctorCommand.self
    )
}

struct BaseplateCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "baseplate",
        abstract: "Lay down a new SwiftUI project baseplate using Tuist or XcodeGen",
        aliases: ["new", "init"]
    )

    @Argument(help: "Project name (optional, triggers interactive setup if omitted)")
    var projectName: String?

    @Option(name: [.customShort("p"), .customLong("bundle-prefix"), .customLong("prefix")], help: "Bundle identifier prefix (default: com.company)")
    var bundlePrefix: String = "com.company"

    @Option(name: [.customShort("t"), .long], help: "Custom project template path")
    var templatePath: String?

    @Option(name: .long, help: "Build tool generator: tuist or xcodegen (default: tuist)")
    var tool: String = "tuist"

    @Flag(name: .long, help: "Simulate project generation without writing to disk")
    var dryRun: Bool = false

    @Flag(name: [.customShort("v"), .long], help: "Enable verbose step-by-step log output")
    var verbose: Bool = false

    func run() throws {
        if let projectName = projectName, !projectName.isEmpty {
            let toolEnum = ProjectGeneratorTool(rawValue: tool.lowercased()) ?? .tuist
            try executeInitProject(projectName: projectName, bundlePrefix: bundlePrefix, templatePath: templatePath, generatorTool: toolEnum, isDryRun: dryRun, isVerbose: verbose)
        } else {
            let options = try InteractiveWizard.runProjectWizard(defaultTemplatePath: templatePath ?? "")
            var finalOptions = options
            finalOptions.isDryRun = dryRun
            finalOptions.isVerbose = verbose
            try executeWithOptions(options: finalOptions)
        }
    }
}

struct SnapCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "snap",
        abstract: "Snap a singleton foundation or generative architectural brick into current project",
        aliases: ["use", "add"]
    )

    @Argument(help: "Brick name or direct Git URL (e.g. network, scene, storage, https://...)")
    var brick: String?

    @Argument(help: "Target module or brick instance name (e.g. Profile, Auth)")
    var name: String?

    @Option(name: [.customShort("t"), .long], help: "Custom bricks template directory path")
    var templatePath: String?

    @Flag(name: .long, help: "Simulate brick generation without writing to disk")
    var dryRun: Bool = false

    func run() throws {
        let baseDir = templatePath ?? FileManager.default.currentDirectoryPath
        let discoveryEngine = BlockDiscoveryEngine()
        
        guard let brickInput = brick else {
            // Interactive wizard when no arguments provided
            let options = try InteractiveWizard.runModuleWizard(defaultTemplatePath: baseDir)
            var finalOptions = options
            finalOptions.isDryRun = dryRun
            try executeAddModuleWithOptions(options: finalOptions)
            return
        }
        
        let normalizedBrick = brickInput.lowercased()

        // Direct Git URL Resolution
        if BoxManager.isGitURL(brickInput) {
            let boxManager = BoxManager()
            let fetched = try boxManager.fetchGitRepository(urlString: brickInput, isVerbose: true)
            var targetPath = fetched.cachedPath

            if let manifest = BrickManifest.load(fromPath: targetPath) {
                let instanceName = name ?? (manifest.instantiation == .generative ? "Main" : manifest.name.capitalized)
                let moduleType = ModuleType(rawValue: manifest.name.lowercased()) ?? .scene
                try executeAddModule(type: moduleType, moduleName: instanceName, templatePath: targetPath, isDryRun: dryRun)
                return
            }

            let discovered = boxManager.discoverMonorepoBricks(at: targetPath)
            if !discovered.isEmpty {
                let selected: (relativePath: String, manifest: BrickManifest)
                if discovered.count == 1 {
                    selected = discovered[0]
                } else {
                    selected = try InteractiveWizard.runMonorepoSelectionWizard(bricks: discovered)
                }
                let selectedPath = "\(targetPath)/\(selected.relativePath)"
                let instanceName = name ?? (selected.manifest.instantiation == .generative ? "Main" : selected.manifest.name.capitalized)
                let moduleType = ModuleType(rawValue: selected.manifest.name.lowercased()) ?? .scene
                try executeAddModule(type: moduleType, moduleName: instanceName, templatePath: selectedPath, isDryRun: dryRun)
                return
            }
        }
        
        // Smart Namespace Resolution
        if let resolvedPath = discoveryEngine.resolveBrickPath(named: brickInput, in: baseDir),
           let manifest = BrickManifest.load(fromPath: resolvedPath) {
            
            let instanceName = name ?? (manifest.instantiation == .generative ? "Main" : manifest.name.capitalized)
            let moduleType = ModuleType(rawValue: manifest.name.lowercased()) ?? .scene
            
            try executeAddModule(type: moduleType, moduleName: instanceName, templatePath: resolvedPath, isDryRun: dryRun)
            return
        }
        
        // Fallback for standard module type
        if let type = ModuleType(rawValue: normalizedBrick) {
            let instanceName = name ?? "Main"
            try executeAddModule(type: type, moduleName: instanceName, templatePath: baseDir, isDryRun: dryRun)
            return
        }
        
        print("❌ Brick '\(brickInput)' not found in local library or registry.")
        throw ExitCode.failure
    }
}

struct KitCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "kit",
        abstract: "Manage and execute multi-brick composition recipes (kits)",
        subcommands: [
            KitRun.self,
            KitList.self
        ],
        defaultSubcommand: KitList.self
    )
}

struct KitRun: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Execute a composition kit to batch generate multiple bricks"
    )

    @Argument(help: "Kit name (e.g. clean-feature)")
    var kitName: String

    @Argument(help: "Target module name (e.g. Profile, Auth)")
    var moduleName: String

    @Flag(name: .long, help: "Simulate kit generation without writing to disk")
    var dryRun: Bool = false

    func run() throws {
        let config = (try? SwiftBlockConfig.load()) ?? SwiftBlockConfig(projectName: "App")
        let engine = KitEngine()
        let result = try engine.executeKit(
            name: kitName,
            moduleName: moduleName,
            config: config,
            projectPath: FileManager.default.currentDirectoryPath,
            isDryRun: dryRun
        )
        if !dryRun {
            print("✔ Snapped kit '\(result.kitName)' for module '\(result.moduleName)' with bricks: \(result.generatedBricks.map { $0.rawValue }.joined(separator: ", "))")
        }
    }
}

struct KitList: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List all available composition kits"
    )

    func run() throws {
        let config = (try? SwiftBlockConfig.load()) ?? SwiftBlockConfig(projectName: "App")
        print("┌  \(ANSIColor.boldText("Available Composition Kits"))")
        print("│")
        if config.kits.isEmpty {
            print("│  • clean-feature: scene, usecase, repository, service")
            print("│  • mvvm-c: scene, coordinator")
        } else {
            for (name, composedBlocks) in config.kits.sorted(by: { $0.key < $1.key }) {
                print("│  • \(ANSIColor.boldText(name)): \(ANSIColor.cyanText(composedBlocks.joined(separator: ", ")))")
            }
        }
    }
}

struct BoxCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "box",
        abstract: "Manage remote team brick repositories (boxes)",
        subcommands: [
            BoxAdd.self,
            BoxList.self,
            BoxRemove.self,
            BoxUpdate.self
        ],
        defaultSubcommand: BoxList.self
    )
}

struct BoxAdd: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add",
        abstract: "Register and clone a remote team box repository"
    )

    @Argument(help: "Box name (e.g. company, core)")
    var name: String

    @Argument(help: "Git repository URL (e.g. https://github.com/company/ios-bricks.git)")
    var gitUrl: String

    func run() throws {
        let manager = BoxManager()
        try manager.addBox(name: name, gitURL: gitUrl, isVerbose: true)
        print("✔ Successfully registered box '\(name.lowercased())' from \(gitUrl)")
    }
}

struct BoxList: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List all registered boxes and cached bricks"
    )

    func run() throws {
        let manager = BoxManager()
        let boxes = manager.listBoxes()

        print("┌  \(ANSIColor.boldText("SwiftBlock Box Registry"))")
        print("│")
        if boxes.isEmpty {
            print("│  • official: Official SwiftBlock built-in library")
            print("│  (Use 'swiftblock box add <name> <git-url>' to register team boxes)")
        } else {
            print("│  • official: Official SwiftBlock built-in library")
            for (boxName, url) in boxes.sorted(by: { $0.key < $1.key }) {
                print("│  • \(ANSIColor.boldText(boxName)): \(ANSIColor.cyanText(url))")
                let boxPath = "\(manager.boxesDirectory)/\(boxName)"
                let discovered = manager.discoverMonorepoBricks(at: boxPath)
                for item in discovered {
                    print("│    └── \(item.manifest.name) (\(item.manifest.instantiation.rawValue))")
                }
            }
        }
    }
}

struct BoxRemove: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "remove",
        abstract: "Remove a registered box repository"
    )

    @Argument(help: "Box name to remove")
    var name: String

    func run() throws {
        let manager = BoxManager()
        try manager.removeBox(name: name)
        print("✔ Removed box '\(name.lowercased())'")
    }
}

struct BoxUpdate: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Pull latest changes for registered box repositories"
    )

    @Argument(help: "Optional box name to update")
    var name: String?

    func run() throws {
        let manager = BoxManager()
        try manager.updateBoxes(name: name, isVerbose: true)
        print("✔ Box repositories updated successfully.")
    }
}

struct DoctorCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "doctor",
        abstract: "Diagnose SwiftBlock environment, Xcode, Tuist, and XcodeGen tooling"
    )

    func run() throws {
        print("┌  \(ANSIColor.boldText("SwiftBlock System Diagnostics"))")
        print("│")
        
        let fm = FileManager.default
        let tuistInstalled = fm.fileExists(atPath: "/usr/local/bin/tuist") || fm.fileExists(atPath: "/opt/homebrew/bin/tuist")
        let xcodegenInstalled = fm.fileExists(atPath: "/usr/local/bin/xcodegen") || fm.fileExists(atPath: "/opt/homebrew/bin/xcodegen")
        
        print("│  \(tuistInstalled ? "[✓]" : "[!]") Tuist: \(tuistInstalled ? "Installed" : "Not found in standard PATH")")
        print("│  \(xcodegenInstalled ? "[✓]" : "[!]") XcodeGen: \(xcodegenInstalled ? "Installed" : "Not found in standard PATH")")
        print("│")
        print("└  \(ANSIColor.boldText("SwiftBlock environment is operational."))")
    }
}

// Legacy Aliases Structs
struct Init: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "init", abstract: "Initialize project (alias for baseplate)")
    @Argument var projectName: String?
    func run() throws {
        let cmd = BaseplateCommand()
        var copy = cmd
        copy.projectName = projectName
        try copy.run()
    }
}

struct New: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "new", abstract: "Create new project (alias for baseplate)")
    @Argument var projectName: String?
    func run() throws {
        let cmd = BaseplateCommand()
        var copy = cmd
        copy.projectName = projectName
        try copy.run()
    }
}

struct Add: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "add", abstract: "Add brick (alias for snap)")
    @Argument var block: String?
    @Argument var name: String?
    func run() throws {
        let cmd = SnapCommand()
        var copy = cmd
        copy.brick = block
        copy.name = name
        try copy.run()
    }
}

struct CoreCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "core", abstract: "Snap foundation brick")
    @Argument var block: String?
    @Argument var name: String?
    func run() throws {
        let cmd = SnapCommand()
        var copy = cmd
        copy.brick = block
        copy.name = name
        try copy.run()
    }
}



private func executeInitProject(projectName: String, bundlePrefix: String, templatePath: String?, generatorTool: ProjectGeneratorTool, isDryRun: Bool, isVerbose: Bool) throws {
    let config = SwiftBlockConfig(projectName: projectName, bundlePrefix: bundlePrefix, generatorTool: generatorTool)
    let options = ProjectGeneratorOptions(
        projectName: projectName,
        bundlePrefix: bundlePrefix,
        templatePath: templatePath,
        isDryRun: isDryRun,
        isVerbose: isVerbose,
        customConfig: config
    )
    try executeWithOptions(options: options)
}

private func executeWithOptions(options: ProjectGeneratorOptions) throws {
    print("◆ Laying down project baseplate: \(options.projectName)")
    let generator = ProjectGenerator()

    do {
        try generator.generateProject(options: options)
        if !options.isDryRun {
            print("✔ Baseplate created at \(options.outputPath)")
            print("✔ Configured \(options.customConfig?.generatorTool.rawValue.capitalized ?? "Tuist") project for \(options.projectName)")
            
            let dirName = (options.outputPath as NSString).lastPathComponent
            print("""

            Next steps:
              1. cd \(dirName)
              2. swiftblock snap network   # Snap foundation bricks
              3. swiftblock snap scene Home # Snap feature scene
              4. make setup                 # Generate Xcode workspace
            """)
        }
    } catch {
        print("✖ \(error.localizedDescription)")
        throw ExitCode.failure
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
    print("◆ Snapping \(options.type.rawValue) brick: \(options.moduleName)")
    let generator = ModuleGenerator()

    do {
        let generatedPath = try generator.generateModule(options: options)
        if !options.isDryRun {
            print("✔ Snapped \(options.type.rawValue) brick '\(options.moduleName)' at \(generatedPath)")
        }
    } catch {
        print("✖ \(error.localizedDescription)")
        throw ExitCode.failure
    }
}
