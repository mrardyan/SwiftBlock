import Foundation

public enum ProjectGeneratorTool: String, Codable, CaseIterable {
    case tuist = "tuist"
    case xcodegen = "xcodegen"
    case spm = "spm"

    public var title: String {
        switch self {
        case .tuist: return "Tuist (Project.swift)"
        case .xcodegen: return "XcodeGen (project.yml)"
        case .spm: return "Swift Package Manager (Package.swift)"
        }
    }
}

public protocol ProjectManifestGenerator {
    func generateManifest(config: SwiftBlockConfig, projectPath: String) throws
    func addBrickDependency(name: String, type: Brick, config: SwiftBlockConfig, projectPath: String) throws
}

public class SPMManifestGenerator: ProjectManifestGenerator {
    public func generateManifest(config: SwiftBlockConfig, projectPath: String) throws {
        // SPM projects use Package.swift natively; no extra Tuist/XcodeGen file generation needed
    }

    public func addBrickDependency(name: String, type: Brick, config: SwiftBlockConfig, projectPath: String) throws {
        // SPM native targets are declared within Package.swift
    }
}

public class ProjectManifestGeneratorFactory {
    public static func createGenerator(for tool: ProjectGeneratorTool) -> ProjectManifestGenerator {
        switch tool {
        case .tuist:
            return TuistManifestGenerator()
        case .xcodegen:
            return XcodeGenManifestGenerator()
        case .spm:
            return SPMManifestGenerator()
        }
    }
}
