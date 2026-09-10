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
        print("◇  \(ANSIColor.boldText("Project Configuration"))")

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

        let toolChoices = ProjectGeneratorTool.allCases.map { ChoiceOption(title: $0.title) }
        let toolChoiceIndex = promptChoiceWithOptions(title: "Select Build Tool Generator", options: toolChoices, readLine: readLine)
        let selectedTool = ProjectGeneratorTool.allCases[toolChoiceIndex]

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
        var selectedCoreBlocks = selectedCoreBlockIds.compactMap { ModuleType(rawValue: $0) }

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
        let confirm = promptConfirm(message: "Create project '\(projectName)' with prefix '\(bundlePrefix)'?", readLine: readLine)
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
            customConfig: config
        )
    }

    public static func runModuleWizard(
        defaultTemplatePath: String = "/usr/local/share/swiftblock/Blocks/Modules",
        readLine: () -> String? = { InteractiveWizard.readLine() }
    ) throws -> ModuleGeneratorOptions {
        print("┌  \(ANSIColor.boldText("Create New Feature Block"))")
        print("│")

        let blocks = BlockRegistry.featureBlocks
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

        return ModuleGeneratorOptions(
            type: selectedType,
            moduleName: moduleName,
            modulesTemplatePath: defaultTemplatePath
        )
    }

    public static func runCoreWizard(
        defaultTemplatePath: String = "/usr/local/share/swiftblock/Blocks/Core",
        readLine: () -> String? = { InteractiveWizard.readLine() }
    ) throws -> ModuleGeneratorOptions {
        print("┌  \(ANSIColor.boldText("Create New Core Block"))")
        print("│")

        let blocks = BlockRegistry.coreBlocks
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

        return ModuleGeneratorOptions(
            type: selectedType,
            moduleName: moduleName,
            modulesTemplatePath: defaultTemplatePath
        )
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
