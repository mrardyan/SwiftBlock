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
            if let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines),
               let choice = Int(input),
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

        let confirm = promptConfirm(message: "Create project '\(projectName)' with bundle prefix '\(bundlePrefix)'?", readLine: readLine)
        guard confirm else {
            print("❌ Project creation cancelled.")
            throw InteractiveWizardError.cancelled
        }

        return ProjectGeneratorOptions(
            projectName: projectName,
            bundlePrefix: bundlePrefix,
            templatePath: defaultTemplatePath
        )
    }

    public static func runModuleWizard(
        defaultTemplatePath: String = "/usr/local/share/swiftblock/Blocks/Modules",
        readLine: () -> String? = { Swift.readLine() }
    ) throws -> ModuleGeneratorOptions {
        print("\n🪄 SwiftBlock Feature Module Block Wizard")
        print("──────────────────────────────────────────")

        let types: [ModuleType] = [.scene, .usecase, .repository, .service, .entity, .coordinator, .component, .mapper, .validator]
        let typeTitles = [
            "Scene (MVVM View + ViewModel + State)",
            "UseCase (Domain Protocol + Implementation)",
            "Repository (Data Protocol + Implementation)",
            "Service (API Service Protocol + Implementation)",
            "Entity (Domain Entity / DTO Model)",
            "Coordinator (Navigation Flow Routing)",
            "Component (Reusable UI Component)",
            "Mapper (DTO to Domain Entity Transformer)",
            "Validator (Form Input Field Validator)"
        ]

        let selectedIndex = promptChoice(title: "Select Feature Block Type:", options: typeTitles, readLine: readLine)
        let selectedType = types[selectedIndex]

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

        let types: [ModuleType] = [.storage, .network, .logger, .analytics, .config, .auth, .featureflag]
        let typeTitles = [
            "Storage (Local Persistence Storage Engine)",
            "Network (Network Client / HTTP Request Engine)",
            "Logger (Unified OSLog / Crash Logger Engine)",
            "Analytics (Event Analytics & Metrics Engine)",
            "Config (Environment Config & Feature Flags)",
            "Auth (User Session & Token State Manager)",
            "FeatureFlag (Feature Flags & Remote Toggles Engine)"
        ]

        let selectedIndex = promptChoice(title: "Select Core Block Type:", options: typeTitles, readLine: readLine)
        let selectedType = types[selectedIndex]

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

