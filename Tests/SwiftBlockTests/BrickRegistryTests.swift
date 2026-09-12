import Foundation
import Testing
@testable import SwiftBlockCore

struct BrickRegistryTests {

    @Test func allBricksNotEmpty() {
        #expect(!BrickRegistry.allBricks.isEmpty)
        #expect(BrickRegistry.allBricks.count == 23)
    }

    @Test func featureAndCoreBlocksCount() {
        #expect(BrickRegistry.featureBricks.count == 9)
        #expect(BrickRegistry.coreBricks.count == 14)
    }

    @Test func specForType() {
        let sceneSpec = BrickRegistry.spec(for: .scene)
        #expect(sceneSpec != nil)
        #expect(sceneSpec?.commandName == "scene")
        #expect(sceneSpec?.category == .feature)

        let storageSpec = BrickRegistry.spec(for: .storage)
        #expect(storageSpec != nil)
        #expect(storageSpec?.commandName == "storage")
        #expect(storageSpec?.category == .core)
    }

    @Test func specForCommand() {
        let mapperSpec = BrickRegistry.spec(forCommand: "mapper")
        #expect(mapperSpec != nil)
        #expect(mapperSpec?.type == .mapper)

        let authSpec = BrickRegistry.spec(forCommand: "AUTH")
        #expect(authSpec != nil)
        #expect(authSpec?.type == .auth)

        // Category namespacing tests (core/network, feature/scene, core.storage)
        let coreNetworkSpec = BrickRegistry.spec(forCommand: "core/network")
        #expect(coreNetworkSpec != nil)
        #expect(coreNetworkSpec?.type == .network)

        let featureSceneSpec = BrickRegistry.spec(forCommand: "feature/scene")
        #expect(featureSceneSpec != nil)
        #expect(featureSceneSpec?.type == .scene)

        let coreStorageSpec = BrickRegistry.spec(forCommand: "core.storage")
        #expect(coreStorageSpec != nil)
        #expect(coreStorageSpec?.type == .storage)

        let slashBrick: Brick = "core/network"
        #expect(slashBrick.rawValue == "network")

        let dotBrick: Brick = "feature/scene"
        #expect(dotBrick.rawValue == "scene")

        let invalidSpec = BrickRegistry.spec(forCommand: "nonexistent")
        #expect(invalidSpec == nil)
    }

    @Test func testBrickCategoryAndNamespaces() {
        let sceneBrick: Brick = Brick.Feature.scene
        #expect(sceneBrick.rawValue == "scene")
        #expect(sceneBrick.category == Brick.Category.feature)

        let storageBrick: Brick = Brick.Core.storage
        #expect(storageBrick.rawValue == "storage")
        #expect(storageBrick.category == Brick.Category.core)

        let featureCat: Brick.Category = .feature
        #expect(!featureCat.isSingleton)

        let coreCat: Brick.Category = .core
        #expect(coreCat.isSingleton)

        let customBrick: Brick = "custombrick"
        #expect(customBrick.description == "custombrick")
    }
}
