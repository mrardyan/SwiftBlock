import Foundation
@testable import SwiftBlockCore
import XCTest

final class InteractiveWizardTests: XCTestCase {
    func testInitWizardInstance() {
        let wizard = InteractiveWizard()
        XCTAssertTrue(type(of: wizard) == InteractiveWizard.self)
    }

    func testPromptCustomInputAndFallback() {
        let customInput = InteractiveWizard.prompt(message: "Name", readLine: { "MyCustomApp" })
        XCTAssertEqual(customInput, "MyCustomApp")

        let fallbackInput = InteractiveWizard.prompt(message: "Prefix", defaultValue: "com.example", readLine: { "" })
        XCTAssertEqual(fallbackInput, "com.example")

        let noDefaultInput = InteractiveWizard.prompt(message: "Optional", defaultValue: nil, readLine: { nil })
        XCTAssertEqual(noDefaultInput, "")
    }

    func testPromptChoiceValidAndRetry() {
        var inputs = ["invalid", "99", "1"]
        let choiceIndex = InteractiveWizard.promptChoice(title: "Select Block", options: ["Scene", "UseCase"], readLine: {
            inputs.isEmpty ? nil : inputs.removeFirst()
        })
        XCTAssertEqual(choiceIndex, 0)
    }

    func testPromptConfirmDefaultsAndExplicit() {
        let confirmDefaultYes = InteractiveWizard.promptConfirm(message: "Proceed?", defaultYes: true, readLine: { "" })
        XCTAssertEqual(confirmDefaultYes, true)

        let confirmDefaultNo = InteractiveWizard.promptConfirm(message: "Proceed?", defaultYes: false, readLine: { "" })
        XCTAssertEqual(confirmDefaultNo, false)

        let confirmExplicitYes = InteractiveWizard.promptConfirm(message: "Proceed?", readLine: { "y" })
        XCTAssertEqual(confirmExplicitYes, true)

        let confirmExplicitNo = InteractiveWizard.promptConfirm(message: "Proceed?", readLine: { "n" })
        XCTAssertEqual(confirmExplicitNo, false)
    }

    func testRunProjectWizardSuccess() throws {
        var inputs = ["1", "AwesomeApp", "com.mycompany", "1", "1", "1", "1", "y", "1", "1", "y", "y"]
        let options = try InteractiveWizard.runProjectWizard(defaultTemplatePath: "/tmp/template", readLine: {
            inputs.isEmpty ? nil : inputs.removeFirst()
        })

        XCTAssertEqual(options.projectName, "AwesomeApp")
        XCTAssertEqual(options.bundlePrefix, "com.mycompany")
        XCTAssertEqual(options.templatePath, "/tmp/template")
        XCTAssertEqual(options.baseplateName, "swiftui")
    }

    func testRunVaporProjectWizardSuccess() throws {
        var inputs = ["2", "MyVaporApi", "com.mycompany.api", "1", "y", "y"]
        let options = try InteractiveWizard.runProjectWizard(defaultTemplatePath: "/tmp/template", readLine: {
            inputs.isEmpty ? nil : inputs.removeFirst()
        })

        XCTAssertEqual(options.projectName, "MyVaporApi")
        XCTAssertEqual(options.bundlePrefix, "com.mycompany.api")
        XCTAssertEqual(options.templatePath, "/tmp/template")
        XCTAssertEqual(options.baseplateName, "vapor")
    }

    func testRunProjectWizardCancelled() {
        var inputs = ["1", "AwesomeApp", "com.mycompany", "1", "1", "1", "1", "y", "1", "1", "y", "n"]
        XCTAssertThrowsError(try InteractiveWizard.runProjectWizard(defaultTemplatePath: "/tmp/template", readLine: {
            inputs.isEmpty ? nil : inputs.removeFirst()
        }))
    }

    func testRunModuleWizardSuccess() throws {
        let blocks = BrickRegistry.featureBricks.filter { $0.isCompatible(withVapor: false) }
        guard let repoIndex = blocks.firstIndex(where: { $0.commandName == "repository" }) else {
            XCTFail("repository brick not found in catalog")
            return
        }
        var inputs = ["\(repoIndex + 1)", "", "UserRepo"]
        let options = try InteractiveWizard.runModuleWizard(defaultTemplatePath: "/tmp/modules", readLine: {
            inputs.isEmpty ? nil : inputs.removeFirst()
        })

        XCTAssertEqual(options.type, .repository)
        XCTAssertEqual(options.name, "UserRepo")
        XCTAssertEqual(options.modulesTemplatePath, "/tmp/modules")
    }

    func testRunCoreWizardSuccess() throws {
        let blocks = BrickRegistry.coreBricks.filter { $0.isCompatible(withVapor: false) }
        guard let storageIndex = blocks.firstIndex(where: { $0.commandName == "storage" }) else {
            XCTFail("storage brick not found in catalog")
            return
        }
        var inputs = ["\(storageIndex + 1)", "", "UserStorage"]
        let options = try InteractiveWizard.runCoreWizard(defaultTemplatePath: "/tmp/core", readLine: {
            inputs.isEmpty ? nil : inputs.removeFirst()
        })

        XCTAssertEqual(options.type, .storage)
        XCTAssertEqual(options.name, "UserStorage")
        XCTAssertEqual(options.modulesTemplatePath, "/tmp/core")
    }

    func testRunKitCreateWizardSuccess() throws {
        var inputs = ["", "my_custom_kit", "a"] // a = toggle all blocks
        let result = try InteractiveWizard.runKitCreateWizard(readLine: {
            inputs.isEmpty ? nil : inputs.removeFirst()
        })

        XCTAssertEqual(result.name, "my_custom_kit")
        XCTAssertFalse(result.blocks.isEmpty)
    }

    func testErrorDescription() {
        let err = InteractiveWizardError.cancelled
        XCTAssertEqual(err.errorDescription, "Operation cancelled by user.")
    }

    func testStripANSIEscapeCodes() {
        let dirtyInput = "MyCompany\u{001B}[D\u{001B}[CApp"
        let cleanInput = InteractiveWizard.stripANSIEscapeCodes(dirtyInput)
        XCTAssertEqual(cleanInput, "MyCompanyApp")
    }

    func testRunRenameWizardSuccess() throws {
        var inputs = ["", "NewAwesomeProject"]
        let newName = try InteractiveWizard.runRenameWizard(projectPath: ".", readLine: {
            inputs.isEmpty ? nil : inputs.removeFirst()
        })
        XCTAssertEqual(newName, "NewAwesomeProject")
    }

    func testRunBrickFlavorsWizardReturnsProvidedSelectionsWhenNoFlavors() throws {
        let manifest = BrickManifest(name: "plain")
        var inputs = ["1"]
        let result = try InteractiveWizard.runBrickFlavorsWizard(
            manifest: manifest,
            providedSelections: ["custom": "value"],
            readLine: { inputs.isEmpty ? nil : inputs.removeFirst() }
        )
        XCTAssertEqual(result["custom"], "value")
    }

    func testRunBrickFlavorsWizardPromptsForEachUnconfiguredFlavor() throws {
        let manifest = BrickManifest(
            name: "scene",
            flavors: [
                "stateStyle": FlavorSpec(
                    id: "stateStyle",
                    prompt: "Select state observation style",
                    defaultValue: "observable",
                    options: [
                        FlavorOptionSpec(id: "observable", title: "@Observable"),
                        FlavorOptionSpec(id: "combine", title: "ObservableObject"),
                    ]
                ),
            ]
        )
        // Select option 2 (combine) via 1-based fallback choice
        var inputs = ["2"]
        let result = try InteractiveWizard.runBrickFlavorsWizard(
            manifest: manifest,
            providedSelections: [:],
            readLine: { inputs.isEmpty ? nil : inputs.removeFirst() }
        )
        XCTAssertEqual(result["statestyle"], "combine")
    }

    func testRunBrickFlavorsWizardSkipsProvidedSelections() throws {
        let manifest = BrickManifest(
            name: "scene",
            flavors: [
                "stateStyle": FlavorSpec(
                    id: "stateStyle",
                    prompt: "Select state observation style",
                    defaultValue: "observable",
                    options: [
                        FlavorOptionSpec(id: "observable", title: "@Observable"),
                        FlavorOptionSpec(id: "combine", title: "ObservableObject"),
                    ]
                ),
            ]
        )
        var inputs = ["1"]
        let result = try InteractiveWizard.runBrickFlavorsWizard(
            manifest: manifest,
            providedSelections: ["stateStyle": "combine"],
            readLine: { inputs.isEmpty ? nil : inputs.removeFirst() }
        )
        XCTAssertEqual(result["stateStyle"], "combine")
    }

    func testRunBrickFlavorsWizardSelectsByNumber() throws {
        let manifest = BrickManifest(
            name: "repository",
            flavors: [
                "strategy": FlavorSpec(
                    id: "strategy",
                    prompt: "Select repository data fetching strategy",
                    defaultValue: "offline-first",
                    options: [
                        FlavorOptionSpec(id: "remote-only", title: "Remote Only"),
                        FlavorOptionSpec(id: "offline-first", title: "Offline-First"),
                        FlavorOptionSpec(id: "local-only", title: "Local Only"),
                    ]
                ),
            ]
        )
        // Select option 3 (local-only) via 1-based fallback choice
        var inputs = ["3"]
        let result = try InteractiveWizard.runBrickFlavorsWizard(
            manifest: manifest,
            providedSelections: [:],
            readLine: { inputs.isEmpty ? nil : inputs.removeFirst() }
        )
        XCTAssertEqual(result["strategy"], "local-only")
    }
}
