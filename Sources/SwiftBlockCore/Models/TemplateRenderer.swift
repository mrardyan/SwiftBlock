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

        // 1. Replace standard SwiftBlock placeholders
        result = result.replacingOccurrences(of: "__MODULE_NAME__", with: moduleName)
        result = result.replacingOccurrences(of: "__PROJECT_NAME__", with: projectName)
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
