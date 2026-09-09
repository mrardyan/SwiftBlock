import Foundation
import Testing
@testable import SwiftBlockCore

struct InteractiveWizardTests {

    @Test func initWizardInstance() {
        let wizard = InteractiveWizard()
        #expect(type(of: wizard) == InteractiveWizard.self)
    }

    @Test func promptCustomInputAndFallback() {
        let customInput = InteractiveWizard.prompt(message: "Name", readLine: { "MyCustomApp" })
        #expect(customInput == "MyCustomApp")

        let fallbackInput = InteractiveWizard.prompt(message: "Prefix", defaultValue: "com.example", readLine: { "" })
        #expect(fallbackInput == "com.example")

        let noDefaultInput = InteractiveWizard.prompt(message: "Optional", defaultValue: nil, readLine: { nil })
        #expect(noDefaultInput == "")
    }

    @Test func promptChoiceValidAndRetry() {
        var inputs = ["invalid", "99", "1"]
        let choiceIndex = InteractiveWizard.promptChoice(title: "Select Block", options: ["Scene", "UseCase"], readLine: {
            inputs.isEmpty ? nil : inputs.removeFirst()
        })
        #expect(choiceIndex == 0)
    }

    @Test func promptConfirmDefaultsAndExplicit() {
        let confirmDefaultYes = InteractiveWizard.promptConfirm(message: "Proceed?", defaultYes: true, readLine: { "" })
        #expect(confirmDefaultYes == true)

        let confirmDefaultNo = InteractiveWizard.promptConfirm(message: "Proceed?", defaultYes: false, readLine: { "" })
        #expect(confirmDefaultNo == false)

        let confirmExplicitYes = InteractiveWizard.promptConfirm(message: "Proceed?", readLine: { "y" })
        #expect(confirmExplicitYes == true)

        let confirmExplicitNo = InteractiveWizard.promptConfirm(message: "Proceed?", readLine: { "n" })
        #expect(confirmExplicitNo == false)
    }

    @Test func runProjectWizardSuccess() throws {
        var inputs = ["", "AwesomeApp", "com.mycompany", "y"]
        let options = try InteractiveWizard.runProjectWizard(defaultTemplatePath: "/tmp/template", readLine: {
            inputs.isEmpty ? nil : inputs.removeFirst()
        })

        #expect(options.projectName == "AwesomeApp")
        #expect(options.bundlePrefix == "com.mycompany")
        #expect(options.templatePath == "/tmp/template")
    }

    @Test func runProjectWizardCancelled() {
        var inputs = ["AwesomeApp", "com.mycompany", "n"]
        #expect(throws: InteractiveWizardError.cancelled) {
            try InteractiveWizard.runProjectWizard(defaultTemplatePath: "/tmp/template", readLine: {
                inputs.isEmpty ? nil : inputs.removeFirst()
            })
        }
    }

    @Test func runModuleWizardSuccess() throws {
        var inputs = ["3", "", "UserRepo"] // Choice 3 = Repository
        let options = try InteractiveWizard.runModuleWizard(defaultTemplatePath: "/tmp/modules", readLine: {
            inputs.isEmpty ? nil : inputs.removeFirst()
        })

        #expect(options.type == .repository)
        #expect(options.moduleName == "UserRepo")
        #expect(options.modulesTemplatePath == "/tmp/modules")
    }

    @Test func errorDescription() {
        let err = InteractiveWizardError.cancelled
        #expect(err.errorDescription == "Operation cancelled by user.")
    }
}

