import Foundation

public struct TemplateRenderer {
    public static func render(
        template: String,
        variables: [String: String],
        config: SwiftBlockConfig? = nil,
        moduleName: String = "",
        projectName: String = ""
    ) -> String {
        var result = template

        // 0. Render conditional blocks ({{#if ...}}...{{else}}...{{/if}} and {{#unless ...}}...{{/unless}})
        result = renderConditionals(template: result, variables: variables)

        // 1. Replace standard SwiftBlock placeholders
        result = result.replacingOccurrences(of: "__MODULE_NAME__", with: moduleName)
        result = result.replacingOccurrences(of: "__PROJECT_NAME__", with: projectName)
        result = result.replacingOccurrences(of: "__APP_MODULE__", with: config?.appModuleName ?? projectName)
        result = result.replacingOccurrences(of: "{{name}}", with: moduleName)
        result = result.replacingOccurrences(of: "{{name.lowercased()}}", with: moduleName.lowercased())
        result = result.replacingOccurrences(of: "{{name.capitalized}}", with: moduleName.capitalized)
        result = result.replacingOccurrences(of: "{{moduleName}}", with: moduleName)
        result = result.replacingOccurrences(of: "{{moduleName.lowercased()}}", with: moduleName.lowercased())
        result = result.replacingOccurrences(of: "{{moduleName.capitalized}}", with: moduleName.capitalized)
        result = result.replacingOccurrences(of: "{{projectName}}", with: projectName)

        // 2. Replace custom variables {{variableName}}
        for (key, val) in variables {
            result = result.replacingOccurrences(of: "{{\(key)}}", with: val)
        }

        // 3. Replace paths tokens if config is provided
        if let config = config {
            for (key, val) in config.paths.allCustomPaths {
                result = result.replacingOccurrences(of: "{{paths.\(key)}}", with: val)
            }
            for type in Brick.allCases {
                let resolved = config.resolveOutputPath(for: type, moduleName: moduleName)
                result = result.replacingOccurrences(of: "{{paths.\(type.rawValue.lowercased())}}", with: resolved)
            }
            result = result.replacingOccurrences(of: "{{paths.feature}}", with: "App/Sources/Features")
            result = result.replacingOccurrences(of: "{{paths.core}}", with: "Packages/Core/Sources/Core")
        }

        return result
    }

    private static func renderConditionals(template: String, variables: [String: String]) -> String {
        var result = template

        // Match {{#if expr}}body{{else}}body{{/if}} or {{#if expr}}body{{/if}}
        let ifPattern = #"\{\{#if\s+([^\}]+)\}\}([\s\S]*?)(?:\{\{else\}\}([\s\S]*?))?\{\{\/if\}\}"#
        if let regex = try? NSRegularExpression(pattern: ifPattern, options: []) {
            var iterations = 0
            while iterations < 50, let match = regex.firstMatch(in: result, options: [], range: NSRange(location: 0, length: result.utf16.count)) {
                iterations += 1
                let fullRange = match.range
                guard let condRange = Range(match.range(at: 1), in: result),
                      let trueRange = Range(match.range(at: 2), in: result) else { break }

                let conditionStr = String(result[condRange]).trimmingCharacters(in: .whitespaces)
                let trueBranch = String(result[trueRange])
                let falseBranch: String
                if match.numberOfRanges > 3 && match.range(at: 3).location != NSNotFound,
                   let falseR = Range(match.range(at: 3), in: result) {
                    falseBranch = String(result[falseR])
                } else {
                    falseBranch = ""
                }

                let isConditionTrue = evaluateCondition(conditionStr, variables: variables)
                let replacement = isConditionTrue ? trueBranch : falseBranch

                if let fullR = Range(fullRange, in: result) {
                    result.replaceSubrange(fullR, with: replacement)
                }
            }
        }

        // Support {{#unless expr}}body{{/unless}}
        let unlessPattern = #"\{\{#unless\s+([^\}]+)\}\}([\s\S]*?)\{\{\/unless\}\}"#
        if let regex = try? NSRegularExpression(pattern: unlessPattern, options: []) {
            var iterations = 0
            while iterations < 50, let match = regex.firstMatch(in: result, options: [], range: NSRange(location: 0, length: result.utf16.count)) {
                iterations += 1
                let fullRange = match.range
                guard let condRange = Range(match.range(at: 1), in: result),
                      let bodyRange = Range(match.range(at: 2), in: result) else { break }

                let conditionStr = String(result[condRange]).trimmingCharacters(in: .whitespaces)
                let body = String(result[bodyRange])

                let isConditionTrue = evaluateCondition(conditionStr, variables: variables)
                let replacement = !isConditionTrue ? body : ""

                if let fullR = Range(fullRange, in: result) {
                    result.replaceSubrange(fullR, with: replacement)
                }
            }
        }

        return result
    }

    private static func evaluateCondition(_ condition: String, variables: [String: String]) -> Bool {
        if condition.contains("==") {
            let parts = condition.components(separatedBy: "==").map { $0.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "'\"")) }
            if parts.count == 2 {
                let lhs = variables[parts[0]] ?? variables[parts[0].lowercased()] ?? parts[0]
                let rhs = variables[parts[1]] ?? variables[parts[1].lowercased()] ?? parts[1]
                return lhs.lowercased() == rhs.lowercased()
            }
        } else if condition.contains("!=") {
            let parts = condition.components(separatedBy: "!=").map { $0.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "'\"")) }
            if parts.count == 2 {
                let lhs = variables[parts[0]] ?? variables[parts[0].lowercased()] ?? parts[0]
                let rhs = variables[parts[1]] ?? variables[parts[1].lowercased()] ?? parts[1]
                return lhs.lowercased() != rhs.lowercased()
            }
        } else {
            let val = variables[condition] ?? variables[condition.lowercased()]
            if let v = val {
                let lower = v.lowercased()
                return lower != "false" && lower != "0" && !lower.isEmpty
            }
            return false
        }
        return false
    }

    public static func renderPath(
        pathTemplate: String,
        variables: [String: String],
        moduleName: String,
        blockName: String,
        config: SwiftBlockConfig? = nil
    ) -> String {
        var path = pathTemplate
            .replacingOccurrences(of: "{module}", with: moduleName.lowercased())
            .replacingOccurrences(of: "{block}", with: blockName.lowercased())
            .replacingOccurrences(of: "__MODULE_NAME__", with: moduleName)
            .replacingOccurrences(of: "__PROJECT_NAME__", with: config?.projectName ?? "")
            .replacingOccurrences(of: "__APP_MODULE__", with: config?.appModuleName ?? "")
            .replacingOccurrences(of: "{{name}}", with: moduleName)
            .replacingOccurrences(of: "{{name.lowercased()}}", with: moduleName.lowercased())
            .replacingOccurrences(of: "{{name.capitalized}}", with: moduleName.capitalized)
            .replacingOccurrences(of: "{{moduleName}}", with: moduleName)
            .replacingOccurrences(of: "{{moduleName.lowercased()}}", with: moduleName.lowercased())
            .replacingOccurrences(of: "{{moduleName.capitalized}}", with: moduleName.capitalized)

        for (key, val) in variables {
            path = path.replacingOccurrences(of: "{{\(key)}}", with: val)
        }

        if let config = config {
            for (key, val) in config.paths.allCustomPaths {
                path = path.replacingOccurrences(of: "{{paths.\(key)}}", with: val)
            }
            for type in Brick.allCases {
                let resolved = config.resolveOutputPath(for: type, moduleName: moduleName)
                path = path.replacingOccurrences(of: "{{paths.\(type.rawValue.lowercased())}}", with: resolved)
            }
            path = path.replacingOccurrences(of: "{{paths.feature}}", with: "App/Sources/Features")
            path = path.replacingOccurrences(of: "{{paths.core}}", with: "Packages/Core/Sources/Core")
        }

        return path
    }
}
