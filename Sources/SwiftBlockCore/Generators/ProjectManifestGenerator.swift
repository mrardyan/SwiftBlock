import Foundation

public enum ProjectGeneratorTool: String, Codable, CaseIterable {
    case tuist = "tuist"
    case xcodegen = "xcodegen"

    public var title: String {
        switch self {
        case .tuist: return "Tuist (Project.swift)"
        case .xcodegen: return "XcodeGen (project.yml)"
        }
    }
}

public protocol ProjectManifestGenerator {
    func generateManifest(config: SwiftBlockConfig, projectPath: String) throws
    func addBrickDependency(name: String, type: Brick, config: SwiftBlockConfig, projectPath: String) throws
}

public class ProjectManifestGeneratorFactory {
    public static func createGenerator(for tool: ProjectGeneratorTool) -> ProjectManifestGenerator {
        switch tool {
        case .tuist:
            return TuistManifestGenerator()
        case .xcodegen:
            return XcodeGenManifestGenerator()
        }
    }
}
