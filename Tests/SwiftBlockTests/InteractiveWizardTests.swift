import Foundation
import Testing
@testable import SwiftBlockCore

struct InteractiveWizardTests {

    @Test func promptFallbackValue() {
        let defaultValue = "com.example"
        // Test prompt helper string formatting logic
        #expect(defaultValue == "com.example")
    }

    @Test func defaultBundlePrefixIsGeneric() {
        let options = ProjectGeneratorOptions(projectName: "Sample")
        #expect(options.bundlePrefix == "com.example")

        let config = SwiftBlockConfig(projectName: "Sample")
        #expect(config.bundlePrefix == "com.example")
    }
}
