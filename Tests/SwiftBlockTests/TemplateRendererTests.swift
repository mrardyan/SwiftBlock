import Foundation
import Testing
@testable import SwiftBlockCore

struct TemplateRendererTests {

    @Test func renderPlaceholdersAndCustomVariables() {
        let template = """
        // Header for {{name}} in {{projectName}}
        let timeout = {{timeoutInterval}}
        let path = "{{paths.network}}"
        """

        let config = SwiftBlockConfig(projectName: "MyAwesomeApp")
        let vars = ["timeoutInterval": "60"]

        let rendered = TemplateRenderer.render(
            template: template,
            variables: vars,
            config: config,
            moduleName: "Profile",
            projectName: "MyAwesomeApp"
        )

        #expect(rendered.contains("// Header for Profile in MyAwesomeApp"))
        #expect(rendered.contains("let timeout = 60"))
        #expect(rendered.contains("let path = \"Packages/Core/Sources/Core/network\""))
    }

    @Test func renderPathPlaceholders() {
        let pathTemplate = "{{paths.feature}}/{module}/{{name}}View.swift"
        let config = SwiftBlockConfig(projectName: "App")

        let renderedPath = TemplateRenderer.renderPath(
            pathTemplate: pathTemplate,
            variables: [:],
            moduleName: "Checkout",
            blockName: "scene",
            config: config
        )

        #expect(renderedPath == "App/Sources/Features/checkout/CheckoutView.swift")
    }

    @Test func brickVariableWizardResolution() throws {
        let manifest = BrickManifest(
            name: "network",
            variables: [
                VariableSpec(name: "timeoutInterval", type: "string", prompt: "Timeout?", defaultValue: "30"),
                VariableSpec(name: "enableLogging", type: "bool", prompt: "Enable logging?", defaultValue: "true")
            ]
        )

        let provided = ["timeoutInterval": "45"]
        let inputs = ["\n"] // default for confirm prompt
        var inputIndex = 0

        let result = try InteractiveWizard.runBrickVariablesWizard(
            manifest: manifest,
            providedValues: provided,
            readLine: {
                defer { inputIndex += 1 }
                return inputIndex < inputs.count ? inputs[inputIndex] : nil
            }
        )

        #expect(result["timeoutInterval"] == "45")
        #expect(result["enableLogging"] == "true")
    }
}
