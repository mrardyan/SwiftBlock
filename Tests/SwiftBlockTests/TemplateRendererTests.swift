import Foundation
@testable import SwiftBlockCore
import XCTest

final class TemplateRendererTests: XCTestCase {
    func testRenderPlaceholdersAndCustomVariables() {
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

        XCTAssertTrue(rendered.contains("// Header for Profile in MyAwesomeApp"))
        XCTAssertTrue(rendered.contains("let timeout = 60"))
        XCTAssertTrue(rendered.contains("let path = \"Packages/Core/Sources/Core/network\""))
    }

    func testRenderPathPlaceholders() {
        let pathTemplate = "{{paths.feature}}/{module}/{{name}}View.swift"
        let config = SwiftBlockConfig(projectName: "App")

        let renderedPath = TemplateRenderer.renderPath(
            pathTemplate: pathTemplate,
            variables: [:],
            moduleName: "Checkout",
            blockName: "scene",
            config: config
        )

        XCTAssertEqual(renderedPath, "App/Sources/Features/checkout/CheckoutView.swift")
    }

    func testBrickVariableWizardResolution() throws {
        let manifest = BrickManifest(
            name: "network",
            variables: [
                VariableSpec(name: "timeoutInterval", type: "string", prompt: "Timeout?", defaultValue: "30"),
                VariableSpec(name: "enableLogging", type: "bool", prompt: "Enable logging?", defaultValue: "true"),
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

        XCTAssertEqual(result["timeoutInterval"], "45")
        XCTAssertEqual(result["enableLogging"], "true")
    }

    func testRenderConditionalIfElseBranches() {
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
        XCTAssertTrue(observableRendered.contains("@State var vm: MyVM"))
        XCTAssertFalse(observableRendered.contains("@StateObject"))

        let combineRendered = TemplateRenderer.render(
            template: template,
            variables: ["stateStyle": "combine"]
        )
        XCTAssertFalse(combineRendered.contains("@State var vm: MyVM"))
        XCTAssertTrue(combineRendered.contains("@StateObject var vm: MyVM"))
    }

    func testRenderConditionalUnlessBranches() {
        let template = """
        {{#unless isLegacy}}
        ModernSwiftCode()
        {{/unless}}
        """

        let truthy = TemplateRenderer.render(template: template, variables: ["isLegacy": "true"])
        XCTAssertFalse(truthy.contains("ModernSwiftCode()"))

        let falsy = TemplateRenderer.render(template: template, variables: ["isLegacy": "false"])
        XCTAssertTrue(falsy.contains("ModernSwiftCode()"))
    }

    func testRenderConditionalNotEqual() {
        let template = """
        {{#if stateStyle != 'combine'}}
        ModernState()
        {{else}}
        CombineState()
        {{/if}}
        """

        let modern = TemplateRenderer.render(template: template, variables: ["stateStyle": "observable"])
        XCTAssertTrue(modern.contains("ModernState()"))
        XCTAssertFalse(modern.contains("CombineState()"))

        let combine = TemplateRenderer.render(template: template, variables: ["stateStyle": "combine"])
        XCTAssertFalse(combine.contains("ModernState()"))
        XCTAssertTrue(combine.contains("CombineState()"))
    }

    func testRenderConditionalBareVariableTruthyFalsy() {
        let template = """
        {{#if hasLocalCache}}
        let cache = Cache()
        {{/if}}
        """

        let truthy = TemplateRenderer.render(template: template, variables: ["hasLocalCache": "true"])
        XCTAssertTrue(truthy.contains("let cache = Cache()"))

        let falsy = TemplateRenderer.render(template: template, variables: ["hasLocalCache": "false"])
        XCTAssertFalse(falsy.contains("let cache = Cache()"))
    }

    func testRenderConditionalUndefinedVariableIsFalse() {
        let template = """
        {{#if missingVar}}
        NeverShown()
        {{/if}}
        """
        let rendered = TemplateRenderer.render(template: template, variables: ["other": "1"])
        XCTAssertFalse(rendered.contains("NeverShown()"))
    }

    func testRenderConditionalNestedBlocks() {
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
        XCTAssertTrue(offline.contains("cacheLayer()"))
        XCTAssertFalse(offline.contains("cacheFallback()"))
        XCTAssertFalse(offline.contains("remoteOnly()"))

        let remote = TemplateRenderer.render(template: template, variables: ["strategy": "remote-only"])
        XCTAssertTrue(remote.contains("remoteOnly()"))
        XCTAssertFalse(remote.contains("cacheLayer()"))
    }

    func testRenderConditionalWithoutElseBranch() {
        let template = """
        {{#if stateStyle == 'observable'}}
        import Observation
        {{/if}}
        import Foundation
        """

        let rendered = TemplateRenderer.render(template: template, variables: ["stateStyle": "observable"])
        XCTAssertTrue(rendered.contains("import Observation"))
        XCTAssertTrue(rendered.contains("import Foundation"))

        let combine = TemplateRenderer.render(template: template, variables: ["stateStyle": "combine"])
        XCTAssertFalse(combine.contains("import Observation"))
        XCTAssertTrue(combine.contains("import Foundation"))
    }

    func testRenderConditionalEvaluatesVariableToVariableComparison() {
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
        XCTAssertTrue(rendered.contains("Match()"))
        XCTAssertFalse(rendered.contains("NoMatch()"))

        let mismatch = TemplateRenderer.render(
            template: template,
            variables: ["mode": "fast", "expectedMode": "slow"]
        )
        XCTAssertFalse(mismatch.contains("\nMatch()\n"))
        XCTAssertTrue(mismatch.contains("NoMatch()"))
    }

    func testRenderConditionalPreservesContentOutsideBlocks() {
        let template = """
        import SwiftUI
        {{#if stateStyle == 'combine'}}
        @StateObject private var vm: MyVM
        {{/if}}
        public struct MyView: View { }
        """

        let rendered = TemplateRenderer.render(template: template, variables: [:])
        XCTAssertTrue(rendered.contains("import SwiftUI"))
        XCTAssertTrue(rendered.contains("public struct MyView: View { }"))
        XCTAssertFalse(rendered.contains("@StateObject"))
    }
}
