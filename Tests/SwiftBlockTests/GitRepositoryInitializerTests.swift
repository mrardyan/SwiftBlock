import Foundation
import Testing
@testable import SwiftBlockCore

struct GitRepositoryInitializerTests {

    @Test func initializeGitRepo() throws {
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

        #expect(FileManager.default.fileExists(atPath: gitDir.path))
        #expect(FileManager.default.fileExists(atPath: gitignore.path))

        let gitignoreContent = try String(contentsOf: gitignore, encoding: .utf8)
        #expect(gitignoreContent.contains("DerivedData"))
        #expect(gitignoreContent.contains(".build/"))
    }
}
