import Foundation
@testable import SwiftBlockCore
import XCTest

final class FlavorResolverTests: XCTestCase {
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

    func testAppliesDefaultOptionWhenNoSelection() throws {
        let manifest = try makeManifest(withFlavorYAML: Self.sceneYAML)
        let result = FlavorResolver.resolve(manifest: manifest, selections: [:])
        XCTAssertEqual(result.variables["stateStyle"], "observable")
        XCTAssertEqual(result.variables["usesObservation"], "true")
    }

    func testAppliesSelectedOption() throws {
        let manifest = try makeManifest(withFlavorYAML: Self.sceneYAML)
        let result = FlavorResolver.resolve(manifest: manifest, selections: ["stateStyle": "combine"])
        XCTAssertEqual(result.variables["stateStyle"], "combine")
        XCTAssertEqual(result.variables["usesObservation"], "false")
    }

    func testSelectionIsCaseInsensitive() throws {
        let manifest = try makeManifest(withFlavorYAML: Self.sceneYAML)
        let result = FlavorResolver.resolve(manifest: manifest, selections: ["STATESTYLE": "Combine"])
        XCTAssertEqual(result.variables["stateStyle"], "combine")
    }

    func testIgnoresUnknownOptionKeepsDefault() throws {
        let manifest = try makeManifest(withFlavorYAML: Self.sceneYAML)
        let result = FlavorResolver.resolve(manifest: manifest, selections: ["stateStyle": "nope"])
        // Unknown selection falls back to default behavior (first option)
        XCTAssertEqual(result.variables["stateStyle"], "observable")
    }

    func testUndeclaredKeysBecomeTemplateVariables() throws {
        let manifest = try makeManifest(withFlavorYAML: Self.sceneYAML)
        let result = FlavorResolver.resolve(manifest: manifest, selections: ["timeout": "60"])
        XCTAssertEqual(result.variables["timeout"], "60")
    }

    func testPreservesProvidedVariables() throws {
        let manifest = try makeManifest(withFlavorYAML: Self.sceneYAML)
        let result = FlavorResolver.resolve(
            manifest: manifest,
            selections: [:],
            variables: ["timeoutInterval": "45"]
        )
        XCTAssertEqual(result.variables["timeoutInterval"], "45")
        XCTAssertEqual(result.variables["stateStyle"], "observable")
    }

    func testAddsFlavorScopedOptionalDependencies() throws {
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
        XCTAssertTrue(result.selectedOptionalDeps.contains("storage"))

        let remoteResult = FlavorResolver.resolve(manifest: manifest, selections: ["strategy": "remote-only"])
        XCTAssertTrue(remoteResult.selectedOptionalDeps.isEmpty)
    }

    func testValidateSelectionReportsUnknownOption() throws {
        let manifest = try makeManifest(withFlavorYAML: Self.sceneYAML)
        XCTAssertNil(FlavorResolver.validateSelection(manifest: manifest, flavorKey: "stateStyle", selectedValue: "combine"))
        XCTAssertTrue(FlavorResolver.validateSelection(manifest: manifest, flavorKey: "stateStyle", selectedValue: "bad")?
            .contains("Unknown option 'bad'") == true)
    }
}
