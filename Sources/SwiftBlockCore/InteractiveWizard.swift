import Foundation

public class InteractiveWizard {
    public init() {}

    public static func prompt(
        message: String,
        defaultValue: String? = nil,
        readLine: () -> String? = { Swift.readLine() }
    ) -> String {
        if let defaultValue = defaultValue, !defaultValue.isEmpty {
            print("\(message) [default: \(defaultValue)]: ", terminator: "")
        } else {
            print("\(message): ", terminator: "")
        }
        fflush(stdout)

        guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines), !input.isEmpty else {
            return defaultValue ?? ""
        }
        return input
    }

    public static func promptChoice(
        title: String,
        options: [String],
        readLine: () -> String? = { Swift.readLine() }
    ) -> Int {
        print("\n\(title)")
        for (index, option) in options.enumerated() {
            print("  \(index + 1)) \(option)")
        }
        
        while true {
            print("Choice [1-\(options.count)]: ", terminator: "")
            fflush(stdout)
            guard let line = readLine() else {
                return 0
            }
            let input = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if let choice = Int(input),
               choice >= 1 && choice <= options.count {
                return choice - 1
            }
            print("⚠️ Invalid choice. Please enter a number between 1 and \(options.count).")
        }
    }

    public static func promptConfirm(
        message: String,
        defaultYes: Bool = true,
        readLine: () -> String? = { Swift.readLine() }
    ) -> Bool {
        let suffix = defaultYes ? "[Y/n]" : "[y/N]"
        print("\(message) \(suffix): ", terminator: "")
        fflush(stdout)

        guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !input.isEmpty else {
            return defaultYes
        }
        return input.hasPrefix("y")
    }

    public static func runProjectWizard(
        defaultTemplatePath: String,
        readLine: () -> String? = { Swift.readLine() }
    ) throws -> ProjectGeneratorOptions {
        print("\n🪄 SwiftBlock Project Scaffolding Wizard")
        print("────────────────────────────────────────")

        var projectName = ""
        while projectName.isEmpty {
            projectName = prompt(message: "Enter Project Name (e.g. MyApp)", readLine: readLine)
            if projectName.isEmpty {
                print("⚠️ Project name cannot be empty.")
            }
        }

        let bundlePrefix = prompt(message: "Enter Bundle Identifier Prefix", defaultValue: "com.example", readLine: readLine)

        let featurePkgOptions = [
            "Monolithic / Main Target (e.g. App/Sources/Features/Home/...)",
            "SPM Multi-Package (e.g. Packages/HomeFeature/Sources/HomeFeature/...)"
        ]
        let featurePkgChoice = promptChoice(title: "📦 Select Feature Packaging Strategy:", options: featurePkgOptions, readLine: readLine)
        let featurePkg = featurePkgChoice == 0 ? "monolithic" : "spm"

        let corePkgOptions = [
            "Monolithic / Main Target (e.g. App/Sources/Core/Storage/...)",
            "SPM Core Package (e.g. Packages/Core/Sources/Storage/...)"
        ]
        let corePkgChoice = promptChoice(title: "📦 Select Core Packaging Strategy:", options: corePkgOptions, readLine: readLine)
        let corePkg = corePkgChoice == 0 ? "monolithic" : "spm"

        let orgOptions = [
            "Business-First (e.g. Home/Scene, Home/UseCase, Payment/Scene)",
            "Technical-First (e.g. Scenes/Home, UseCases/Home, Repositories/Payment)"
        ]
        let orgChoice = promptChoice(title: "📁 Select Code Organization Strategy:", options: orgOptions, readLine: readLine)
        let orgStrategy = orgChoice == 0 ? "business-first" : "technical-first"

        let confirm = promptConfirm(message: "Create project '\(projectName)' with bundle prefix '\(bundlePrefix)'?", readLine: readLine)
        guard confirm else {
            print("❌ Project creation cancelled.")
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
            coreTemplate = "Packages/Core/Sources/{block}"
        } else {
            coreTemplate = "App/Sources/Core/{block}"
        }

        let config = SwiftBlockConfig(
            projectName: projectName,
            bundlePrefix: bundlePrefix,
            packaging: PackagingConfig(feature: featurePkg, core: corePkg),
            organization: orgStrategy,
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
        readLine: () -> String? = { Swift.readLine() }
    ) throws -> ModuleGeneratorOptions {
        print("\n🪄 SwiftBlock Feature Module Block Wizard")
        print("──────────────────────────────────────────")

        let blocks = BlockRegistry.featureBlocks
        let typeTitles = blocks.map { "\($0.title) (\($0.description))" }

        let selectedIndex = promptChoice(title: "Select Feature Block Type:", options: typeTitles, readLine: readLine)
        let selectedType = blocks[selectedIndex].type

        var moduleName = ""
        while moduleName.isEmpty {
            moduleName = prompt(message: "Enter Module Name (e.g. Home)", readLine: readLine)
            if moduleName.isEmpty {
                print("⚠️ Module name cannot be empty.")
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
        readLine: () -> String? = { Swift.readLine() }
    ) throws -> ModuleGeneratorOptions {
        print("\n🪄 SwiftBlock Core Foundation Block Wizard")
        print("───────────────────────────────────────────")

        let blocks = BlockRegistry.coreBlocks
        let typeTitles = blocks.map { "\($0.title) (\($0.description))" }

        let selectedIndex = promptChoice(title: "Select Core Block Type:", options: typeTitles, readLine: readLine)
        let selectedType = blocks[selectedIndex].type

        var moduleName = ""
        while moduleName.isEmpty {
            moduleName = prompt(message: "Enter Core Block Name (e.g. AppStorage)", readLine: readLine)
            if moduleName.isEmpty {
                print("⚠️ Block name cannot be empty.")
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

