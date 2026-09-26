import Foundation
import Testing
@testable import SwiftBlockCore

struct FlavorResolverTests {

    private func makeManifest(withFlavorYAML: String) throws -> BrickManifest {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("FlavorResolver_\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let brickDir = tempDir.appendingPathComponent("flavored", isDirectory: true)
        try FileManager.default.createDirectory(at: brickDir, withIntermediateDirectories: true)
        let yml = """
        name: flavored
        category: core
        defaultPath: App/Sources/Flavored
        \(withFlavorYAML)
        """
        try yml.write(to: brickDir.appendingPathComponent("brick.yml"), atomically: true, encoding: .utf8)
        guard let manifest = BrickManifest.load(fromPath: brickDir.path) else {
            throw BrickManifestError.missing
        }
        return manifest
    }

    private enum BrickManifestError: Error {
        case missing
    }

    private static let sceneYAML = """
    flavors:
      stateStyle:
        prompt: Select state observation style
        default: observable
        options:
          - id: observable
            title: @Observable
            variables:
              usesObservation: true
          - id: combine
            title: ObservableObject (Combine)
            variables:
              usesObservation: false
    """

    @Test func appliesDefaultOptionWhenNoSelection() throws {
        let manifest = try makeManifest(withFlavorYAML: Self.sceneYAML)
        let result = FlavorResolver.resolve(manifest: manifest, selections: [:])
        #expect(result.variables["stateStyle"] == "observable")
        #expect(result.variables["usesObservation"] == "true")
    }

    @Test func appliesSelectedOption() throws {
        let manifest = try makeManifest(withFlavorYAML: Self.sceneYAML)
        let result = FlavorResolver.resolve(manifest: manifest, selections: ["stateStyle": "combine"])
        #expect(result.variables["stateStyle"] == "combine")
        #expect(result.variables["usesObservation"] == "false")
    }

    @Test func selectionIsCaseInsensitive() throws {
        let manifest = try makeManifest(withFlavorYAML: Self.sceneYAML)
        let result = FlavorResolver.resolve(manifest: manifest, selections: ["STATESTYLE": "Combine"])
        #expect(result.variables["stateStyle"] == "combine")
    }

    @Test func ignoresUnknownOptionKeepsDefault() throws {
        let manifest = try makeManifest(withFlavorYAML: Self.sceneYAML)
        let result = FlavorResolver.resolve(manifest: manifest, selections: ["stateStyle": "nope"])
        // Unknown selection falls back to default behavior (first option)
        #expect(result.variables["stateStyle"] == "observable")
    }

    @Test func undeclaredKeysBecomeTemplateVariables() throws {
        let manifest = try makeManifest(withFlavorYAML: Self.sceneYAML)
        let result = FlavorResolver.resolve(manifest: manifest, selections: ["timeout": "60"])
        #expect(result.variables["timeout"] == "60")
    }

    @Test func preservesProvidedVariables() throws {
        let manifest = try makeManifest(withFlavorYAML: Self.sceneYAML)
        let result = FlavorResolver.resolve(
            manifest: manifest,
            selections: [:],
            variables: ["timeoutInterval": "45"]
        )
        #expect(result.variables["timeoutInterval"] == "45")
        #expect(result.variables["stateStyle"] == "observable")
    }

    @Test func addsFlavorScopedOptionalDependencies() throws {
        let manifest = try makeManifest(withFlavorYAML: """
        flavors:
          strategy:
            prompt: Select strategy
            default: offline-first
            options:
              - id: remote-only
                title: Remote Only
              - id: offline-first
                title: Offline First
                dependencies:
                  optional:
                    - name: storage
                      description: Local cache
        """)
        let result = FlavorResolver.resolve(manifest: manifest, selections: ["strategy": "offline-first"])
        #expect(result.selectedOptionalDeps.contains("storage"))

        let remoteResult = FlavorResolver.resolve(manifest: manifest, selections: ["strategy": "remote-only"])
        #expect(remoteResult.selectedOptionalDeps.isEmpty)
    }

    @Test func validateSelectionReportsUnknownOption() throws {
        let manifest = try makeManifest(withFlavorYAML: Self.sceneYAML)
        #expect(FlavorResolver.validateSelection(manifest: manifest, flavorKey: "stateStyle", selectedValue: "combine") == nil)
        #expect(FlavorResolver.validateSelection(manifest: manifest, flavorKey: "stateStyle", selectedValue: "bad")?.contains("Unknown option 'bad'") == true)
    }
}