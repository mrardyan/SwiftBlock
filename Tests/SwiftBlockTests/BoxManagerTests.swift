import Foundation
import Testing
@testable import SwiftBlockCore

struct BoxManagerTests {

    @Test func gitURLParsing() {
        let parsedSimple = BoxManager.parseGitURL("https://github.com/company/ios-bricks.git")
        #expect(parsedSimple.repoURL == "https://github.com/company/ios-bricks.git")
        #expect(parsedSimple.fragment == nil)

        let parsedWithFragment = BoxManager.parseGitURL("https://github.com/company/ios-bricks.git#bricks/network")
        #expect(parsedWithFragment.repoURL == "https://github.com/company/ios-bricks.git")
        #expect(parsedWithFragment.fragment == "bricks/network")
    }

    @Test func isGitURL() {
        #expect(BoxManager.isGitURL("https://github.com/company/ios-bricks.git"))
        #expect(BoxManager.isGitURL("http://gitlab.com/company/repo.git#bricks/storage"))
        #expect(BoxManager.isGitURL("git@github.com:company/repo.git"))
        #expect(!BoxManager.isGitURL("network"))
        #expect(!BoxManager.isGitURL("core/network"))
    }

    @Test func boxConfigPersistenceAndStoreDirectories() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("BoxStore_\(UUID().uuidString)", isDirectory: true).path
        defer {
            try? FileManager.default.removeItem(atPath: tempDir)
        }

        let manager = BoxManager(storeRootPath: tempDir)
        #expect(manager.boxesDirectory == "\(tempDir)/store/v1/boxes")
        #expect(manager.gitCacheDirectory == "\(tempDir)/store/v1/git")

        #expect(manager.listBoxes().isEmpty)
    }

    @Test func monorepoDiscovery() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("Monorepo_\(UUID().uuidString)", isDirectory: true).path
        defer {
            try? FileManager.default.removeItem(atPath: tempDir)
        }

        let brickDir1 = "\(tempDir)/bricks/network"
        let brickDir2 = "\(tempDir)/bricks/storage"
        try FileManager.default.createDirectory(atPath: brickDir1, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(atPath: brickDir2, withIntermediateDirectories: true)

        let manifest1 = """
        name: network
        instantiation: singleton
        description: Network Transport Brick
        """
        let manifest2 = """
        name: storage
        instantiation: singleton
        description: Storage Brick
        """

        try manifest1.write(toFile: "\(brickDir1)/brick.yml", atomically: true, encoding: .utf8)
        try manifest2.write(toFile: "\(brickDir2)/brick.yml", atomically: true, encoding: .utf8)

        let manager = BoxManager(storeRootPath: tempDir)
        let discovered = manager.discoverMonorepoBricks(at: tempDir)

        #expect(discovered.count == 2)
        #expect(discovered.map { $0.manifest.name }.contains("network"))
        #expect(discovered.map { $0.manifest.name }.contains("storage"))
    }

    @Test func boxNameSanitizationAndTraversalPrevention() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("BoxStoreSanitization_\(UUID().uuidString)", isDirectory: true).path
        defer {
            try? FileManager.default.removeItem(atPath: tempDir)
        }

        let manager = BoxManager(storeRootPath: tempDir)
        
        // Attempt removing with path traversal characters
        #expect(throws: Never.self) {
            try manager.removeBox(name: "../../evil_box")
        }

        // Attempt adding with empty name
        #expect(throws: BoxManagerError.self) {
            try manager.addBox(name: "   ", gitURL: "https://invalid-repo-url.git")
        }
    }

    @Test func invalidGitURLOrCloneFailure() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("BoxStoreCloneFail_\(UUID().uuidString)", isDirectory: true).path
        defer {
            try? FileManager.default.removeItem(atPath: tempDir)
        }

        let manager = BoxManager(storeRootPath: tempDir)
        
        #expect(throws: BoxManagerError.self) {
            try manager.addBox(name: "invalidbox", gitURL: "https://invalid-non-existent-domain-12345.com/repo.git")
        }
    }
}
