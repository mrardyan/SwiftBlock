import Foundation

public struct InjectionSpec {
    public let target: String
    public let marker: String?
    public let scope: String?
    public let content: String
    public let condition: String?

    public init(target: String, marker: String? = nil, scope: String? = nil, content: String, condition: String? = nil) {
        self.target = target
        self.marker = marker
        self.scope = scope
        self.content = content
        self.condition = condition
    }
}

public struct CodeInjector {
    public static func inject(
        spec: InjectionSpec,
        variables: [String: String] = [:],
        projectName: String = "",
        moduleName: String? = nil,
        projectRootPath: String = FileManager.default.currentDirectoryPath,
        config: SwiftBlockConfig? = nil,
        isDryRun: Bool = false
    ) throws -> Bool {
        let resolvedTargetPath = TemplateRenderer.renderPath(
            pathTemplate: spec.target,
            variables: variables,
            moduleName: moduleName ?? "",
            blockName: "",
            config: config
        )

        let absoluteTargetPath = (resolvedTargetPath as NSString).isAbsolutePath
            ? (resolvedTargetPath as NSString).standardizingPath
            : ("\(projectRootPath)/\(resolvedTargetPath)" as NSString).standardizingPath
        let standardizedRoot = (projectRootPath as NSString).standardizingPath

        guard absoluteTargetPath.hasPrefix(standardizedRoot) else {
            print("⚠️ Path traversal blocked: Target path '\(absoluteTargetPath)' is outside project root '\(standardizedRoot)'")
            return false
        }

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: absoluteTargetPath) else {
            print("⚠️ Target file for code injection not found at: \(absoluteTargetPath)")
            return false
        }

        guard let existingContent = try? String(contentsOfFile: absoluteTargetPath, encoding: .utf8) else {
            return false
        }

        let renderedSnippet = TemplateRenderer.render(
            template: spec.content,
            variables: variables,
            config: config,
            moduleName: moduleName ?? "",
            projectName: projectName
        ).trimmingCharacters(in: .whitespacesAndNewlines)

        if renderedSnippet.isEmpty {
            return false
        }

        // Prevent duplicate injections
        if existingContent.contains(renderedSnippet) {
            print("ℹ️ Snippet already present in \(resolvedTargetPath). Skipping injection.")
            return false
        }

        if isDryRun {
            print("🔍 [DRY RUN] Would inject snippet into \(resolvedTargetPath):")
            print("🔍 [DRY RUN] \(renderedSnippet)")
            return true
        }

        var lines = existingContent.components(separatedBy: "\n")
        var injected = false

        // 1. Structural Scope Injection (Method/Container body matching)
        if let scope = spec.scope, !scope.isEmpty {
            let renderedScope = TemplateRenderer.render(
                template: scope,
                variables: variables,
                config: config,
                moduleName: moduleName ?? "",
                projectName: projectName
            )

            if let scopeIndex = lines.firstIndex(where: { $0.contains(renderedScope) }) {
                // Find matching closing brace for this method/container
                var braceCount = 0
                var foundOpenBrace = false
                var closingBraceIndex: Int?

                for i in scopeIndex..<lines.count {
                    let line = lines[i]
                    for char in line {
                        if char == "{" {
                            braceCount += 1
                            foundOpenBrace = true
                        } else if char == "}" {
                            braceCount -= 1
                        }
                    }
                    if foundOpenBrace && braceCount == 0 {
                        closingBraceIndex = i
                        break
                    }
                }

                if let targetIndex = closingBraceIndex {
                    let indent = "        "
                    lines.insert(indent + renderedSnippet, at: targetIndex)
                    injected = true
                }
            }
        }

        // 2. Marker-based Injection
        if !injected, let marker = spec.marker, !marker.isEmpty {
            let renderedMarker = TemplateRenderer.render(
                template: marker,
                variables: variables,
                config: config,
                moduleName: moduleName ?? "",
                projectName: projectName
            )

            if let markerIndex = lines.firstIndex(where: { $0.contains(renderedMarker) }) {
                lines.insert("    " + renderedSnippet, at: markerIndex + 1)
                injected = true
            }
        }

        // 3. Fallback: Append before last closing brace or at end of file
        if !injected {
            if let lastBraceIndex = lines.rIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "}" }) {
                lines.insert("    " + renderedSnippet, at: lastBraceIndex)
                injected = true
            } else {
                lines.append(renderedSnippet)
                injected = true
            }
        }

        let newContent = lines.joined(separator: "\n")
        try newContent.write(toFile: absoluteTargetPath, atomically: true, encoding: .utf8)
        print("✔ Code injected into \(resolvedTargetPath)")
        return true
    }

    public static func injectAll(
        specs: [InjectionSpec],
        variables: [String: String] = [:],
        projectName: String = "",
        moduleName: String? = nil,
        projectRootPath: String = FileManager.default.currentDirectoryPath,
        config: SwiftBlockConfig? = nil,
        isDryRun: Bool = false
    ) throws {
        for spec in specs {
            _ = try inject(
                spec: spec,
                variables: variables,
                projectName: projectName,
                moduleName: moduleName,
                projectRootPath: projectRootPath,
                config: config,
                isDryRun: isDryRun
            )
        }
    }
}

private extension Array {
    func rIndex(where predicate: (Element) -> Bool) -> Int? {
        for index in stride(from: count - 1, through: 0, by: -1) {
            if predicate(self[index]) {
                return index
            }
        }
        return nil
    }
}
