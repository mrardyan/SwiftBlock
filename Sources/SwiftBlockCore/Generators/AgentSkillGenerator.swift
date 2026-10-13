import Foundation

public enum AgentTarget: String, CaseIterable {
    case all
    case antigravity
    case cursor
    case claude
    case copilot
}

public class AgentSkillGenerator {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// Generates agent guidelines and skills for specified targets
    @discardableResult
    public func generate(
        projectPath: String,
        targets: [AgentTarget] = [.all]
    ) throws -> [String] {
        var createdFiles: [String] = []
        let resolvedTargets: Set<AgentTarget> = if targets.contains(.all) {
            Set([.antigravity, .cursor, .claude, .copilot])
        } else {
            Set(targets)
        }

        if resolvedTargets.contains(.antigravity) {
            let skill = try generateAgentSkill(projectPath: projectPath)
            let root = try generateRootAgentDoc(projectPath: projectPath)
            createdFiles.append(contentsOf: [skill, root])
        }

        if resolvedTargets.contains(.cursor) {
            let cursor = try generateCursorRule(projectPath: projectPath)
            createdFiles.append(cursor)
        }

        if resolvedTargets.contains(.claude) {
            let claude = try generateClaudeDoc(projectPath: projectPath)
            createdFiles.append(claude)
        }

        if resolvedTargets.contains(.copilot) {
            let copilot = try generateCopilotDoc(projectPath: projectPath)
            createdFiles.append(copilot)
        }

        return createdFiles
    }

    /// Generates .agents/skills/swiftblock/SKILL.md, AGENTS.md, and optionally .cursor/rules/swiftblock.mdc
    @discardableResult
    public func generateAll(
        projectPath: String,
        includeCursorRule: Bool = true,
        includeRootAgentFile: Bool = true
    ) throws -> [String] {
        var targets: [AgentTarget] = [.claude, .copilot]
        if includeRootAgentFile {
            targets.append(.antigravity)
        }
        if includeCursorRule {
            targets.append(.cursor)
        }
        return try generate(projectPath: projectPath, targets: targets)
    }

    /// Generates workspace skill for Antigravity & Gemini agents (.agents/skills/swiftblock/SKILL.md)
    @discardableResult
    public func generateAgentSkill(projectPath: String) throws -> String {
        let skillDir = "\(projectPath)/.agents/skills/swiftblock"
        try fileManager.createDirectory(atPath: skillDir, withIntermediateDirectories: true)
        let skillFile = "\(skillDir)/SKILL.md"
        try AgentSkillTemplates.skillMarkdown.write(toFile: skillFile, atomically: true, encoding: .utf8)
        return skillFile
    }

    /// Generates universal root workspace instructions (AGENTS.md)
    @discardableResult
    public func generateRootAgentDoc(projectPath: String) throws -> String {
        let filePath = "\(projectPath)/AGENTS.md"
        try AgentSkillTemplates.rootAgentsMarkdown.write(toFile: filePath, atomically: true, encoding: .utf8)
        return filePath
    }

    /// Generates Cursor IDE rules (.cursor/rules/swiftblock.mdc)
    @discardableResult
    public func generateCursorRule(projectPath: String) throws -> String {
        let cursorRulesDir = "\(projectPath)/.cursor/rules"
        try fileManager.createDirectory(atPath: cursorRulesDir, withIntermediateDirectories: true)
        let filePath = "\(cursorRulesDir)/swiftblock.mdc"
        try AgentSkillTemplates.cursorRuleMarkdown.write(toFile: filePath, atomically: true, encoding: .utf8)
        return filePath
    }

    /// Generates Claude Code guidelines (CLAUDE.md)
    @discardableResult
    public func generateClaudeDoc(projectPath: String) throws -> String {
        let filePath = "\(projectPath)/CLAUDE.md"
        try AgentSkillTemplates.claudeMarkdown.write(toFile: filePath, atomically: true, encoding: .utf8)
        return filePath
    }

    /// Generates GitHub Copilot repository instructions (.github/copilot-instructions.md)
    @discardableResult
    public func generateCopilotDoc(projectPath: String) throws -> String {
        let githubDir = "\(projectPath)/.github"
        try fileManager.createDirectory(atPath: githubDir, withIntermediateDirectories: true)
        let filePath = "\(githubDir)/copilot-instructions.md"
        try AgentSkillTemplates.copilotMarkdown.write(toFile: filePath, atomically: true, encoding: .utf8)
        return filePath
    }

    public func buildSkillMarkdown() -> String {
        AgentSkillTemplates.skillMarkdown
    }

    public func buildRootAgentsMarkdown() -> String {
        AgentSkillTemplates.rootAgentsMarkdown
    }

    public func buildCursorRuleMarkdown() -> String {
        AgentSkillTemplates.cursorRuleMarkdown
    }

    public func buildClaudeMarkdown() -> String {
        AgentSkillTemplates.claudeMarkdown
    }

    public func buildCopilotMarkdown() -> String {
        AgentSkillTemplates.copilotMarkdown
    }
}
