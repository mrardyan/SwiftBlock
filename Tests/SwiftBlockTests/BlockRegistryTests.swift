import Foundation
import Testing
@testable import SwiftBlockCore

struct BlockRegistryTests {

    @Test func allBlocksNotEmpty() {
        #expect(!BlockRegistry.allBlocks.isEmpty)
        #expect(BlockRegistry.allBlocks.count == 16)
    }

    @Test func featureAndCoreBlocksCount() {
        #expect(BlockRegistry.featureBlocks.count == 9)
        #expect(BlockRegistry.coreBlocks.count == 7)
    }

    @Test func specForType() {
        let sceneSpec = BlockRegistry.spec(for: .scene)
        #expect(sceneSpec != nil)
        #expect(sceneSpec?.commandName == "scene")
        #expect(sceneSpec?.category == .feature)

        let storageSpec = BlockRegistry.spec(for: .storage)
        #expect(storageSpec != nil)
        #expect(storageSpec?.commandName == "storage")
        #expect(storageSpec?.category == .core)
    }

    @Test func specForCommand() {
        let mapperSpec = BlockRegistry.spec(forCommand: "mapper")
        #expect(mapperSpec != nil)
        #expect(mapperSpec?.type == .mapper)

        let authSpec = BlockRegistry.spec(forCommand: "AUTH")
        #expect(authSpec != nil)
        #expect(authSpec?.type == .auth)

        let invalidSpec = BlockRegistry.spec(forCommand: "nonexistent")
        #expect(invalidSpec == nil)
    }
}
