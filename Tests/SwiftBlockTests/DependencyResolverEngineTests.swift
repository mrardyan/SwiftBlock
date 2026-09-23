import XCTest
@testable import SwiftBlockCore

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
        conflicts: [String] = []
    ) {
        let brickDir = "\(tempDirectory!)/Bricks/\(category)/\(name)"
        try? fileManager.createDirectory(atPath: brickDir, withIntermediateDirectories: true)

        var yml = "name: \(name)\ncategory: \(category)\ndefaultPath: App/Sources/\(name)\n"
        if !mandatory.isEmpty || !optional.isEmpty || !conflicts.isEmpty {
            yml += "dependencies:\n"
            if !mandatory.isEmpty {
                yml += "  mandatory:\n"
                for m in mandatory {
                    yml += "    - name: \(m)\n"
                }
            }
            if !optional.isEmpty {
                yml += "  optional:\n"
                for o in optional {
                    yml += "    - name: \(o)\n"
                }
            }
            if !conflicts.isEmpty {
                yml += "  conflicts:\n"
                for c in conflicts {
                    yml += "    - \(c)\n"
                }
            }
        }

        try? yml.write(toFile: "\(brickDir)/brick.yml", atomically: true, encoding: .utf8)
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
            guard case DependencyResolutionError.circularDependency(let chain) = error else {
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
        XCTAssertEqual(planWithout.executionOrder.map { $0.name }, ["base", "mainBrick"])

        // With selecting optional
        let planWith = try engine.resolve(
            targetBrickName: "mainBrick",
            baseTemplatePath: tempDirectory,
            projectRootPath: tempDirectory,
            selectedOptionalDeps: ["helperPlugin"]
        )
        XCTAssertEqual(planWith.executionOrder.map { $0.name }, ["base", "helperPlugin", "mainBrick"])
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
}
