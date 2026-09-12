import Foundation
import Testing
@testable import SwiftBlockCore

struct BrickRegistryTests {

    @Test func allBricksNotEmpty() {
        #expect(!BrickRegistry.allBricks.isEmpty)
        #expect(BrickRegistry.allBricks.count == 16)
    }

    @Test func featureAndCoreBlocksCount() {
        #expect(BrickRegistry.featureBricks.count == 9)
        #expect(BrickRegistry.coreBricks.count == 7)
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
