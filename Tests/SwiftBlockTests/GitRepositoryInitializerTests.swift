import Foundation
@testable import SwiftBlockCore
import XCTest

final class GitRepositoryInitializerTests: XCTestCase {
    func testInitializeGitRepo() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        let config = SwiftBlockConfig(
            projectName: "GitTestApp",
            bundlePrefix: "com.test",
            gitInit: true
        )

        let initializer = GitRepositoryInitializer()
        try initializer.initializeRepository(at: tempDir.path, config: config)

        let gitDir = tempDir.appendingPathComponent(".git")
        let gitignore = tempDir.appendingPathComponent(".gitignore")

        XCTAssertTrue(FileManager.default.fileExists(atPath: gitDir.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: gitignore.path))

        let gitignoreContent = try String(contentsOf: gitignore, encoding: .utf8)
        XCTAssertTrue(gitignoreContent.contains("DerivedData"))
        XCTAssertTrue(gitignoreContent.contains(".build/"))
    }
}
