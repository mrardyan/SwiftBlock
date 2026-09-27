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
            RenameCommand.self,
            CompletionCommand.self,
        ],
        defaultSubcommand: DoctorCommand.self
    )
}

struct BaseplateCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "baseplate",
        abstract: "Lay down a new SwiftUI or Vapor project baseplate using Tuist, XcodeGen, or SPM",
        aliases: ["new", "init"]
    )

    @Argument(help: "Project name (optional, triggers interactive setup if omitted)")
    var projectName: String?

    @Option(name: [.customShort("p"), .customLong("bundle-prefix"), .customLong("prefix")], help: "Bundle identifier prefix (default: com.company)")
    var bundlePrefix = "com.company"

    @Option(
        name: [.customShort("b"), .customLong("baseplate"), .customLong("template-name")],
        help: "Baseplate starter template: swiftui or vapor (default: swiftui)"
    )
    var baseplate = "swiftui"

    @Option(name: [.customShort("t"), .long], help: "Custom project template path")
    var templatePath: String?

    @Option(name: .long, help: "Build tool generator: tuist or xcodegen (default: tuist)")
    var tool = "tuist"

    @Option(name: .long, help: "Unit test framework: swift-testing or xctest (default: swift-testing)")
    var testFramework = "swift-testing"

    @Flag(name: .long, help: "Simulate project generation without writing to disk")
    var dryRun = false

    @Flag(name: [.customShort("v"), .long], help: "Enable verbose step-by-step log output")
    var verbose = false

    func run() throws {
        if let projectName, !projectName.isEmpty {
            guard ProjectRefactoringEngine.isValidProjectName(projectName) else {
                print("❌ Invalid project name '\(projectName)'. Project name must start with a letter and contain only alphanumeric characters or underscores.")
                throw ExitCode.failure
            }
            let toolEnum = ProjectGeneratorTool(rawValue: tool.lowercased()) ?? .tuist
            let tfEnum = TestFramework(rawValue: testFramework.lowercased()) ?? .swiftTesting
            try executeInitProject(
                projectName: projectName,
                bundlePrefix: bundlePrefix,
                baseplateName: baseplate,
                templatePath: templatePath,
                generatorTool: toolEnum,
                testFramework: tfEnum,
                isDryRun: dryRun,
                isVerbose: verbose
            )
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

    @Option(name: .customLong("with-optional"), help: "Comma-separated list of optional dependencies to snap")
    var withOptional: String?

    @Flag(name: .customLong("all-optional"), help: "Snap all optional dependencies")
    var allOptional = false

    @Flag(name: .customLong("no-deps"), help: "Skip automatic resolution of mandatory dependencies")
    var noDeps = false

    @Option(name: .customLong("flavor"), help: "Key-value flavor selection (e.g. --flavor concurrency=async-await)")
    var flavor: [String] = []

    @Option(name: .long, help: "Unit test framework: swift-testing or xctest")
    var testFramework: String?

    @Flag(name: .long, help: "Simulate brick generation without writing to disk")
    var dryRun = false

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

    private func parseFlavorSelections() -> [String: String] {
        var dict: [String: String] = [:]
        for item in flavor {
            let parts = item.split(separator: "=", maxSplits: 1).map(String.init)
            if parts.count == 2 {
                dict[parts[0].trimmingCharacters(in: .whitespaces).lowercased()] = parts[1].trimmingCharacters(in: .whitespaces)
            }
        }
        return dict
    }

    private func parseOptionalDeps(manifest: BrickManifest) -> Set<String> {
        if allOptional {
            return Set(manifest.dependencies.optional.map { $0.name.lowercased() })
        }
        guard let list = withOptional else { return [] }
        return Set(list.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() })
    }

    /// Applies flavor selections from `--flavor` flags against the manifest's declared flavors,
    /// merging selected option variables into the template variables, and adding flavor-scoped
    /// dependencies into the optional dependency set. Unknown flavor keys fall back to being
    /// treated as plain template variables for backward compatibility.
    private func applyFlavors(
        manifest: BrickManifest,
        selections: [String: String],
        variables: inout [String: String],
        selectedOptionalDeps: inout Set<String>
    ) {
        let result = FlavorResolver.resolve(
            manifest: manifest,
            selections: selections,
            variables: variables,
            selectedOptionalDeps: selectedOptionalDeps
        )
        variables = result.variables
        selectedOptionalDeps = result.selectedOptionalDeps

        for (flavorKey, flavor) in manifest.flavors {
            let selectedValue = selections[flavorKey.lowercased()] ?? selections[flavor.id.lowercased()]
            guard let val = selectedValue else { continue }
            if let warning = FlavorResolver.validateSelection(manifest: manifest, flavorKey: flavorKey, selectedValue: val) {
                print("  \(ANSIColor.yellowText("⚠️ \(warning)"))")
            } else {
                print("  \(ANSIColor.greenText("✔ Flavor '\(flavorKey)' → '\(val)'"))")
            }
        }
    }

    func run() throws {
        let baseDir = templatePath ?? FileManager.default.currentDirectoryPath
        let discoveryEngine = BrickDiscoveryEngine()
        let depResolver = DependencyResolverEngine(discoveryEngine: discoveryEngine)

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
                let instanceName = name ?? (manifest.instantiation == .generative ? "Main" : manifest.defaultInstanceName)
                let moduleType = Brick(rawValue: (targetPath as NSString).lastPathComponent)
                try executeAddModule(type: moduleType, moduleName: instanceName, templatePath: targetPath, isDryRun: dryRun, variables: resolvedVars)
                return
            }

            let discovered = boxManager.discoverMonorepoBricks(at: targetPath)
            if !discovered.isEmpty {
                let selected: (relativePath: String, manifest: BrickManifest) = if discovered.count == 1 {
                    discovered[0]
                } else {
                    try InteractiveWizard.runMonorepoSelectionWizard(bricks: discovered)
                }
                let selectedPath = "\(targetPath)/\(selected.relativePath)"
                if !selected.manifest.variables.isEmpty {
                    resolvedVars = try InteractiveWizard.runBrickVariablesWizard(manifest: selected.manifest, providedValues: resolvedVars)
                }
                let instanceName = name ?? (selected.manifest.instantiation == .generative ? "Main" : selected.manifest.defaultInstanceName)
                let moduleType = Brick(rawValue: (selectedPath as NSString).lastPathComponent)
                try executeAddModule(type: moduleType, moduleName: instanceName, templatePath: selectedPath, isDryRun: dryRun, variables: resolvedVars)
                return
            }
        }

        // Smart Namespace Resolution & Structured Composing
        if let resolvedPath = discoveryEngine.resolveBrickPath(named: brickInput, in: baseDir),
           let manifest = BrickManifest.load(fromPath: resolvedPath)
        {
            if !manifest.variables.isEmpty {
                resolvedVars = try InteractiveWizard.runBrickVariablesWizard(manifest: manifest, providedValues: resolvedVars)
            }

            var flavorSelections = parseFlavorSelections()
            if isatty(STDIN_FILENO) != 0, !manifest.flavors.isEmpty {
                flavorSelections = try InteractiveWizard.runBrickFlavorsWizard(manifest: manifest, providedSelections: flavorSelections)
            }

            var selectedOpts = parseOptionalDeps(manifest: manifest)
            applyFlavors(manifest: manifest, selections: flavorSelections, variables: &resolvedVars, selectedOptionalDeps: &selectedOpts)

            // Resolve Dependency Plan
            if !noDeps {
                do {
                    let plan = try depResolver.resolve(
                        targetBrickName: brickInput,
                        baseTemplatePath: baseDir,
                        projectRootPath: FileManager.default.currentDirectoryPath,
                        selectedOptionalDeps: selectedOpts
                    )

                    for skipped in plan.skippedAlreadyInstalled {
                        print("  \(ANSIColor.dimText("ℹ Dependency '\(skipped)' already installed, skipping."))")
                    }
                    for node in plan.executionOrder where node.name.lowercased() != manifest.name.lowercased() {
                        let depType = Brick(rawValue: (node.templatePath as NSString).lastPathComponent)
                        let depInstanceName = node.manifest.instantiation == .generative ? "Main" : node.manifest.defaultInstanceName
                        try executeAddModule(
                            type: depType,
                            moduleName: depInstanceName,
                            templatePath: node.templatePath,
                            isDryRun: dryRun,
                            variables: resolvedVars
                        )
                        if node.autoWire {
                            print("  \(ANSIColor.greenText("⚡ Auto-wired '\(node.manifest.name)' into '\(manifest.name)'"))")
                        }
                    }
                } catch {
                    print("❌ Dependency resolution failed: \(error.localizedDescription)")
                    throw ExitCode.failure
                }
            }

            let instanceName = name ?? (manifest.instantiation == .generative ? "Main" : manifest.defaultInstanceName)
            let moduleType = Brick(rawValue: (resolvedPath as NSString).lastPathComponent)

            try executeAddModule(type: moduleType, moduleName: instanceName, templatePath: resolvedPath, isDryRun: dryRun, variables: resolvedVars)
            return
        }

        // Fallback for standard module type
        let type = Brick(rawValue: normalizedBrick)
        let instanceName = name ?? "Main"
        do {
            try executeAddModule(type: type, moduleName: instanceName, templatePath: baseDir, isDryRun: dryRun, variables: resolvedVars)
            return
        } catch {
            print("❌ Brick '\(brickInput)' not found in local library or registry.")
            print("  \(ANSIColor.dimText("ℹ Available bricks:")) \(BrickRegistry.allBricks.map(\.commandName).joined(separator: ", "))")
            throw ExitCode.failure
        }
    }
}

struct KitCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "kit",
        abstract: "Manage and execute multi-brick composition recipes (kits)",
        subcommands: [
            KitAdd.self,
            KitList.self,
            KitCreate.self,
        ],
        defaultSubcommand: KitList.self
    )
}

struct KitAdd: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add",
        abstract: "Snap or apply a multi-brick composition kit into current project",
        aliases: ["run", "use", "apply"]
    )

    @Argument(help: "Kit name (e.g. clean-feature)")
    var kitName: String?

    @Argument(help: "Target module name (e.g. Profile, Auth)")
    var moduleName: String?

    @Flag(name: .long, help: "Simulate kit generation without writing to disk")
    var dryRun = false

    func run() throws {
        let config = (try? SwiftBlockConfig.load()) ?? SwiftBlockConfig(projectName: "App")
        let targetKit: String
        let targetModule: String

        if let kName = kitName, !kName.isEmpty {
            targetKit = kName
        } else {
            let availableKits = Array(config.kits.keys.sorted())
            let choices = availableKits.map { ChoiceOption(title: $0, subtitle: config.kits[$0]?.joined(separator: ", ")) }
            let selectedIdx = InteractiveWizard.promptChoiceWithOptions(title: "Select Composition Kit", options: choices)
            targetKit = availableKits[selectedIdx]
        }

        if let mName = moduleName, !mName.isEmpty {
            targetModule = mName
        } else {
            var inputModule = ""
            while inputModule.isEmpty {
                inputModule = InteractiveWizard.prompt(message: "Enter Target Module Name (e.g. Profile)")
                if inputModule.isEmpty {
                    print("  \(ANSIColor.yellowText("⚠️"))  Module name cannot be empty.")
                }
            }
            targetModule = inputModule
        }

        let engine = KitEngine()
        let result = try engine.executeKit(
            name: targetKit,
            moduleName: targetModule,
            config: config,
            projectPath: FileManager.default.currentDirectoryPath,
            isDryRun: dryRun
        )
        if !dryRun {
            print(
                "✔ Snapped kit '\(result.kitName)' for module '\(result.moduleName)' with bricks: "
                    + "\(result.generatedBricks.map(\.rawValue).joined(separator: ", "))"
            )
        }
    }
}

struct KitCreate: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Design and save a custom multi-brick composition kit",
        aliases: ["new", "make"]
    )

    @Argument(help: "Kit name (optional, triggers interactive wizard if omitted)")
    var kitName: String?

    @Option(name: [.customShort("b"), .long], help: "Comma-separated list of brick names (e.g. --bricks scene,usecase,repository)")
    var bricks: String?

    func run() throws {
        let rootPath = FileManager.default.currentDirectoryPath
        var config = (try? SwiftBlockConfig.load(from: rootPath)) ?? SwiftBlockConfig(projectName: "App")

        let finalName: String
        let finalBlocks: [String]

        if let name = kitName, !name.isEmpty {
            finalName = name.lowercased()
            if let brickList = bricks, !brickList.isEmpty {
                finalBlocks = brickList.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            } else {
                let featureBlocks = BrickRegistry.featureBricks
                let blockOptions = featureBlocks.map {
                    TerminalPrompt.MultiChoiceOption(id: $0.commandName, title: $0.title, subtitle: $0.description, isSelected: true)
                }
                finalBlocks = TerminalPrompt.selectMultiChoice(title: "Select composed bricks for '\(finalName)'", options: blockOptions)
            }
        } else {
            let res = try InteractiveWizard.runKitCreateWizard(projectPath: rootPath)
            finalName = res.name
            finalBlocks = res.blocks
        }

        guard !finalBlocks.isEmpty else {
            print("└  \(ANSIColor.redText("✖ Kit creation cancelled (no bricks selected)."))")
            throw ExitCode.failure
        }

        config.kits[finalName] = finalBlocks
        try config.save(to: rootPath)
        print("✔ Saved custom composition kit '\(finalName)' with bricks: \(finalBlocks.joined(separator: ", "))")
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
            BoxPublish.self,
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
    var remote = "origin"

    @Flag(name: .long, help: "Simulate publish workflow without pushing to remote")
    var dryRun = false

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
    var vscode = false

    @Flag(name: .long, help: "Generate Xcode & Makefile shortcuts")
    var xcode = false

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

    @Argument(help: "New project name (optional, triggers interactive wizard if omitted)")
    var newName: String?

    @Option(name: [.customShort("p"), .long], help: "Path to project root directory (default: current directory)")
    var path: String?

    @Flag(name: .long, help: "Simulate project rename without writing changes to disk")
    var dryRun = false

    func run() throws {
        let rootPath = path ?? FileManager.default.currentDirectoryPath
        let targetName: String = if let name = newName, !name.isEmpty {
            name
        } else {
            try InteractiveWizard.runRenameWizard(projectPath: rootPath)
        }

        let engine = ProjectRefactoringEngine()

        do {
            let result = try engine.renameProject(projectPath: rootPath, newName: targetName, isDryRun: dryRun)
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

struct CompletionCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "completion",
        abstract: "Generate shell autocompletion script for zsh, bash, or fish"
    )

    @Argument(help: "Target shell: zsh, bash, or fish (default: zsh)")
    var shell = "zsh"

    func run() throws {
        let shellType = ShellType(rawValue: shell.lowercased()) ?? .zsh
        let script = CompletionGenerator.generate(for: shellType)
        print(script)
    }
}

private func executeInitProject(
    projectName: String,
    bundlePrefix: String,
    baseplateName: String = "swiftui",
    templatePath: String?,
    generatorTool: ProjectGeneratorTool,
    testFramework: TestFramework = .swiftTesting,
    isDryRun: Bool,
    isVerbose: Bool
) throws {
    let isVapor = baseplateName.lowercased().contains("vapor")
    let resolvedTool: ProjectGeneratorTool = isVapor ? .spm : generatorTool
    let config = if isVapor {
        SwiftBlockConfig(
            projectName: projectName,
            bundlePrefix: bundlePrefix,
            packaging: PackagingConfig(feature: "monolithic", core: "monolithic"),
            organization: "feature-first",
            generatorTool: .spm,
            guardrails: GuardrailsConfig(
                swiftlint: true,
                swiftformat: true,
                precommit: true,
                periphery: false,
                gitleaks: true,
                danger: false,
                swiftgen: false,
                licenseplist: false
            ),
            cicd: CICDConfig(provider: .githubActions),
            coreBlocks: [.network, .logger, .config, .vaporauth],
            gitInit: true,
            pathTemplates: [
                "feature": "Sources/App/Features/{module}/{block}",
                "core": "Sources/App/Core/{block}",
            ],
            testFramework: testFramework
        )
    } else {
        SwiftBlockConfig(projectName: projectName, bundlePrefix: bundlePrefix, generatorTool: resolvedTool, testFramework: testFramework)
    }

    let options = ProjectGeneratorOptions(
        projectName: projectName,
        bundlePrefix: bundlePrefix,
        templatePath: templatePath,
        isDryRun: isDryRun,
        isVerbose: isVerbose,
        customConfig: config,
        baseplateName: baseplateName
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
            let isVapor = options.baseplateName.lowercased().contains("vapor") || (options.customConfig?.generatorTool == .spm)
            if isVapor {
                print("""

                Next steps:
                  1. cd \(dirName)
                  2. swiftblock snap service Order # Snap feature service brick
                  3. swift run                     # Start local Vapor dev server
                """)
            } else {
                print("""

                Next steps:
                  1. cd \(dirName)
                  2. swiftblock snap network       # Snap foundation bricks
                  3. swiftblock snap scene Home    # Snap feature scene
                  4. make setup                    # Generate Xcode workspace
                """)
            }
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
