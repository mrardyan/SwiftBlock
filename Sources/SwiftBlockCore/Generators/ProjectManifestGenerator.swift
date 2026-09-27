import Foundation

public enum ProjectGeneratorTool: String, Codable, CaseIterable {
    case tuist
    case xcodegen
    case spm

    public var title: String {
        switch self {
            case .tuist: "Tuist (Project.swift)"
            case .xcodegen: "XcodeGen (project.yml)"
            case .spm: "Swift Package Manager (Package.swift)"
        }
    }
}

public protocol ProjectManifestGenerator {
    func generateManifest(config: SwiftBlockConfig, projectPath: String) throws
    func addBrickDependency(name: String, type: Brick, config: SwiftBlockConfig, projectPath: String) throws
}

public class SPMManifestGenerator: ProjectManifestGenerator {
    public func generateManifest(config _: SwiftBlockConfig, projectPath _: String) throws {
        // SPM projects use Package.swift natively; no extra Tuist/XcodeGen file generation needed
    }

    public func addBrickDependency(name _: String, type _: Brick, config _: SwiftBlockConfig, projectPath _: String) throws {
        // SPM native targets are declared within Package.swift
    }
}

public class ProjectManifestGeneratorFactory {
    public static func createGenerator(for tool: ProjectGeneratorTool) -> ProjectManifestGenerator {
        switch tool {
            case .tuist:
                TuistManifestGenerator()
            case .xcodegen:
                XcodeGenManifestGenerator()
            case .spm:
                SPMManifestGenerator()
        }
    }
}
