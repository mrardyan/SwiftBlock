import Foundation

public class IDEConfigGenerator {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func generateVSCodeTasks(projectPath: String, config: SwiftBlockConfig) throws {
        let vscodeDir = "\(projectPath)/.vscode"
        try fileManager.createDirectory(atPath: vscodeDir, withIntermediateDirectories: true)

        let tasksPath = "\(vscodeDir)/tasks.json"

        let tasksJSONContent = """
        {
          "version": "2.0.0",
          "tasks": [
            {
              "label": "SwiftBlock: Snap Scene",
              "type": "shell",
              "command": "swiftblock snap scene ${input:sceneName}",
              "problemMatcher": [],
              "group": "build"
            },
            {
              "label": "SwiftBlock: Snap Core Block",
              "type": "shell",
              "command": "swiftblock snap storage ${input:coreBlockName}",
              "problemMatcher": [],
              "group": "build"
            },
            {
              "label": "SwiftBlock: Run Feature Kit",
              "type": "shell",
              "command": "swiftblock kit run clean-feature ${input:featureName}",
              "problemMatcher": [],
              "group": "build"
            },
            {
              "label": "SwiftBlock: Doctor Diagnostics",
              "type": "shell",
              "command": "swiftblock doctor",
              "problemMatcher": [],
              "group": "test"
            }
          ],
          "inputs": [
            {
              "id": "sceneName",
              "type": "promptString",
              "description": "Enter Scene Name (e.g. Profile, Home):"
            },
            {
              "id": "coreBlockName",
              "type": "promptString",
              "description": "Enter Core Block Name (e.g. Database, Network):"
            },
            {
              "id": "featureName",
              "type": "promptString",
              "description": "Enter Feature Module Name (e.g. Profile, Auth):"
            }
          ]
        }
        """

        let trimmed = tasksJSONContent.trimmingCharacters(in: .newlines) + "\n"
        try trimmed.write(toFile: tasksPath, atomically: true, encoding: .utf8)
    }

    public func updateMakefileShortcuts(projectPath: String) throws {
        let makefilePath = "\(projectPath)/Makefile"
        guard fileManager.fileExists(atPath: makefilePath),
              var content = try? String(contentsOfFile: makefilePath, encoding: .utf8) else {
            return
        }

        if !content.contains("snap-scene:") {
            let shortcuts = """

# SwiftBlock IDE & Developer Shortcuts
snap-scene:
	swiftblock snap scene $(NAME)

snap-core:
	swiftblock snap $(BLOCK) $(NAME)

kit-run:
	swiftblock kit run $(KIT) $(NAME)

doctor:
	swiftblock doctor
"""
            content += shortcuts
            try content.write(toFile: makefilePath, atomically: true, encoding: .utf8)
        }
    }

    public func setupAll(projectPath: String, config: SwiftBlockConfig) throws {
        try generateVSCodeTasks(projectPath: projectPath, config: config)
        try updateMakefileShortcuts(projectPath: projectPath)
    }
}
