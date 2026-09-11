import Foundation

public struct InjectionSpec {
    public let target: String
    public let marker: String?
    public let content: String
    public let condition: String?

    public init(target: String, marker: String? = nil, content: String, condition: String? = nil) {
        self.target = target
        self.marker = marker
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
            ? resolvedTargetPath
            : "\(projectRootPath)/\(resolvedTargetPath)"

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: absoluteTargetPath) else {
            print("⚠️ Target file for code injection not found at: \(absoluteTargetPath)")
            return false
        }

        guard var existingContent = try? String(contentsOfFile: absoluteTargetPath, encoding: .utf8) else {
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

        if let marker = spec.marker, !marker.isEmpty {
            let renderedMarker = TemplateRenderer.render(
                template: marker,
                variables: variables,
                config: config,
                moduleName: moduleName ?? "",
                projectName: projectName
            )

            if let markerIndex = lines.firstIndex(where: { $0.contains(renderedMarker) }) {
                lines.insert(renderedSnippet, at: markerIndex + 1)
                injected = true
            }
        }

        if !injected {
            // Fallback: append before the last closing brace or at end of file
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
