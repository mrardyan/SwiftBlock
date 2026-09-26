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
    public let autoWire: Bool

    public static func == (lhs: ResolvedBrickNode, rhs: ResolvedBrickNode) -> Bool {
        lhs.name.lowercased() == rhs.name.lowercased() &&
        lhs.templatePath == rhs.templatePath &&
        lhs.isMandatory == rhs.isMandatory &&
        lhs.requiredBy == rhs.requiredBy &&
        lhs.autoWire == rhs.autoWire
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
            autoWire: false,
            selectedOptionalDeps: selectedOptionalDeps,
            includeMandatory: includeMandatory,
            visited: &visited,
            visitingStack: &visitingStack,
            executionList: &executionList,
            skipped: &skipped
        )

        // Conflict check: against the execution list AND bricks already installed in the project
        let installedNames = Set(skipped.map { $0.lowercased() })
        for node in executionList {
            for conflict in node.manifest.dependencies.conflicts {
                let confLower = conflict.lowercased()
                let inPlan = executionList.contains { $0.name.lowercased() == confLower }
                let inProject = installedNames.contains(confLower) || isBrickInstalled(conflict, in: baseTemplatePath, projectRootPath: projectRootPath)
                if inPlan || inProject {
                    throw DependencyResolutionError.conflictDetected(brick: node.name, conflictsWith: conflict)
                }
            }
        }

        return DependencyResolutionPlan(executionOrder: executionList, skippedAlreadyInstalled: skipped)
    }

    /// Resolves a conflicting brick's manifest and checks whether its rendered output is installed.
    private func isBrickInstalled(_ name: String, in baseTemplatePath: String, projectRootPath: String) -> Bool {
        guard let path = discoveryEngine.resolveBrickPath(named: name, in: baseTemplatePath),
              let manifest = BrickManifest.load(fromPath: path) else {
            return false
        }
        return isAlreadyInstalled(manifest: manifest, templatePath: path, in: projectRootPath)
    }

    private func resolveNode(
        manifest: BrickManifest,
        templatePath: String,
        baseTemplatePath: String,
        projectRootPath: String,
        requiredBy: String?,
        isMandatory: Bool,
        autoWire: Bool,
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
                    autoWire: dep.autoWire,
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
                    autoWire: opt.autoWire,
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
            requiredBy: requiredBy,
            autoWire: autoWire
        )
        visited[nodeName] = node

        // Check if already installed in project (idempotency check)
        if isAlreadyInstalled(manifest: manifest, templatePath: templatePath, in: projectRootPath) {
            skipped.append(manifest.name)
        } else {
            executionList.append(node)
        }
    }

    /// Determines whether a brick has already been snapped into the project by checking the
    /// existence of the rendered template output file(s) — not just the containing directory,
    /// so that sibling bricks sharing a common `defaultPath` (e.g. all protocol bricks living
    /// in `App/Sources/Core/Protocols`) are not falsely treated as installed.
    private func isAlreadyInstalled(manifest: BrickManifest, templatePath: String, in projectRootPath: String) -> Bool {
        guard !manifest.defaultPath.isEmpty else { return false }

        let baseDir = "\(projectRootPath)/\(manifest.defaultPath)"
        guard fileManager.fileExists(atPath: baseDir) else { return false }

        let moduleName = manifest.instantiation == .generative ? "Main" : manifest.defaultInstanceName

        // Enumerate template files (skip metadata) to derive concrete output file names.
        guard let items = try? fileManager.contentsOfDirectory(atPath: templatePath) else {
            return fileManager.fileExists(atPath: baseDir)
        }

        let sourceFiles = items.filter { item in
            let lower = item.lowercased()
            return !lower.hasSuffix("brick.yml") &&
                   !lower.hasSuffix("brick.yaml") &&
                   lower != "block.json"
        }

        for item in sourceFiles {
            let rendered = BrickDiscoveryEngine.evaluateTokens(
                in: item,
                moduleName: moduleName,
                blockName: manifest.name.lowercased()
            )
            let fullPath = "\(baseDir)/\(rendered)"
            if fileManager.fileExists(atPath: fullPath) {
                return true
            }
        }
        return false
    }
}
