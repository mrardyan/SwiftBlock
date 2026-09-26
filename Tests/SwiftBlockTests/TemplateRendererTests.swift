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

    @Test func renderConditionalIfElseBranches() {
        let template = """
        struct MyView {
        {{#if stateStyle == 'observable'}}
            @State var vm: MyVM
        {{else}}
            @StateObject var vm: MyVM
        {{/if}}
        }
        """

        let observableRendered = TemplateRenderer.render(
            template: template,
            variables: ["stateStyle": "observable"]
        )
        #expect(observableRendered.contains("@State var vm: MyVM"))
        #expect(!observableRendered.contains("@StateObject"))

        let combineRendered = TemplateRenderer.render(
            template: template,
            variables: ["stateStyle": "combine"]
        )
        #expect(!combineRendered.contains("@State var vm: MyVM"))
        #expect(combineRendered.contains("@StateObject var vm: MyVM"))
    }

    @Test func renderConditionalUnlessBranches() {
        let template = """
        {{#unless isLegacy}}
        ModernSwiftCode()
        {{/unless}}
        """

        let truthy = TemplateRenderer.render(template: template, variables: ["isLegacy": "true"])
        #expect(!truthy.contains("ModernSwiftCode()"))

        let falsy = TemplateRenderer.render(template: template, variables: ["isLegacy": "false"])
        #expect(falsy.contains("ModernSwiftCode()"))
    }

    @Test func renderConditionalNotEqual() {
        let template = """
        {{#if stateStyle != 'combine'}}
        ModernState()
        {{else}}
        CombineState()
        {{/if}}
        """

        let modern = TemplateRenderer.render(template: template, variables: ["stateStyle": "observable"])
        #expect(modern.contains("ModernState()"))
        #expect(!modern.contains("CombineState()"))

        let combine = TemplateRenderer.render(template: template, variables: ["stateStyle": "combine"])
        #expect(!combine.contains("ModernState()"))
        #expect(combine.contains("CombineState()"))
    }

    @Test func renderConditionalBareVariableTruthyFalsy() {
        let template = """
        {{#if hasLocalCache}}
        let cache = Cache()
        {{/if}}
        """

        let truthy = TemplateRenderer.render(template: template, variables: ["hasLocalCache": "true"])
        #expect(truthy.contains("let cache = Cache()"))

        let falsy = TemplateRenderer.render(template: template, variables: ["hasLocalCache": "false"])
        #expect(!falsy.contains("let cache = Cache()"))
    }

    @Test func renderConditionalUndefinedVariableIsFalse() {
        let template = """
        {{#if missingVar}}
        NeverShown()
        {{/if}}
        """
        let rendered = TemplateRenderer.render(template: template, variables: ["other": "1"])
        #expect(!rendered.contains("NeverShown()"))
    }

    @Test func renderConditionalNestedBlocks() {
        let template = """
        {{#if strategy == 'offline-first'}}
        {{#if hasLocalCache}}
        cacheLayer()
        {{else}}
        cacheFallback()
        {{/if}}
        {{else}}
        remoteOnly()
        {{/if}}
        """

        let offline = TemplateRenderer.render(
            template: template,
            variables: ["strategy": "offline-first", "hasLocalCache": "true"]
        )
        #expect(offline.contains("cacheLayer()"))
        #expect(!offline.contains("cacheFallback()"))
        #expect(!offline.contains("remoteOnly()"))

        let remote = TemplateRenderer.render(template: template, variables: ["strategy": "remote-only"])
        #expect(remote.contains("remoteOnly()"))
        #expect(!remote.contains("cacheLayer()"))
    }

    @Test func renderConditionalWithoutElseBranch() {
        let template = """
        {{#if stateStyle == 'observable'}}
        import Observation
        {{/if}}
        import Foundation
        """

        let rendered = TemplateRenderer.render(template: template, variables: ["stateStyle": "observable"])
        #expect(rendered.contains("import Observation"))
        #expect(rendered.contains("import Foundation"))

        let combine = TemplateRenderer.render(template: template, variables: ["stateStyle": "combine"])
        #expect(!combine.contains("import Observation"))
        #expect(combine.contains("import Foundation"))
    }

    @Test func renderConditionalEvaluatesVariableToVariableComparison() {
        let template = """
        {{#if mode == expectedMode}}
        Match()
        {{else}}
        NoMatch()
        {{/if}}
        """
        let rendered = TemplateRenderer.render(
            template: template,
            variables: ["mode": "fast", "expectedMode": "fast"]
        )
        #expect(rendered.contains("Match()"))
        #expect(!rendered.contains("NoMatch()"))

        let mismatch = TemplateRenderer.render(
            template: template,
            variables: ["mode": "fast", "expectedMode": "slow"]
        )
        #expect(!mismatch.contains("\nMatch()\n"))
        #expect(mismatch.contains("NoMatch()"))
    }

    @Test func renderConditionalPreservesContentOutsideBlocks() {
        let template = """
        import SwiftUI
        {{#if stateStyle == 'combine'}}
        @StateObject private var vm: MyVM
        {{/if}}
        public struct MyView: View { }
        """

        let rendered = TemplateRenderer.render(template: template, variables: [:])
        #expect(rendered.contains("import SwiftUI"))
        #expect(rendered.contains("public struct MyView: View { }"))
        #expect(!rendered.contains("@StateObject"))
    }
}
