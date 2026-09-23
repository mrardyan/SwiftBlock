import Foundation

public enum DependencyResolutionError: Error, LocalizedError, Equatable {
    case circularDependency(chain: [String])
    case dependencyNotFound(brick: String, requiredBy: String)
    case conflictDetected(brick: String, conflictsWith: String)

    public var errorDescription: String? {
        switch self {
        case .circularDependency(let chain):
            return "Circular dependency detected: \(chain.joined(separator: " -> "))"
        case .dependencyNotFound(let brick, let requiredBy):
            return "Required dependency '\(brick)' (by '\(requiredBy)') was not found in registry or local bricks."
        case .conflictDetected(let brick, let conflictsWith):
            return "Conflict detected: Brick '\(brick)' cannot be installed alongside '\(conflictsWith)'."
        }
    }
}

public struct ResolvedBrickNode: Equatable {
    public let name: String
    public let templatePath: String
    public let manifest: BrickManifest
    public let isMandatory: Bool
    public let requiredBy: String?

    public static func == (lhs: ResolvedBrickNode, rhs: ResolvedBrickNode) -> Bool {
        lhs.name.lowercased() == rhs.name.lowercased() &&
        lhs.templatePath == rhs.templatePath &&
        lhs.isMandatory == rhs.isMandatory &&
        lhs.requiredBy == rhs.requiredBy
    }
}

public struct DependencyResolutionPlan: Equatable {
    public let executionOrder: [ResolvedBrickNode]
    public let skippedAlreadyInstalled: [String]
}

public final class DependencyResolverEngine {
    private let fileManager: FileManager
    private let discoveryEngine: BrickDiscoveryEngine

    public init(fileManager: FileManager = .default, discoveryEngine: BrickDiscoveryEngine = BrickDiscoveryEngine()) {
        self.fileManager = fileManager
        self.discoveryEngine = discoveryEngine
    }

    /// Resolves the full dependency plan (topologically sorted) for a target brick.
    /// - Parameters:
    ///   - targetBrickName: Name of the primary brick to snap.
    ///   - baseTemplatePath: Path to search for templates.
    ///   - projectRootPath: Root path of the current project to check installed status.
    ///   - selectedOptionalDeps: Names of optional dependencies the user explicitly selected.
    ///   - includeMandatory: Whether to resolve mandatory dependencies (default: true).
    public func resolve(
        targetBrickName: String,
        baseTemplatePath: String,
        projectRootPath: String = FileManager.default.currentDirectoryPath,
        selectedOptionalDeps: Set<String> = [],
        includeMandatory: Bool = true
    ) throws -> DependencyResolutionPlan {
        guard let targetPath = discoveryEngine.resolveBrickPath(named: targetBrickName, in: baseTemplatePath),
              let targetManifest = BrickManifest.load(fromPath: targetPath) else {
            throw DependencyResolutionError.dependencyNotFound(brick: targetBrickName, requiredBy: "CLI")
        }

        var visited: [String: ResolvedBrickNode] = [:]
        var visitingStack: [String] = []
        var executionList: [ResolvedBrickNode] = []
        var skipped: [String] = []

        try resolveNode(
            manifest: targetManifest,
            templatePath: targetPath,
            baseTemplatePath: baseTemplatePath,
            projectRootPath: projectRootPath,
            requiredBy: nil,
            isMandatory: true,
            selectedOptionalDeps: selectedOptionalDeps,
            includeMandatory: includeMandatory,
            visited: &visited,
            visitingStack: &visitingStack,
            executionList: &executionList,
            skipped: &skipped
        )

        // Conflict check across execution list
        for node in executionList {
            for conflict in node.manifest.dependencies.conflicts {
                let confLower = conflict.lowercased()
                if executionList.contains(where: { $0.name.lowercased() == confLower }) {
                    throw DependencyResolutionError.conflictDetected(brick: node.name, conflictsWith: conflict)
                }
            }
        }

        return DependencyResolutionPlan(executionOrder: executionList, skippedAlreadyInstalled: skipped)
    }

    private func resolveNode(
        manifest: BrickManifest,
        templatePath: String,
        baseTemplatePath: String,
        projectRootPath: String,
        requiredBy: String?,
        isMandatory: Bool,
        selectedOptionalDeps: Set<String>,
        includeMandatory: Bool,
        visited: inout [String: ResolvedBrickNode],
        visitingStack: inout [String],
        executionList: inout [ResolvedBrickNode],
        skipped: inout [String]
    ) throws {
        let nodeName = manifest.name.lowercased()

        if visitingStack.contains(nodeName) {
            let chain = visitingStack + [nodeName]
            throw DependencyResolutionError.circularDependency(chain: chain)
        }

        if visited[nodeName] != nil {
            return
        }

        visitingStack.append(nodeName)

        // 1. Process Mandatory Dependencies first (if enabled)
        if includeMandatory {
            for dep in manifest.dependencies.mandatory {
                let depName = dep.name.lowercased()
                guard let depPath = discoveryEngine.resolveBrickPath(named: depName, in: baseTemplatePath),
                      let depManifest = BrickManifest.load(fromPath: depPath) else {
                    throw DependencyResolutionError.dependencyNotFound(brick: dep.name, requiredBy: manifest.name)
                }

                try resolveNode(
                    manifest: depManifest,
                    templatePath: depPath,
                    baseTemplatePath: baseTemplatePath,
                    projectRootPath: projectRootPath,
                    requiredBy: manifest.name,
                    isMandatory: true,
                    selectedOptionalDeps: selectedOptionalDeps,
                    includeMandatory: includeMandatory,
                    visited: &visited,
                    visitingStack: &visitingStack,
                    executionList: &executionList,
                    skipped: &skipped
                )
            }
        }

        // 2. Process Selected Optional Dependencies
        for opt in manifest.dependencies.optional {
            let optName = opt.name.lowercased()
            if selectedOptionalDeps.contains(optName) || selectedOptionalDeps.contains(opt.name) {
                guard let optPath = discoveryEngine.resolveBrickPath(named: optName, in: baseTemplatePath),
                      let optManifest = BrickManifest.load(fromPath: optPath) else {
                    continue
                }

                try resolveNode(
                    manifest: optManifest,
                    templatePath: optPath,
                    baseTemplatePath: baseTemplatePath,
                    projectRootPath: projectRootPath,
                    requiredBy: manifest.name,
                    isMandatory: false,
                    selectedOptionalDeps: selectedOptionalDeps,
                    includeMandatory: includeMandatory,
                    visited: &visited,
                    visitingStack: &visitingStack,
                    executionList: &executionList,
                    skipped: &skipped
                )
            }
        }

        visitingStack.removeLast()

        let node = ResolvedBrickNode(
            name: manifest.name,
            templatePath: templatePath,
            manifest: manifest,
            isMandatory: isMandatory,
            requiredBy: requiredBy
        )
        visited[nodeName] = node

        // Check if already installed in project (idempotency check)
        if isAlreadyInstalled(manifest: manifest, in: projectRootPath) {
            skipped.append(manifest.name)
        } else {
            executionList.append(node)
        }
    }

    private func isAlreadyInstalled(manifest: BrickManifest, in projectRootPath: String) -> Bool {
        guard !manifest.defaultPath.isEmpty else { return false }
        let evaluated = manifest.defaultPath.replacingOccurrences(of: "{module}", with: manifest.name.lowercased())
        let fullPath = "\(projectRootPath)/\(evaluated)"
        return fileManager.fileExists(atPath: fullPath)
    }
}
