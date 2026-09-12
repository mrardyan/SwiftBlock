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
            IDECommand.self,
            RenameCommand.self
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

    @Option(name: [.customShort("v"), .customLong("var")], help: "Key-value template variable (e.g. --var timeout=60)")
    var variables: [String] = []

    @Flag(name: .long, help: "Simulate brick generation without writing to disk")
    var dryRun: Bool = false

    private func parseVariables() -> [String: String] {
        var dict: [String: String] = [:]
        for item in variables {
            let parts = item.split(separator: "=", maxSplits: 1).map(String.init)
            if parts.count == 2 {
                dict[parts[0].trimmingCharacters(in: .whitespaces)] = parts[1].trimmingCharacters(in: .whitespaces)
            }
        }
        return dict
    }

    func run() throws {
        let baseDir = templatePath ?? FileManager.default.currentDirectoryPath
        let discoveryEngine = BrickDiscoveryEngine()
        
        guard let brickInput = brick else {
            // Interactive wizard when no arguments provided
            let options = try InteractiveWizard.runModuleWizard(defaultTemplatePath: baseDir)
            var finalOptions = options
            finalOptions.isDryRun = dryRun
            try executeAddModuleWithOptions(options: finalOptions)
            return
        }
        
        let normalizedBrick = brickInput.lowercased()
        var resolvedVars = parseVariables()

        // Direct Git URL Resolution
        if BoxManager.isGitURL(brickInput) {
            let boxManager = BoxManager()
            let fetched = try boxManager.fetchGitRepository(urlString: brickInput, isVerbose: true)
            let targetPath = fetched.cachedPath

            if let manifest = BrickManifest.load(fromPath: targetPath) {
                if !manifest.variables.isEmpty {
                    resolvedVars = try InteractiveWizard.runBrickVariablesWizard(manifest: manifest, providedValues: resolvedVars)
                }
                let instanceName = name ?? (manifest.instantiation == .generative ? "Main" : manifest.name.capitalized)
                let moduleType = Brick(rawValue: manifest.name.lowercased())
                try executeAddModule(type: moduleType, moduleName: instanceName, templatePath: targetPath, isDryRun: dryRun, variables: resolvedVars)
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
                if !selected.manifest.variables.isEmpty {
                    resolvedVars = try InteractiveWizard.runBrickVariablesWizard(manifest: selected.manifest, providedValues: resolvedVars)
                }
                let instanceName = name ?? (selected.manifest.instantiation == .generative ? "Main" : selected.manifest.name.capitalized)
                let moduleType = Brick(rawValue: selected.manifest.name.lowercased())
                try executeAddModule(type: moduleType, moduleName: instanceName, templatePath: selectedPath, isDryRun: dryRun, variables: resolvedVars)
                return
            }
        }
        
        // Smart Namespace Resolution
        if let resolvedPath = discoveryEngine.resolveBrickPath(named: brickInput, in: baseDir),
           let manifest = BrickManifest.load(fromPath: resolvedPath) {
            
            if !manifest.variables.isEmpty {
                resolvedVars = try InteractiveWizard.runBrickVariablesWizard(manifest: manifest, providedValues: resolvedVars)
            }
            let instanceName = name ?? (manifest.instantiation == .generative ? "Main" : manifest.name.capitalized)
            let moduleType = Brick(rawValue: manifest.name.lowercased())
            
            try executeAddModule(type: moduleType, moduleName: instanceName, templatePath: resolvedPath, isDryRun: dryRun, variables: resolvedVars)
            return
        }
        
        // Fallback for standard module type
        let type = Brick(rawValue: normalizedBrick)
        let instanceName = name ?? "Main"
        try executeAddModule(type: type, moduleName: instanceName, templatePath: baseDir, isDryRun: dryRun, variables: resolvedVars)
        
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
            BoxUpdate.self,
            BoxValidate.self,
            BoxPublish.self
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

struct BoxValidate: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "validate",
        abstract: "Validate brick/kit manifest syntax, variable definitions, and template integrity"
    )

    @Argument(help: "Path to brick directory (default: current directory)")
    var path: String?

    func run() throws {
        let targetPath = path ?? FileManager.default.currentDirectoryPath
        let publisher = BoxPublisher()
        let report = try publisher.validateBox(at: targetPath)

        print("┌  \(ANSIColor.boldText("SwiftBlock Box Validation Result"))")
        print("│")
        if let manifest = report.manifest {
            print("│  Brick Name: \(ANSIColor.boldText(manifest.name)) (\(manifest.instantiation.rawValue))")
        }

        for warning in report.warnings {
            print("│  [\(ANSIColor.yellowText("!"))] Warning: \(warning)")
        }

        if report.isValid {
            print("└  \(ANSIColor.greenText("✔ Box manifest and templates are valid and ready to publish."))")
        } else {
            for error in report.errors {
                print("│  [\(ANSIColor.redText("✖"))] Error: \(error)")
            }
            print("└  \(ANSIColor.redText("✖ Box validation failed with \(report.errors.count) error(s)."))")
            throw ExitCode.failure
        }
    }
}

struct BoxPublish: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "publish",
        abstract: "Validate, version tag, and publish box brick/kit to remote Git repository"
    )

    @Argument(help: "Path to brick directory (default: current directory)")
    var path: String?

    @Option(name: [.customShort("t"), .long], help: "Release semantic version tag (e.g. v1.0.0)")
    var tag: String?

    @Option(name: [.customShort("r"), .long], help: "Git remote target name (default: origin)")
    var remote: String = "origin"

    @Flag(name: .long, help: "Simulate publish workflow without pushing to remote")
    var dryRun: Bool = false

    func run() throws {
        let targetPath = path ?? FileManager.default.currentDirectoryPath
        let publisher = BoxPublisher()

        do {
            let result = try publisher.publishBox(at: targetPath, tag: tag, remote: remote, isDryRun: dryRun)
            if dryRun {
                print("✔ [DRY RUN] Box '\(result.boxName)' validation passed. Target release tag: \(result.tag)")
            } else {
                print("✔ Successfully tagged and published box '\(result.boxName)' (\(result.tag)) to remote '\(result.remote)'.")
            }
        } catch {
            print("✖ \(error.localizedDescription)")
            throw ExitCode.failure
        }
    }
}

struct DoctorCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "doctor",
        abstract: "Diagnose SwiftBlock environment, build tools, dependency graph, and Periphery static analysis"
    )

    func run() throws {
        let engine = DoctorEngine()
        engine.printDiagnosticsReport()
    }
}

struct IDECommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ide",
        abstract: "Generate and configure IDE tasks (VS Code tasks.json and Makefile shortcuts)",
        subcommands: [IDESetup.self],
        defaultSubcommand: IDESetup.self
    )
}

struct IDESetup: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "setup",
        abstract: "Generate .vscode/tasks.json and Makefile shortcuts"
    )

    @Flag(name: .long, help: "Generate VS Code tasks")
    var vscode: Bool = false

    @Flag(name: .long, help: "Generate Xcode & Makefile shortcuts")
    var xcode: Bool = false

    func run() throws {
        let rootPath = FileManager.default.currentDirectoryPath
        let config = (try? SwiftBlockConfig.load(from: rootPath)) ?? SwiftBlockConfig(projectName: "App")

        let generator = IDEConfigGenerator()
        if vscode || (!vscode && !xcode) {
            try generator.generateVSCodeTasks(projectPath: rootPath, config: config)
            print("✔ Generated VS Code tasks at .vscode/tasks.json")
        }
        if xcode || (!vscode && !xcode) {
            try generator.updateMakefileShortcuts(projectPath: rootPath)
            print("✔ Updated Makefile shortcuts")
        }
    }
}

struct RenameCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "rename",
        abstract: "Safely refactor and rename current project without breaking targets, manifests, or tests"
    )

    @Argument(help: "New project name (e.g. MyAwesomeApp)")
    var newName: String

    @Option(name: [.customShort("p"), .long], help: "Path to project root directory (default: current directory)")
    var path: String?

    @Flag(name: .long, help: "Simulate project rename without writing changes to disk")
    var dryRun: Bool = false

    func run() throws {
        let rootPath = path ?? FileManager.default.currentDirectoryPath
        let engine = ProjectRefactoringEngine()

        do {
            let result = try engine.renameProject(projectPath: rootPath, newName: newName, isDryRun: dryRun)
            if dryRun {
                print("✔ [DRY RUN] Would rename project '\(result.oldName)' -> '\(result.newName)'")
            } else {
                print("✔ Refactored project '\(result.oldName)' to '\(result.newName)' successfully.")
                print("✔ Updated \(result.modifiedFiles.count) file(s) and renamed \(result.renamedFiles.count) test file(s).")
            }
        } catch {
            print("✖ \(error.localizedDescription)")
            throw ExitCode.failure
        }
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

private func executeAddModule(type: Brick, moduleName: String, templatePath: String, isDryRun: Bool, variables: [String: String] = [:]) throws {
    let options = BrickGeneratorOptions(
        type: type,
        name: moduleName,
        modulesTemplatePath: templatePath,
        isDryRun: isDryRun,
        variables: variables
    )
    try executeAddModuleWithOptions(options: options)
}

private func executeAddModuleWithOptions(options: BrickGeneratorOptions) throws {
    print("◆ Snapping \(options.type.rawValue) brick: \(options.name)")
    let generator = BrickGenerator()

    do {
        let generatedPath = try generator.generateModule(options: options)
        if !options.isDryRun {
            print("✔ Snapped \(options.type.rawValue) brick '\(options.name)' at \(generatedPath)")
        }
    } catch {
        print("✖ \(error.localizedDescription)")
        throw ExitCode.failure
    }
}
