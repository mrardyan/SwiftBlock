import Foundation
@testable import SwiftBlockCore
import XCTest

final class AgentSkillGeneratorTests: XCTestCase {
    func testGenerateAllCreatesSkillAndAgentFiles() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let generator = AgentSkillGenerator()
        let created = try generator.generate(projectPath: tempDir, targets: [.all])

        let skillFile = "\(tempDir)/.agents/skills/swiftblock/SKILL.md"
        let rootAgentsFile = "\(tempDir)/AGENTS.md"
        let cursorRuleFile = "\(tempDir)/.cursor/rules/swiftblock.mdc"
        let claudeFile = "\(tempDir)/CLAUDE.md"
        let copilotFile = "\(tempDir)/.github/copilot-instructions.md"

        XCTAssertTrue(FileManager.default.fileExists(atPath: skillFile))
        XCTAssertTrue(FileManager.default.fileExists(atPath: rootAgentsFile))
        XCTAssertTrue(FileManager.default.fileExists(atPath: cursorRuleFile))
        XCTAssertTrue(FileManager.default.fileExists(atPath: claudeFile))
        XCTAssertTrue(FileManager.default.fileExists(atPath: copilotFile))
        XCTAssertEqual(created.count, 5)

        let skillContent = try String(contentsOfFile: skillFile, encoding: .utf8)
        XCTAssertTrue(skillContent.contains("name: swiftblock"))
        XCTAssertTrue(skillContent.contains("swiftblock snap scene <Name>"))
        XCTAssertTrue(skillContent.contains("swiftblock kit add clean-feature <Module>"))
        XCTAssertTrue(skillContent.contains("swiftblock doctor"))

        let agentsContent = try String(contentsOfFile: rootAgentsFile, encoding: .utf8)
        XCTAssertTrue(agentsContent.contains("SwiftBlock Project Guidelines for AI Agents"))
        XCTAssertTrue(agentsContent.contains("swiftblock snap"))

        let cursorContent = try String(contentsOfFile: cursorRuleFile, encoding: .utf8)
        XCTAssertTrue(cursorContent.contains("SwiftBlock Rules"))

        let claudeContent = try String(contentsOfFile: claudeFile, encoding: .utf8)
        XCTAssertTrue(claudeContent.contains("SwiftBlock Guidelines (Claude Code)"))

        let copilotContent = try String(contentsOfFile: copilotFile, encoding: .utf8)
        XCTAssertTrue(copilotContent.contains("SwiftBlock Instructions (GitHub Copilot)"))
    }

    func testGenerateSpecificTargetOnly() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tempDir) }

        let generator = AgentSkillGenerator()
        let created = try generator.generate(projectPath: tempDir, targets: [.claude])

        let claudeFile = "\(tempDir)/CLAUDE.md"
        let cursorFile = "\(tempDir)/.cursor/rules/swiftblock.mdc"

        XCTAssertTrue(FileManager.default.fileExists(atPath: claudeFile))
        XCTAssertFalse(FileManager.default.fileExists(atPath: cursorFile))
        XCTAssertEqual(created.count, 1)
    }
}
