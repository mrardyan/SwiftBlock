@testable import SwiftBlockCore
import XCTest

final class DependencyResolverEngineTests: XCTestCase {
    var tempDirectory: String!
    var fileManager: FileManager!

    override func setUp() {
        super.setUp()
        fileManager = FileManager.default
        tempDirectory = "\(NSTemporaryDirectory())SwiftBlock_DepResolver_\(UUID().uuidString)"
        try? fileManager.createDirectory(atPath: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let temp = tempDirectory {
            try? fileManager.removeItem(atPath: temp)
        }
        super.tearDown()
    }

    private func createMockBrick(
        name: String,
        category: String = "core",
        mandatory: [String] = [],
        optional: [String] = [],
        conflicts: [String] = [],
        defaultPath: String? = nil,
        instantiation: String = "generative",
        templateFiles: [String] = []
    ) {
        let brickDir = "\(tempDirectory!)/Bricks/\(category)/\(name)"
        try? fileManager.createDirectory(atPath: brickDir, withIntermediateDirectories: true)

        var yml = "name: \(name)\ncategory: \(category)\ninstantiation: \(instantiation)\ndefaultPath: \(defaultPath ?? "App/Sources/\(name)")\n"
        if !mandatory.isEmpty || !optional.isEmpty || !conflicts.isEmpty {
            yml += "dependencies:\n"
            if !mandatory.isEmpty {
                yml += "  mandatory:\n"
                for dep in mandatory {
                    yml += "    - name: \(dep)\n"
                }
            }
            if !optional.isEmpty {
                yml += "  optional:\n"
                for dep in optional {
                    yml += "    - name: \(dep)\n"
                }
            }
            if !conflicts.isEmpty {
                yml += "  conflicts:\n"
                for conf in conflicts {
                    yml += "    - \(conf)\n"
                }
            }
        }

        try? yml.write(toFile: "\(brickDir)/brick.yml", atomically: true, encoding: .utf8)

        for file in templateFiles {
            try? "// \(file)".write(toFile: "\(brickDir)/\(file)", atomically: true, encoding: .utf8)
        }
    }

    private func createInstalledFile(relativePath: String) {
        let fullPath = "\(tempDirectory!)/\(relativePath)"
        try? fileManager.createDirectory(atPath: (fullPath as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
        try? "// installed".write(toFile: fullPath, atomically: true, encoding: .utf8)
    }

    func testTopologicalOrderingForMandatoryDependencies() throws {
        // C has no deps
        createMockBrick(name: "c")
        // B requires C
        createMockBrick(name: "b", mandatory: ["c"])
        // A requires B
        createMockBrick(name: "a", mandatory: ["b"])

        let engine = DependencyResolverEngine()
        let plan = try engine.resolve(targetBrickName: "a", baseTemplatePath: tempDirectory, projectRootPath: tempDirectory)

        let names = plan.executionOrder.map { $0.name.lowercased() }
        XCTAssertEqual(names, ["c", "b", "a"])
    }

    func testCircularDependencyThrowsError() {
        createMockBrick(name: "nodeA", mandatory: ["nodeB"])
        createMockBrick(name: "nodeB", mandatory: ["nodeA"])

        let engine = DependencyResolverEngine()
        XCTAssertThrowsError(try engine.resolve(targetBrickName: "nodeA", baseTemplatePath: tempDirectory, projectRootPath: tempDirectory)) { error in
            guard case let DependencyResolutionError.circularDependency(chain) = error else {
                return XCTFail("Expected circularDependency error but got \(error)")
            }
            XCTAssertTrue(chain.contains("nodea"))
            XCTAssertTrue(chain.contains("nodeb"))
        }
    }

    func testOptionalDependenciesIncludedWhenSelected() throws {
        createMockBrick(name: "mainBrick", mandatory: ["base"], optional: ["helperPlugin"])
        createMockBrick(name: "base")
        createMockBrick(name: "helperPlugin")

        let engine = DependencyResolverEngine()

        // Without selecting optional
        let planWithout = try engine.resolve(targetBrickName: "mainBrick", baseTemplatePath: tempDirectory, projectRootPath: tempDirectory)
        XCTAssertEqual(planWithout.executionOrder.map(\.name), ["base", "mainBrick"])

        // With selecting optional
        let planWith = try engine.resolve(
            targetBrickName: "mainBrick",
            baseTemplatePath: tempDirectory,
            projectRootPath: tempDirectory,
            selectedOptionalDeps: ["helperPlugin"]
        )
        XCTAssertEqual(planWith.executionOrder.map(\.name), ["base", "helperPlugin", "mainBrick"])
    }

    func testConflictThrowsError() {
        createMockBrick(name: "brickX", mandatory: ["brickY"])
        createMockBrick(name: "brickY", conflicts: ["brickX"])

        let engine = DependencyResolverEngine()
        XCTAssertThrowsError(try engine.resolve(targetBrickName: "brickX", baseTemplatePath: tempDirectory, projectRootPath: tempDirectory)) { error in
            guard case DependencyResolutionError.conflictDetected = error else {
                return XCTFail("Expected conflictDetected error but got \(error)")
            }
        }
    }

    func testConflictAgainstAlreadyInstalledBrickThrowsError() {
        // brickX conflicts with brickZ; brickZ is already installed (skipped)
        createMockBrick(
            name: "brickX",
            conflicts: ["brickZ"],
            defaultPath: "App/Sources/Core/Protocols",
            instantiation: "singleton",
            templateFiles: ["__MODULE_NAME__.swift"]
        )
        createMockBrick(name: "brickZ", defaultPath: "App/Sources/Core/Protocols", instantiation: "singleton", templateFiles: ["__MODULE_NAME__.swift"])
        createInstalledFile(relativePath: "App/Sources/Core/Protocols/BrickZ.swift")

        let engine = DependencyResolverEngine()
        XCTAssertThrowsError(try engine.resolve(targetBrickName: "brickX", baseTemplatePath: tempDirectory, projectRootPath: tempDirectory)) { error in
            guard case DependencyResolutionError.conflictDetected = error else {
                return XCTFail("Expected conflictDetected error but got \(error)")
            }
        }
    }

    func testSharedDefaultPathIsNotFalselySkipped() throws {
        // Two protocol bricks share the same defaultPath directory.
        // Only one of them has its rendered file installed — the other must NOT be skipped.
        createMockBrick(name: "alphaProtocol", defaultPath: "App/Sources/Core/Protocols", instantiation: "singleton", templateFiles: ["__MODULE_NAME__.swift"])
        createMockBrick(name: "betaProtocol", defaultPath: "App/Sources/Core/Protocols", instantiation: "singleton", templateFiles: ["__MODULE_NAME__.swift"])
        createMockBrick(name: "consumer", mandatory: ["alphaProtocol", "betaProtocol"])

        createInstalledFile(relativePath: "App/Sources/Core/Protocols/AlphaProtocol.swift")

        let engine = DependencyResolverEngine()
        let plan = try engine.resolve(targetBrickName: "consumer", baseTemplatePath: tempDirectory, projectRootPath: tempDirectory)

        let executed = plan.executionOrder.map { $0.name.lowercased() }
        let skipped = plan.skippedAlreadyInstalled.map { $0.lowercased() }
        XCTAssertTrue(
            executed.contains("betaprotocol"),
            "BetaProtocol shares the directory but its file is absent — must be snapped, got executed=\(executed) skipped=\(skipped)"
        )
        XCTAssertTrue(skipped.contains("alphaprotocol"), "AlphaProtocol's file exists — should be skipped, got skipped=\(skipped)")
    }

    func testFileBasedIdempotencyUsesRenderedFileName() throws {
        // defaultPath directory exists but the rendered output file does not → must snap.
        createMockBrick(name: "renderTarget", defaultPath: "App/Sources/Core/Protocols", instantiation: "singleton", templateFiles: ["__MODULE_NAME__.swift"])
        try? fileManager.createDirectory(atPath: "\(tempDirectory!)/App/Sources/Core/Protocols", withIntermediateDirectories: true)

        let engine = DependencyResolverEngine()
        let plan = try engine.resolve(targetBrickName: "renderTarget", baseTemplatePath: tempDirectory, projectRootPath: tempDirectory)

        XCTAssertEqual(plan.executionOrder.map(\.name), ["renderTarget"])
        XCTAssertTrue(plan.skippedAlreadyInstalled.isEmpty)
    }

    func testFlavorOptionParsesVariablesDependenciesAndFiles() {
        let brickDir = "\(tempDirectory!)/Bricks/core/flavoredBrick"
        try? fileManager.createDirectory(atPath: brickDir, withIntermediateDirectories: true)

        let yml = """
        name: flavoredBrick
        category: core
        defaultPath: App/Sources/Flavored
        flavors:
          transport:
            prompt: "Select transport style"
            default: sync
            options:
              - id: sync
                title: Synchronous
                variables:
                  asyncStyle: false
              - id: async-await
                title: Async Await
                variables:
                  asyncStyle: true
                dependencies:
                  optional:
                    - name: exponentialbackoff
                      description: "Auto-retry decorator"
                files:
                  - source: AsyncVariant.swift
                    destination: App/Sources/Flavored/AsyncVariant.swift
        """
        try? yml.write(toFile: "\(brickDir)/brick.yml", atomically: true, encoding: .utf8)

        let manifest = BrickManifest.load(fromPath: brickDir)
        XCTAssertNotNil(manifest)
        guard let flavor = manifest?.flavors["transport"] else {
            return XCTFail("Expected 'transport' flavor to be parsed")
        }
        XCTAssertEqual(flavor.prompt, "Select transport style")
        XCTAssertEqual(flavor.defaultValue, "sync")
        XCTAssertEqual(flavor.options.count, 2)

        guard let asyncOption = flavor.options.first(where: { $0.id == "async-await" }) else {
            return XCTFail("Expected async-await flavor option")
        }
        XCTAssertEqual(asyncOption.variables["asyncStyle"], "true")
        XCTAssertEqual(asyncOption.dependencies?.optional.first?.name, "exponentialbackoff")
        XCTAssertEqual(asyncOption.files.first?.destination, "App/Sources/Flavored/AsyncVariant.swift")
    }
}
