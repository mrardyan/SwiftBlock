import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

public class InteractiveWizard {
    public init() {}

    public static func stripANSIEscapeCodes(_ input: String) -> String {
        return input.replacingOccurrences(
            of: #"\x1B\[[0-9;?]*[a-zA-Z~]"#,
            with: "",
            options: .regularExpression
        )
    }

    public static func readLine() -> String? {
        if let line = readTerminalLine() {
            return stripANSIEscapeCodes(line)
        }
        return nil
    }

    public static func readTerminalLine() -> String? {
        guard isatty(STDIN_FILENO) != 0 else {
            return Swift.readLine()
        }

        var oldTerm = termios()
        if tcgetattr(STDIN_FILENO, &oldTerm) != 0 {
            return Swift.readLine()
        }

        var rawTerm = oldTerm
        rawTerm.c_lflag &= ~tcflag_t(ICANON | ECHO)

        withUnsafeMutablePointer(to: &rawTerm.c_cc) { ptr in
            let base = UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: cc_t.self)
            base[Int(VMIN)] = 1
            base[Int(VTIME)] = 0
        }

        if tcsetattr(STDIN_FILENO, TCSANOW, &rawTerm) != 0 {
            return Swift.readLine()
        }

        defer {
            tcsetattr(STDIN_FILENO, TCSANOW, &oldTerm)
        }

        var buffer: [Character] = []
        var cursor = 0

        func getByte() -> UInt8? {
            var byte: UInt8 = 0
            let n = read(STDIN_FILENO, &byte, 1)
            return n == 1 ? byte : nil
        }

        func redraw(startIndex: Int) {
            let tail = String(buffer[startIndex...])
            print(tail + " ", terminator: "")
            let printedLength = tail.count + 1
            let offsetFromStart = cursor - startIndex
            let moveBack = printedLength - offsetFromStart
            if moveBack > 0 {
                print("\u{001B}[\(moveBack)D", terminator: "")
            }
            fflush(stdout)
        }

        while true {
            guard let byte = getByte() else { break }

            if byte == 0x0A || byte == 0x0D { // Enter (\n or \r)
                return String(buffer)
            } else if byte == 0x03 || byte == 0x04 { // Ctrl+C or Ctrl+D
                if byte == 0x03 {
                    print("")
                    fflush(stdout)
                }
                return nil
            } else if byte == 0x7F || byte == 0x08 { // Backspace
                if cursor > 0 {
                    cursor -= 1
                    buffer.remove(at: cursor)
                    if cursor == buffer.count {
                        print("\u{001B}[1D \u{001B}[1D", terminator: "")
                        fflush(stdout)
                    } else {
                        print("\u{001B}[1D", terminator: "")
                        redraw(startIndex: cursor)
                    }
                }
            } else if byte == 0x1B { // Escape sequence (\u{1B})
                if let b2 = getByte(), (b2 == 0x5B || b2 == 0x4F) { // '[' or 'O'
                    if let b3 = getByte() {
                        switch b3 {
                        case 0x44: // Left arrow ('D')
                            if cursor > 0 {
                                cursor -= 1
                                print("\u{001B}[1D", terminator: "")
                                fflush(stdout)
                            }
                        case 0x43: // Right arrow ('C')
                            if cursor < buffer.count {
                                cursor += 1
                                print("\u{001B}[1C", terminator: "")
                                fflush(stdout)
                            }
                        case 0x48: // Home ('H')
                            if cursor > 0 {
                                print("\u{001B}[\(cursor)D", terminator: "")
                                cursor = 0
                                fflush(stdout)
                            }
                        case 0x46: // End ('F')
                            if cursor < buffer.count {
                                let dist = buffer.count - cursor
                                print("\u{001B}[\(dist)C", terminator: "")
                                cursor = buffer.count
                                fflush(stdout)
                            }
                        case 0x33: // Delete ('3~')
                            if let b4 = getByte(), b4 == 0x7E { // '~'
                                if cursor < buffer.count {
                                    buffer.remove(at: cursor)
                                    redraw(startIndex: cursor)
                                }
                            }
                        default:
                            break
                        }
                    }
                }
            } else if byte >= 0x20 { // Printable ASCII or UTF-8
                var bytes = [byte]
                var expectedLen = 1
                if (byte & 0xE0) == 0xC0 { expectedLen = 2 }
                else if (byte & 0xF0) == 0xE0 { expectedLen = 3 }
                else if (byte & 0xF8) == 0xF0 { expectedLen = 4 }

                while bytes.count < expectedLen {
                    if let nextByte = getByte() {
                        bytes.append(nextByte)
                    } else {
                        break
                    }
                }

                if let str = String(bytes: bytes, encoding: .utf8), let ch = str.first {
                    if cursor == buffer.count {
                        buffer.append(ch)
                        cursor += 1
                        print(ch, terminator: "")
                        fflush(stdout)
                    } else {
                        buffer.insert(ch, at: cursor)
                        cursor += 1
                        redraw(startIndex: cursor - 1)
                    }
                }
            }
        }

        return String(buffer)
    }

    public static func prompt(
        message: String,
        defaultValue: String? = nil,
        readLine: () -> String? = { InteractiveWizard.readLine() }
    ) -> String {
        return TerminalPrompt.promptInput(title: message, defaultValue: defaultValue, readLineFallback: readLine)
    }

    public static func promptChoice(
        title: String,
        options: [String],
        readLine: () -> String? = { InteractiveWizard.readLine() }
    ) -> Int {
        let choiceOptions = options.map { ChoiceOption(title: $0) }
        return TerminalPrompt.selectChoice(title: title, options: choiceOptions, readLineFallback: readLine) ?? 0
    }

    public static func promptChoiceWithOptions(
        title: String,
        options: [ChoiceOption],
        readLine: () -> String? = { InteractiveWizard.readLine() }
    ) -> Int {
        return TerminalPrompt.selectChoice(title: title, options: options, readLineFallback: readLine) ?? 0
    }

    public static func promptConfirm(
        message: String,
        defaultYes: Bool = true,
        readLine: () -> String? = { InteractiveWizard.readLine() }
    ) -> Bool {
        return TerminalPrompt.confirm(title: message, defaultYes: defaultYes, readLineFallback: readLine)
    }

    public static func runProjectWizard(
        defaultTemplatePath: String,
        readLine: () -> String? = { InteractiveWizard.readLine() }
    ) throws -> ProjectGeneratorOptions {
        print("┌  \(ANSIColor.boldText("Create New Project"))")
        print("│")
        print("◇  \(ANSIColor.boldText("Project Baseplate Starter"))")

        let baseplateChoices = [
            ChoiceOption(title: "SwiftUI App", subtitle: "Apple platform application (iOS, macOS) with Tuist or XcodeGen"),
            ChoiceOption(title: "Vapor Backend API", subtitle: "High-performance Swift backend web API service powered by Vapor & SPM")
        ]
        let baseplateChoiceIndex = promptChoiceWithOptions(title: "What do you want to create?", options: baseplateChoices, readLine: readLine)

        if baseplateChoiceIndex == 0 {
            return try runSwiftUIProjectWizard(defaultTemplatePath: defaultTemplatePath, readLine: readLine)
        } else {
            return try runVaporProjectWizard(defaultTemplatePath: defaultTemplatePath, readLine: readLine)
        }
    }

    private static func runSwiftUIProjectWizard(
        defaultTemplatePath: String,
        readLine: () -> String?
    ) throws -> ProjectGeneratorOptions {
        print("│")
        print("◇  \(ANSIColor.boldText("SwiftUI App Configuration"))")

        var projectName = ""
        while projectName.isEmpty {
            projectName = prompt(message: "Enter Project Name", readLine: readLine)
            if projectName.isEmpty {
                print("  \(ANSIColor.yellowText("⚠️"))  Project name cannot be empty.")
            }
        }

        let bundlePrefix = prompt(message: "Enter Bundle Identifier Prefix", defaultValue: "com.company", readLine: readLine)

        print("│")
        print("◇  \(ANSIColor.boldText("Build Tool & Architecture Strategy"))")

        let availableTools = ProjectGeneratorTool.allCases.filter { $0 != .spm }
        let toolChoices = availableTools.map { ChoiceOption(title: $0.title) }
        let toolChoiceIndex = promptChoiceWithOptions(title: "Select Build Tool Generator", options: toolChoices, readLine: readLine)
        let selectedTool = availableTools[toolChoiceIndex]

        let corePkgChoices = [
            ChoiceOption(title: "Monolithic Main Target", subtitle: "e.g. App/Sources/Core/Storage/..."),
            ChoiceOption(title: "SPM Core Package Target", subtitle: "e.g. Packages/Core/Sources/Core/Storage/...")
        ]
        let corePkgChoice = promptChoiceWithOptions(title: "Select Core Packaging Strategy", options: corePkgChoices, readLine: readLine)
        let corePkg = corePkgChoice == 0 ? "monolithic" : "spm"

        let featurePkgChoices = [
            ChoiceOption(title: "Monolithic Main Target", subtitle: "e.g. App/Sources/Features/Home/..."),
            ChoiceOption(title: "SPM Multi-Package Target", subtitle: "e.g. Packages/HomeFeature/Sources/...")
        ]
        let featurePkgChoice = promptChoiceWithOptions(title: "Select Feature Packaging Strategy", options: featurePkgChoices, readLine: readLine)
        let featurePkg = featurePkgChoice == 0 ? "monolithic" : "spm"

        print("│")
        print("◇  \(ANSIColor.boldText("Code Organization Strategy"))")

        let orgChoices = [
            ChoiceOption(title: "Feature-First", subtitle: "e.g. Home/Scene, Home/UseCase, Payment/Scene"),
            ChoiceOption(title: "Technical-First", subtitle: "e.g. Scenes/Home, UseCases/Home, Repositories/Payment")
        ]
        let orgChoice = promptChoiceWithOptions(title: "Select Code Organization Strategy", options: orgChoices, readLine: readLine)
        let orgStrategy = orgChoice == 0 ? "feature-first" : "technical-first"

        print("│")
        print("◇  \(ANSIColor.boldText("Guardrails & Developer Tooling"))")

        let guardrailOptions = [
            TerminalPrompt.MultiChoiceOption(id: "swiftlint", title: "SwiftLint", subtitle: "Code style rules & build phase script", isSelected: true),
            TerminalPrompt.MultiChoiceOption(id: "swiftformat", title: "SwiftFormat", subtitle: "Automated code formatter & make target", isSelected: true),
            TerminalPrompt.MultiChoiceOption(id: "precommit", title: "Pre-commit Hooks", subtitle: "Git pre-commit framework integration", isSelected: true),
            TerminalPrompt.MultiChoiceOption(id: "periphery", title: "Periphery", subtitle: "Dead & unused code scanner", isSelected: true),
            TerminalPrompt.MultiChoiceOption(id: "gitleaks", title: "Gitleaks", subtitle: "Secret & credential leak prevention scanner", isSelected: true),
            TerminalPrompt.MultiChoiceOption(id: "danger", title: "Danger", subtitle: "Automated PR code review engine", isSelected: true),
            TerminalPrompt.MultiChoiceOption(id: "swiftgen", title: "SwiftGen", subtitle: "Type-safe asset & string generator", isSelected: true),
            TerminalPrompt.MultiChoiceOption(id: "licenseplist", title: "LicensePlist", subtitle: "Open-source license acknowledgements generator", isSelected: true)
        ]
        let selectedGuardrailIds = TerminalPrompt.selectMultiChoice(title: "Select Guardrails (Space: toggle, Enter: submit)", options: guardrailOptions, readLineFallback: readLine)

        let activeGuardrails = GuardrailsConfig(
            swiftlint: selectedGuardrailIds.contains("swiftlint"),
            swiftformat: selectedGuardrailIds.contains("swiftformat"),
            precommit: selectedGuardrailIds.contains("precommit"),
            periphery: selectedGuardrailIds.contains("periphery"),
            gitleaks: selectedGuardrailIds.contains("gitleaks"),
            danger: selectedGuardrailIds.contains("danger"),
            swiftgen: selectedGuardrailIds.contains("swiftgen"),
            licenseplist: selectedGuardrailIds.contains("licenseplist")
        )

        print("│")
        print("◇  \(ANSIColor.boldText("Core Foundation Modules"))")

        let coreBlockOptions = [
            TerminalPrompt.MultiChoiceOption(id: "storage", title: "Storage", subtitle: "Local persistence storage engine", isSelected: true),
            TerminalPrompt.MultiChoiceOption(id: "network", title: "Network", subtitle: "Network client & HTTP engine", isSelected: true),
            TerminalPrompt.MultiChoiceOption(id: "logger", title: "Logger", subtitle: "Unified OSLog & crash logger", isSelected: true),
            TerminalPrompt.MultiChoiceOption(id: "config", title: "Config", subtitle: "Multi-environment (.xcconfig) & Dev/Staging/Prod schemes", isSelected: true),
            TerminalPrompt.MultiChoiceOption(id: "auth", title: "Auth", subtitle: "User session & token state manager", isSelected: true),
            TerminalPrompt.MultiChoiceOption(id: "analytics", title: "Analytics", subtitle: "Event analytics & metrics engine", isSelected: false),
            TerminalPrompt.MultiChoiceOption(id: "featureflag", title: "FeatureFlag", subtitle: "Remote feature flags & toggles", isSelected: false)
        ]
        let selectedCoreBlockIds = TerminalPrompt.selectMultiChoice(title: "Select Core Foundation Modules to include", options: coreBlockOptions, readLineFallback: readLine)
        var selectedCoreBlocks = selectedCoreBlockIds.compactMap { Brick(rawValue: $0) }

        let multiEnvConfirm = promptConfirm(message: "Setup Multi-Environment Configurations (.xcconfig & Schemes)?", defaultYes: true, readLine: readLine)
        if multiEnvConfirm {
            if !selectedCoreBlocks.contains(.config) {
                selectedCoreBlocks.append(.config)
            }
        } else {
            selectedCoreBlocks.removeAll { $0 == .config }
        }

        print("│")
        print("◇  \(ANSIColor.boldText("CI/CD Pipeline & Git Repository"))")

        let cicdChoices = CICDProvider.allCases.map { ChoiceOption(title: $0.title) }
        let cicdChoiceIndex = promptChoiceWithOptions(title: "Select CI/CD Pipeline Provider", options: cicdChoices, readLine: readLine)
        let selectedCICD = CICDProvider.allCases[cicdChoiceIndex]

        let gitInitConfirm = promptConfirm(message: "Initialize Git repository & setup hooks?", defaultYes: true, readLine: readLine)

        print("│")
        let confirm = promptConfirm(message: "Create SwiftUI project '\(projectName)' with prefix '\(bundlePrefix)'?", readLine: readLine)
        guard confirm else {
            print("└  \(ANSIColor.redText("✖ Project creation cancelled."))")
            throw InteractiveWizardError.cancelled
        }

        let featureTemplate: String
        if featurePkg == "spm" {
            featureTemplate = "Packages/{module}Feature/Sources/{module}Feature/{block}s"
        } else if orgStrategy == "technical-first" {
            featureTemplate = "App/Sources/{block}s/{module}"
        } else {
            featureTemplate = "App/Sources/Features/{module}/{block}"
        }

        let coreTemplate: String
        if corePkg == "spm" {
            coreTemplate = "Packages/Core/Sources/Core/{block}"
        } else {
            coreTemplate = "App/Sources/Core/{block}"
        }

        let config = SwiftBlockConfig(
            projectName: projectName,
            bundlePrefix: bundlePrefix,
            packaging: PackagingConfig(feature: featurePkg, core: corePkg),
            organization: orgStrategy,
            generatorTool: selectedTool,
            guardrails: activeGuardrails,
            cicd: CICDConfig(provider: selectedCICD),
            coreBlocks: selectedCoreBlocks,
            gitInit: gitInitConfirm,
            pathTemplates: [
                "feature": featureTemplate,
                "core": coreTemplate
            ]
        )

        return ProjectGeneratorOptions(
            projectName: projectName,
            bundlePrefix: bundlePrefix,
            templatePath: defaultTemplatePath,
            customConfig: config,
            baseplateName: "swiftui"
        )
    }

    private static func runVaporProjectWizard(
        defaultTemplatePath: String,
        readLine: () -> String?
    ) throws -> ProjectGeneratorOptions {
        print("│")
        print("◇  \(ANSIColor.boldText("Vapor Backend API Configuration"))")

        var projectName = ""
        while projectName.isEmpty {
            projectName = prompt(message: "Enter Backend Server Project Name", readLine: readLine)
            if projectName.isEmpty {
                print("  \(ANSIColor.yellowText("⚠️"))  Project name cannot be empty.")
            }
        }

        let bundlePrefix = prompt(message: "Enter Module / Reverse Domain Prefix", defaultValue: "com.company.api", readLine: readLine)

        print("│")
        print("◇  \(ANSIColor.boldText("Backend Guardrails & Developer Tooling"))")

        let guardrailOptions = [
            TerminalPrompt.MultiChoiceOption(id: "swiftlint", title: "SwiftLint", subtitle: "Swift server code style analyzer", isSelected: true),
            TerminalPrompt.MultiChoiceOption(id: "swiftformat", title: "SwiftFormat", subtitle: "Automated code formatter & make target", isSelected: true),
            TerminalPrompt.MultiChoiceOption(id: "precommit", title: "Pre-commit Hooks", subtitle: "Git pre-commit framework integration", isSelected: true),
            TerminalPrompt.MultiChoiceOption(id: "gitleaks", title: "Gitleaks", subtitle: "Secret & API key leak scanner", isSelected: true)
        ]
        let selectedGuardrailIds = TerminalPrompt.selectMultiChoice(title: "Select Server Guardrails (Space: toggle, Enter: submit)", options: guardrailOptions, readLineFallback: readLine)

        let activeGuardrails = GuardrailsConfig(
            swiftlint: selectedGuardrailIds.contains("swiftlint"),
            swiftformat: selectedGuardrailIds.contains("swiftformat"),
            precommit: selectedGuardrailIds.contains("precommit"),
            periphery: false,
            gitleaks: selectedGuardrailIds.contains("gitleaks"),
            danger: false,
            swiftgen: false,
            licenseplist: false
        )

        print("│")
        print("◇  \(ANSIColor.boldText("Server Core Services"))")

        let serverBlockOptions = [
            TerminalPrompt.MultiChoiceOption(id: "network", title: "Network", subtitle: "Vapor Async HTTP Client engine", isSelected: true),
            TerminalPrompt.MultiChoiceOption(id: "logger", title: "Logger", subtitle: "Structured SwiftLog server logger", isSelected: true),
            TerminalPrompt.MultiChoiceOption(id: "config", title: "Config", subtitle: "Environment variables & dotenv manager", isSelected: true),
            TerminalPrompt.MultiChoiceOption(id: "auth", title: "Auth", subtitle: "JWT & Session Auth Manager", isSelected: true),
            TerminalPrompt.MultiChoiceOption(id: "storage", title: "Storage", subtitle: "Database & Fluent ORM persistence", isSelected: false)
        ]
        let selectedServerBlockIds = TerminalPrompt.selectMultiChoice(title: "Select Server Services to include", options: serverBlockOptions, readLineFallback: readLine)
        let selectedCoreBlocks = selectedServerBlockIds.map { id -> Brick in
            return id == "auth" ? .vaporauth : Brick(rawValue: id)
        }

        print("│")
        print("◇  \(ANSIColor.boldText("CI/CD Pipeline & Git Repository"))")

        let cicdChoices = CICDProvider.allCases.filter { $0 != .xcodeCloud }.map { ChoiceOption(title: $0.title) }
        let cicdChoiceIndex = promptChoiceWithOptions(title: "Select CI/CD Pipeline Provider", options: cicdChoices, readLine: readLine)
        let selectedCICD = CICDProvider.allCases.filter { $0 != .xcodeCloud }[cicdChoiceIndex]

        let gitInitConfirm = promptConfirm(message: "Initialize Git repository & setup hooks?", defaultYes: true, readLine: readLine)

        print("│")
        let confirm = promptConfirm(message: "Create Vapor backend project '\(projectName)'?", readLine: readLine)
        guard confirm else {
            print("└  \(ANSIColor.redText("✖ Project creation cancelled."))")
            throw InteractiveWizardError.cancelled
        }

        let config = SwiftBlockConfig(
            projectName: projectName,
            bundlePrefix: bundlePrefix,
            packaging: PackagingConfig(feature: "monolithic", core: "spm"),
            organization: "feature-first",
            generatorTool: .spm,
            guardrails: activeGuardrails,
            cicd: CICDConfig(provider: selectedCICD),
            coreBlocks: selectedCoreBlocks,
            gitInit: gitInitConfirm,
            pathTemplates: [
                "feature": "Sources/App/Features/{module}/{block}",
                "core": "Sources/App/Core/{block}"
            ]
        )

        return ProjectGeneratorOptions(
            projectName: projectName,
            bundlePrefix: bundlePrefix,
            templatePath: defaultTemplatePath,
            customConfig: config,
            baseplateName: "vapor"
        )
    }

    public static func runModuleWizard(
        defaultTemplatePath: String = "/usr/local/share/swiftblock/Blocks/Modules",
        readLine: () -> String? = { InteractiveWizard.readLine() }
    ) throws -> BrickGeneratorOptions {
        print("┌  \(ANSIColor.boldText("Create New Feature Block"))")
        print("│")

        let blocks = BrickRegistry.featureBricks
        let typeChoices = blocks.map { ChoiceOption(title: $0.title, subtitle: $0.description) }

        let selectedIndex = promptChoiceWithOptions(title: "Select Feature Block Type", options: typeChoices, readLine: readLine)
        let selectedType = blocks[selectedIndex].type

        var moduleName = ""
        while moduleName.isEmpty {
            moduleName = prompt(message: "Enter Module Name", readLine: readLine)
            if moduleName.isEmpty {
                print("  \(ANSIColor.yellowText("⚠️"))  Module name cannot be empty.")
            }
        }

        return BrickGeneratorOptions(
            type: selectedType,
            name: moduleName,
            modulesTemplatePath: defaultTemplatePath
        )
    }

    public static func runCoreWizard(
        defaultTemplatePath: String = "/usr/local/share/swiftblock/Blocks/Core",
        readLine: () -> String? = { InteractiveWizard.readLine() }
    ) throws -> BrickGeneratorOptions {
        print("┌  \(ANSIColor.boldText("Create New Core Block"))")
        print("│")

        let blocks = BrickRegistry.coreBricks
        let typeChoices = blocks.map { ChoiceOption(title: $0.title, subtitle: $0.description) }

        let selectedIndex = promptChoiceWithOptions(title: "Select Core Block Type", options: typeChoices, readLine: readLine)
        let selectedType = blocks[selectedIndex].type

        var moduleName = ""
        while moduleName.isEmpty {
            moduleName = prompt(message: "Enter Core Block Name", readLine: readLine)
            if moduleName.isEmpty {
                print("  \(ANSIColor.yellowText("⚠️"))  Block name cannot be empty.")
            }
        }

        return BrickGeneratorOptions(
            type: selectedType,
            name: moduleName,
            modulesTemplatePath: defaultTemplatePath
        )
    }

    public static func runKitCreateWizard(
        projectPath: String = FileManager.default.currentDirectoryPath,
        readLine: () -> String? = { InteractiveWizard.readLine() }
    ) throws -> (name: String, blocks: [String]) {
        print("┌  \(ANSIColor.boldText("Design Architecture Kit"))")
        print("│")

        var kitName = ""
        while kitName.isEmpty {
            kitName = prompt(message: "Enter Kit Name", readLine: readLine).lowercased()
            if kitName.isEmpty {
                print("  \(ANSIColor.yellowText("⚠️"))  Kit name cannot be empty.")
            }
        }

        let featureBlocks = BrickRegistry.featureBricks
        let blockOptions = featureBlocks.map {
            TerminalPrompt.MultiChoiceOption(id: $0.commandName, title: $0.title, subtitle: $0.description, isSelected: true)
        }

        let selectedBlockIds = TerminalPrompt.selectMultiChoice(title: "Select composed bricks for '\(kitName)'", options: blockOptions, readLineFallback: readLine)
        guard !selectedBlockIds.isEmpty else {
            print("└  \(ANSIColor.redText("✖ Kit creation cancelled (no bricks selected)."))")
            throw InteractiveWizardError.cancelled
        }

        if selectedBlockIds.contains("scene") && selectedBlockIds.contains("repository") && !selectedBlockIds.contains("usecase") {
            print("  \(ANSIColor.dimText("ℹ Note: ViewModel will access Repository directly without a UseCase layer."))")
        }

        return (name: kitName, blocks: selectedBlockIds)
    }

    public static func runMonorepoSelectionWizard(
        bricks: [(relativePath: String, manifest: BrickManifest)],
        readLine: () -> String? = { InteractiveWizard.readLine() }
    ) throws -> (relativePath: String, manifest: BrickManifest) {
        print("┌  \(ANSIColor.boldText("Monorepo Git Repository Detected"))")
        print("│  Multiple bricks found in repository:")
        
        let options = bricks.map { item in
            ChoiceOption(
                title: "\(item.manifest.name) (\(item.manifest.instantiation.rawValue.capitalized))",
                subtitle: item.relativePath
            )
        }
        
        let selectedIndex = promptChoiceWithOptions(title: "Select brick to snap", options: options, readLine: readLine)
        return bricks[selectedIndex]
    }

    public static func runBrickVariablesWizard(
        manifest: BrickManifest,
        providedValues: [String: String] = [:],
        readLine: () -> String? = { InteractiveWizard.readLine() }
    ) throws -> [String: String] {
        var resolved = providedValues

        if manifest.variables.isEmpty {
            return resolved
        }

        print("┌  \(ANSIColor.boldText("Configure Variables for '\(manifest.name)'"))")
        print("│")

        for variable in manifest.variables {
            if resolved[variable.name] != nil {
                continue
            }

            if variable.type == "confirm" || variable.type == "bool" {
                let defaultBool = (variable.defaultValue?.lowercased() == "true" || variable.defaultValue == "1")
                let answer = promptConfirm(message: variable.prompt, defaultYes: defaultBool, readLine: readLine)
                resolved[variable.name] = answer ? "true" : "false"
            } else if variable.type == "select", let options = variable.options, !options.isEmpty {
                let choices = options.map { ChoiceOption(title: $0) }
                let idx = promptChoiceWithOptions(title: variable.prompt, options: choices, readLine: readLine)
                resolved[variable.name] = options[idx]
            } else {
                var value = ""
                while value.isEmpty {
                    let promptMsg: String
                    if let def = variable.defaultValue {
                        promptMsg = "\(variable.prompt) (default: \(def))"
                    } else {
                        promptMsg = variable.prompt
                    }
                    let input = prompt(message: promptMsg, readLine: readLine)
                    if input.isEmpty, let def = variable.defaultValue {
                        value = def
                    } else {
                        value = input
                    }

                    if value.isEmpty {
                        print("  \(ANSIColor.yellowText("⚠️"))  Value for '\(variable.name)' cannot be empty.")
                    }
                }
                resolved[variable.name] = value
            }
        }

        return resolved
    }

    public static func runRenameWizard(
        projectPath: String = FileManager.default.currentDirectoryPath,
        readLine: () -> String? = { InteractiveWizard.readLine() }
    ) throws -> String {
        let resolvedRoot = SwiftBlockConfig.findProjectRoot(from: projectPath) ?? projectPath
        let config = try? SwiftBlockConfig.load(from: resolvedRoot)
        let oldName = config?.projectName ?? "CurrentProject"

        print("┌  \(ANSIColor.boldText("Refactor / Rename SwiftBlock Project"))")
        print("│  Current Project Name: \(ANSIColor.cyanText(oldName))")
        print("│  Project Root Path: \(resolvedRoot)")
        print("│")

        var newName = ""
        while newName.isEmpty {
            newName = prompt(message: "Enter New Project Name", readLine: readLine)
            if newName.isEmpty {
                print("  \(ANSIColor.yellowText("⚠️"))  Project name cannot be empty.")
            }
        }
        return newName
    }
}

public enum InteractiveWizardError: Error, LocalizedError, Equatable {
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Operation cancelled by user."
        }
    }
}
