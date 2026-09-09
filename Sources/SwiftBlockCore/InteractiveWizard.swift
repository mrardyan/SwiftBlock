import Foundation

public class InteractiveWizard {
    public init() {}

    public static func prompt(message: String, defaultValue: String? = nil) -> String {
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

    public static func promptChoice(title: String, options: [String]) -> Int {
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

    public static func promptConfirm(message: String, defaultYes: Bool = true) -> Bool {
        let suffix = defaultYes ? "[Y/n]" : "[y/N]"
        print("\(message) \(suffix): ", terminator: "")
        fflush(stdout)

        guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !input.isEmpty else {
            return defaultYes
        }
        return input.hasPrefix("y")
    }

    public static func runProjectWizard(defaultTemplatePath: String) throws -> ProjectGeneratorOptions {
        print("\n🪄 SwiftBlock Project Scaffolding Wizard")
        print("────────────────────────────────────────")

        var projectName = ""
        while projectName.isEmpty {
            projectName = prompt(message: "Enter Project Name (e.g. MyApp)")
            if projectName.isEmpty {
                print("⚠️ Project name cannot be empty.")
            }
        }

        let bundlePrefix = prompt(message: "Enter Bundle Identifier Prefix", defaultValue: "com.example")

        let confirm = promptConfirm(message: "Create project '\(projectName)' with bundle prefix '\(bundlePrefix)'?")
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

    public static func runModuleWizard(defaultTemplatePath: String) throws -> ModuleGeneratorOptions {
        print("\n🪄 SwiftBlock Architecture Module Wizard")
        print("────────────────────────────────────────")

        let types = ModuleType.allCases
        let typeTitles = [
            "Scene (MVVM View + ViewModel + State)",
            "UseCase (Domain Protocol + Implementation)",
            "Repository (Data Protocol + Implementation)",
            "Service (API Service Protocol + Implementation)"
        ]

        let selectedIndex = promptChoice(title: "Select Module Block Type:", options: typeTitles)
        let selectedType = types[selectedIndex]

        var moduleName = ""
        while moduleName.isEmpty {
            moduleName = prompt(message: "Enter Module Name (e.g. Home)")
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
}

public enum InteractiveWizardError: Error, LocalizedError {
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Operation cancelled by user."
        }
    }
}
