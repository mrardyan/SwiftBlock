import Foundation
@testable import SwiftBlockCore
import XCTest

final class BrickRegistryTests: XCTestCase {
    func testAllBricksNotEmpty() {
        XCTAssertFalse(BrickRegistry.allBricks.isEmpty)
        // Curated bricks are always present
        XCTAssertGreaterThanOrEqual(BrickRegistry.allBricks.count, 23)
    }

    func testFeatureAndCoreBlocksCount() {
        // All curated feature bricks must be present
        XCTAssertGreaterThanOrEqual(BrickRegistry.featureBricks.count, 9)
        XCTAssertGreaterThanOrEqual(BrickRegistry.coreBricks.count, 14)
        // Auto-discovered bricks are categorized (e.g. value types land in utils, not feature)
        let moneySpec = BrickRegistry.spec(forCommand: "money")
        XCTAssertNotEqual(moneySpec, nil)
        XCTAssertEqual(moneySpec?.category, .utils)
    }

    func testSpecForType() {
        let sceneSpec = BrickRegistry.spec(for: .scene)
        XCTAssertNotEqual(sceneSpec, nil)
        XCTAssertEqual(sceneSpec?.commandName, "scene")
        XCTAssertEqual(sceneSpec?.category, .feature)

        let storageSpec = BrickRegistry.spec(for: .storage)
        XCTAssertNotEqual(storageSpec, nil)
        XCTAssertEqual(storageSpec?.commandName, "storage")
        XCTAssertEqual(storageSpec?.category, .core)
    }

    func testSpecForCommand() {
        let mapperSpec = BrickRegistry.spec(forCommand: "mapper")
        XCTAssertNotEqual(mapperSpec, nil)
        XCTAssertEqual(mapperSpec?.type, .mapper)

        let authSpec = BrickRegistry.spec(forCommand: "AUTH")
        XCTAssertNotEqual(authSpec, nil)
        XCTAssertEqual(authSpec?.type, .auth)

        // Category namespacing tests (core/network, feature/scene, core.storage)
        let coreNetworkSpec = BrickRegistry.spec(forCommand: "core/network")
        XCTAssertNotEqual(coreNetworkSpec, nil)
        XCTAssertEqual(coreNetworkSpec?.type, .network)

        let featureSceneSpec = BrickRegistry.spec(forCommand: "feature/scene")
        XCTAssertNotEqual(featureSceneSpec, nil)
        XCTAssertEqual(featureSceneSpec?.type, .scene)

        let coreStorageSpec = BrickRegistry.spec(forCommand: "core.storage")
        XCTAssertNotEqual(coreStorageSpec, nil)
        XCTAssertEqual(coreStorageSpec?.type, .storage)

        let slashBrick: Brick = "core/network"
        XCTAssertEqual(slashBrick.rawValue, "network")

        let dotBrick: Brick = "feature/scene"
        XCTAssertEqual(dotBrick.rawValue, "scene")

        let invalidSpec = BrickRegistry.spec(forCommand: "nonexistent")
        XCTAssertEqual(invalidSpec, nil)
    }

    func testBrickCategoryAndNamespaces() {
        let sceneBrick = Brick.Feature.scene
        XCTAssertEqual(sceneBrick.rawValue, "scene")
        XCTAssertEqual(sceneBrick.category, Brick.Category.feature)

        let storageBrick = Brick.Core.storage
        XCTAssertEqual(storageBrick.rawValue, "storage")
        XCTAssertEqual(storageBrick.category, Brick.Category.core)

        let featureCat: Brick.Category = .feature
        XCTAssertFalse(featureCat.isSingleton)

        let coreCat: Brick.Category = .core
        XCTAssertTrue(coreCat.isSingleton)

        let customBrick: Brick = "custombrick"
        XCTAssertEqual(customBrick.description, "custombrick")
    }
}
