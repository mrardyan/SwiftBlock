import Foundation
@testable import SwiftBlockCore
import XCTest

final class BoxManagerTests: XCTestCase {
    func testGitURLParsing() {
        let parsedSimple = BoxManager.parseGitURL("https://github.com/company/ios-bricks.git")
        XCTAssertEqual(parsedSimple.repoURL, "https://github.com/company/ios-bricks.git")
        XCTAssertEqual(parsedSimple.fragment, nil)

        let parsedWithFragment = BoxManager.parseGitURL("https://github.com/company/ios-bricks.git#bricks/network")
        XCTAssertEqual(parsedWithFragment.repoURL, "https://github.com/company/ios-bricks.git")
        XCTAssertEqual(parsedWithFragment.fragment, "bricks/network")
    }

    func testIsGitURL() {
        XCTAssertTrue(BoxManager.isGitURL("https://github.com/company/ios-bricks.git"))
        XCTAssertTrue(BoxManager.isGitURL("http://gitlab.com/company/repo.git#bricks/storage"))
        XCTAssertTrue(BoxManager.isGitURL("git@github.com:company/repo.git"))
        XCTAssertFalse(BoxManager.isGitURL("network"))
        XCTAssertFalse(BoxManager.isGitURL("core/network"))
    }

    func testBoxConfigPersistenceAndStoreDirectories() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("BoxStore_\(UUID().uuidString)", isDirectory: true).path
        defer {
            try? FileManager.default.removeItem(atPath: tempDir)
        }

        let manager = BoxManager(storeRootPath: tempDir)
        XCTAssertEqual(manager.boxesDirectory, "\(tempDir)/store/v1/boxes")
        XCTAssertEqual(manager.gitCacheDirectory, "\(tempDir)/store/v1/git")

        XCTAssertTrue(manager.listBoxes().isEmpty)
    }

    func testMonorepoDiscovery() throws {
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

        XCTAssertEqual(discovered.count, 2)
        XCTAssertTrue(discovered.map(\.manifest.name).contains("network"))
        XCTAssertTrue(discovered.map(\.manifest.name).contains("storage"))
    }

    func testBoxNameSanitizationAndTraversalPrevention() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("BoxStoreSanitization_\(UUID().uuidString)", isDirectory: true).path
        defer {
            try? FileManager.default.removeItem(atPath: tempDir)
        }

        let manager = BoxManager(storeRootPath: tempDir)

        // Attempt removing with path traversal characters
        XCTAssertNoThrow(try manager.removeBox(name: "../../evil_box"))

        // Attempt adding with empty name
        XCTAssertThrowsError(try manager.addBox(name: "   ", gitURL: "https://invalid-repo-url.git"))
    }

    func testInvalidGitURLOrCloneFailure() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("BoxStoreCloneFail_\(UUID().uuidString)", isDirectory: true).path
        defer {
            try? FileManager.default.removeItem(atPath: tempDir)
        }

        let manager = BoxManager(storeRootPath: tempDir)

        XCTAssertThrowsError(try manager.addBox(name: "invalidbox", gitURL: "https://invalid-non-existent-domain-12345.com/repo.git"))
    }
}
