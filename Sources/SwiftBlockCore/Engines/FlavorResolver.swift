import Foundation

public struct FlavorResolutionResult: Equatable {
    public var variables: [String: String]
    public var selectedOptionalDeps: Set<String>

    public init(variables: [String: String] = [:], selectedOptionalDeps: Set<String> = []) {
        self.variables = variables
        self.selectedOptionalDeps = selectedOptionalDeps
    }
}

/// Resolves a brick manifest's declared `flavors` against user-provided selections,
/// merging the selected option's template variables and flavor-scoped optional
/// dependencies. Undeclared selection keys fall back to plain template variables
/// for backward compatibility.
public enum FlavorResolver {
    public static func resolve(
        manifest: BrickManifest,
        selections: [String: String],
        variables: [String: String] = [:],
        selectedOptionalDeps: Set<String> = []
    ) -> FlavorResolutionResult {
        var resolvedVars = variables
        var selected = selectedOptionalDeps

        // Normalize selection keys (lowercased) so lookups are case-insensitive.
        var normalizedSelections: [String: String] = [:]
        for (key, value) in selections {
            normalizedSelections[key.lowercased()] = value
        }

        // 1. Apply default or selected option for every declared flavor
        for (flavorKey, flavor) in manifest.flavors {
            let selectedValue = normalizedSelections[flavorKey.lowercased()]
                ?? normalizedSelections[flavor.id.lowercased()]
                ?? flavor.defaultValue
                ?? flavor.options.first?.id
            guard let val = selectedValue else { continue }
            guard let option = flavor.options.first(where: { $0.id.lowercased() == val.lowercased() }) else {
                continue
            }

            resolvedVars[flavorKey] = option.id
            for (k, v) in option.variables {
                resolvedVars[k] = v
            }
            if let deps = option.dependencies {
                for dep in deps.optional {
                    selected.insert(dep.name.lowercased())
                }
            }
        }

        // 2. Ensure every declared flavor ends up with a concrete value: if the user-supplied
        //    selection was invalid, fall back to the flavor default (or first option).
        for (flavorKey, flavor) in manifest.flavors {
            guard resolvedVars[flavorKey] == nil else { continue }
            let fallback = flavor.defaultValue ?? flavor.options.first?.id
            guard let fallbackID = fallback,
                  let option = flavor.options.first(where: { $0.id.lowercased() == fallbackID.lowercased() }) else { continue }
            resolvedVars[flavorKey] = option.id
            for (k, v) in option.variables {
                resolvedVars[k] = v
            }
            if let deps = option.dependencies {
                for dep in deps.optional {
                    selected.insert(dep.name.lowercased())
                }
            }
        }

        // 3. Process undeclared flavor keys as custom template variables
        for (flavorKey, selectedValue) in normalizedSelections where manifest.flavors[flavorKey] == nil {
            resolvedVars[flavorKey] = selectedValue
        }

        return FlavorResolutionResult(variables: resolvedVars, selectedOptionalDeps: selected)
    }

    /// Returns the unknown-option warning message for a declared flavor, or `nil`
    /// when the selection is valid. Used by the CLI to surface actionable feedback.
    public static func validateSelection(manifest: BrickManifest, flavorKey: String, selectedValue: String) -> String? {
        guard let flavor = flavor(in: manifest, named: flavorKey) else { return nil }
        if flavor.options.contains(where: { $0.id.lowercased() == selectedValue.lowercased() }) {
            return nil
        }
        let available = flavor.options.map(\.id).joined(separator: ", ")
        return "Unknown option '\(selectedValue)' for flavor '\(flavorKey)'. Available: \(available) — ignoring."
    }

    private static func flavor(in manifest: BrickManifest, named key: String) -> FlavorSpec? {
        if let flavor = manifest.flavors[key.lowercased()] { return flavor }
        return manifest.flavors.first { $0.key.lowercased() == key.lowercased() }?.value
    }
}
