import Foundation

public enum BrickInstantiationType: String, Codable {
    case singleton
    case generative
}

public struct VariableSpec: Equatable {
    public let name: String
    public let type: String // "string", "confirm", "select"
    public let prompt: String
    public let defaultValue: String?
    public let validate: String?
    public let options: [String]?
    
    public init(name: String, type: String, prompt: String, defaultValue: String? = nil, validate: String? = nil, options: [String]? = nil) {
        self.name = name
        self.type = type
        self.prompt = prompt
        self.defaultValue = defaultValue
        self.validate = validate
        self.options = options
    }
}

public struct FileSpec: Equatable {
    public let source: String
    public let destination: String
    public let condition: String?
    
    public init(source: String, destination: String, condition: String? = nil) {
        self.source = source
        self.destination = destination
        self.condition = condition
    }
}

public struct DependencyItemSpec: Equatable {
    public let name: String
    public let reason: String?
    public let autoWire: Bool
    
    public init(name: String, reason: String? = nil, autoWire: Bool = false) {
        self.name = name
        self.reason = reason
        self.autoWire = autoWire
    }
}

public struct BrickDependenciesSpec: Equatable {
    public let mandatory: [DependencyItemSpec]
    public let optional: [DependencyItemSpec]
    public let conflicts: [String]
    
    public init(mandatory: [DependencyItemSpec] = [], optional: [DependencyItemSpec] = [], conflicts: [String] = []) {
        self.mandatory = mandatory
        self.optional = optional
        self.conflicts = conflicts
    }
}

public struct FlavorOptionSpec: Equatable {
    public let id: String
    public let title: String
    public let description: String?
    public let files: [FileSpec]
    public let variables: [String: String]
    public let dependencies: BrickDependenciesSpec?
    
    public init(
        id: String,
        title: String,
        description: String? = nil,
        files: [FileSpec] = [],
        variables: [String: String] = [:],
        dependencies: BrickDependenciesSpec? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.files = files
        self.variables = variables
        self.dependencies = dependencies
    }
}

public struct FlavorSpec: Equatable {
    public let id: String
    public let prompt: String
    public let defaultValue: String?
    public let options: [FlavorOptionSpec]
    
    public init(id: String, prompt: String, defaultValue: String? = nil, options: [FlavorOptionSpec] = []) {
        self.id = id
        self.prompt = prompt
        self.defaultValue = defaultValue
        self.options = options
    }
}

public struct BrickManifest {
    public let name: String
    public let category: String
    public let instantiation: BrickInstantiationType
    public let description: String
    public let version: String
    public let defaultPath: String
    public let requiresNameArgument: Bool
    public let namingPostfix: String?
    public let baseplates: [String]?
    public let variables: [VariableSpec]
    public let files: [FileSpec]
    public let preSnapHooks: [String]
    public let postSnapHooks: [String]
    public let injections: [InjectionSpec]
    public let dependencies: BrickDependenciesSpec
    public let flavors: [String: FlavorSpec]
    
    public init(
        name: String,
        category: String = "general",
        instantiation: BrickInstantiationType = .generative,
        description: String = "",
        version: String = "1.0.0",
        defaultPath: String = "App/Sources/Features",
        requiresNameArgument: Bool = true,
        namingPostfix: String? = nil,
        baseplates: [String]? = nil,
        variables: [VariableSpec] = [],
        files: [FileSpec] = [],
        preSnapHooks: [String] = [],
        postSnapHooks: [String] = [],
        injections: [InjectionSpec] = [],
        dependencies: BrickDependenciesSpec = BrickDependenciesSpec(),
        flavors: [String: FlavorSpec] = [:]
    ) {
        self.name = name
        self.category = category
        self.instantiation = instantiation
        self.description = description
        self.version = version
        self.defaultPath = defaultPath
        self.requiresNameArgument = requiresNameArgument
        self.namingPostfix = namingPostfix
        self.baseplates = baseplates
        self.variables = variables
        self.files = files
        self.preSnapHooks = preSnapHooks
        self.postSnapHooks = postSnapHooks
        self.injections = injections
        self.dependencies = dependencies
        self.flavors = flavors
    }
    
    /// The module/instance name derived from the manifest `name`, converting snake_case to
    /// PascalCase and preserving existing camelCase (e.g. "battery_level" -> "BatteryLevel",
    /// "BiometricAuthManager" stays as-is).
    public var defaultInstanceName: String {
        if name.contains("_") {
            return name.split(separator: "_").map { String($0).capitalized }.joined()
        }
        return name.isEmpty ? name : String(name.prefix(1).uppercased()) + name.dropFirst()
    }

    public static func load(fromPath path: String) -> BrickManifest? {
        let fileManager = FileManager.default
        let ymlPath = path.hasSuffix("brick.yml") ? path : (path as NSString).appendingPathComponent("brick.yml")
        let jsonPath = (path as NSString).appendingPathComponent("block.json")

        if fileManager.fileExists(atPath: ymlPath), let content = try? String(contentsOfFile: ymlPath, encoding: .utf8) {
            return parseYAML(content, folderName: (path as NSString).lastPathComponent)
        } else if fileManager.fileExists(atPath: jsonPath), let data = fileManager.contents(atPath: jsonPath),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return parseJSONDict(json, folderName: (path as NSString).lastPathComponent)
        }
        
        let folderName = (path as NSString).lastPathComponent
        return BrickManifest(name: folderName.lowercased())
    }
    
    public static func parseYAML(_ content: String, folderName: String) -> BrickManifest {
        let parsed = SimpleYAMLParser.parse(content)
        return parseDict(parsed, folderName: folderName)
    }
    
    public static func parseJSONDict(_ dict: [String: Any], folderName: String) -> BrickManifest {
        return parseDict(dict, folderName: folderName)
    }
    
    private static func parseDict(_ dict: [String: Any], folderName: String) -> BrickManifest {
        let name = (dict["name"] as? String) ?? folderName.lowercased()
        let category = (dict["category"] as? String) ?? "general"
        let instStr = (dict["instantiation"] as? String) ?? (dict["type"] as? String) ?? "generative"
        let instantiation = BrickInstantiationType(rawValue: instStr.lowercased()) ?? .generative
        let description = (dict["description"] as? String) ?? (dict["title"] as? String) ?? ""
        let version = (dict["version"] as? String) ?? "1.0.0"
        let defaultPath = (dict["defaultPath"] as? String) ?? (dict["defaultOutputPath"] as? String) ?? "App/Sources/Features"
        let requiresName = (dict["requiresNameArgument"] as? Bool) ?? (instantiation == .generative)
        let baseplates = (dict["baseplates"] as? [String]) ?? (dict["platforms"] as? [String])
        
        var namingPostfix: String? = nil
        if let naming = dict["namingConvention"] as? [String: Any] {
            namingPostfix = naming["postfix"] as? String
        }
        
        var variables: [VariableSpec] = []
        if let varsList = dict["variables"] as? [[String: Any]] {
            for v in varsList {
                if let vName = v["name"] as? String {
                    let vType = (v["type"] as? String) ?? "string"
                    let vPrompt = (v["prompt"] as? String) ?? "Enter \(vName):"
                    let vDefault = v["default"] != nil ? "\(v["default"]!)" : nil
                    let vValidate = v["validate"] as? String
                    let vOptions = v["options"] as? [String]
                    variables.append(VariableSpec(name: vName, type: vType, prompt: vPrompt, defaultValue: vDefault, validate: vValidate, options: vOptions))
                }
            }
        }
        
        var files: [FileSpec] = []
        if let filesList = dict["files"] as? [[String: Any]] {
            for f in filesList {
                if let src = f["source"] as? String, let dest = f["destination"] as? String {
                    let cond = f["condition"] as? String
                    files.append(FileSpec(source: src, destination: dest, condition: cond))
                }
            }
        }
        
        var preSnapHooks: [String] = []
        var postSnapHooks: [String] = []
        if let hooksDict = dict["hooks"] as? [String: Any] {
            if let pre = hooksDict["pre_snap"] as? [Any] {
                preSnapHooks = pre.map { "\($0)" }
            } else if let pre = hooksDict["pre-snap"] as? [Any] {
                preSnapHooks = pre.map { "\($0)" }
            } else if let preStr = hooksDict["pre_snap"] as? String {
                preSnapHooks = [preStr]
            }
            
            if let post = hooksDict["post_snap"] as? [Any] {
                postSnapHooks = post.map { "\($0)" }
            } else if let post = hooksDict["post-snap"] as? [Any] {
                postSnapHooks = post.map { "\($0)" }
            } else if let postStr = hooksDict["post_snap"] as? String {
                postSnapHooks = [postStr]
            }
        }
        
        var injections: [InjectionSpec] = []
        if let injList = dict["injections"] as? [[String: Any]] {
            for item in injList {
                if let target = item["target"] as? String, let content = item["content"] as? String {
                    let marker = item["marker"] as? String
                    let scope = item["scope"] as? String
                    let condition = item["condition"] as? String
                    injections.append(InjectionSpec(target: target, marker: marker, scope: scope, content: content, condition: condition))
                }
            }
        }

        // Dependencies Parsing
        var mandatoryDeps: [DependencyItemSpec] = []
        var optionalDeps: [DependencyItemSpec] = []
        var conflictDeps: [String] = []

        if let depsDict = dict["dependencies"] as? [String: Any] {
            if let mandList = depsDict["mandatory"] as? [Any] {
                mandatoryDeps = parseDependencyList(mandList)
            } else if let reqList = depsDict["requires"] as? [Any] {
                mandatoryDeps = parseDependencyList(reqList)
            }
            if let optList = depsDict["optional"] as? [Any] {
                optionalDeps = parseDependencyList(optList)
            } else if let suggList = depsDict["suggests"] as? [Any] {
                optionalDeps = parseDependencyList(suggList)
            }
            if let confList = depsDict["conflicts"] as? [Any] {
                conflictDeps = confList.map { "\($0)".trimmingCharacters(in: .whitespaces) }
            }
        }
        let dependencies = BrickDependenciesSpec(mandatory: mandatoryDeps, optional: optionalDeps, conflicts: conflictDeps)

        // Flavors Parsing
        var flavors: [String: FlavorSpec] = [:]
        if let flavorsDict = dict["flavors"] as? [String: Any] {
            for (flavorKey, flavorVal) in flavorsDict {
                if let fDict = flavorVal as? [String: Any] {
                    let prompt = (fDict["prompt"] as? String) ?? "Select flavor for \(flavorKey):"
                    let defaultValue = fDict["default"] != nil ? "\(fDict["default"]!)" : nil
                    var options: [FlavorOptionSpec] = []
                    if let optsList = fDict["options"] as? [[String: Any]] {
                        for opt in optsList {
                            if let id = opt["id"] as? String {
                                let title = (opt["title"] as? String) ?? id.capitalized
                                let desc = opt["description"] as? String
                                options.append(FlavorOptionSpec(id: id, title: title, description: desc))
                            }
                        }
                    }
                    flavors[flavorKey] = FlavorSpec(id: flavorKey, prompt: prompt, defaultValue: defaultValue, options: options)
                }
            }
        }
        
        return BrickManifest(
            name: name,
            category: category,
            instantiation: instantiation,
            description: description,
            version: version,
            defaultPath: defaultPath,
            requiresNameArgument: requiresName,
            namingPostfix: namingPostfix,
            baseplates: baseplates,
            variables: variables,
            files: files,
            preSnapHooks: preSnapHooks,
            postSnapHooks: postSnapHooks,
            injections: injections,
            dependencies: dependencies,
            flavors: flavors
        )
    }

    private static func parseDependencyList(_ list: [Any]) -> [DependencyItemSpec] {
        var result: [DependencyItemSpec] = []
        for item in list {
            if let str = item as? String {
                result.append(DependencyItemSpec(name: str.trimmingCharacters(in: .whitespaces)))
            } else if let dict = item as? [String: Any] {
                if let name = dict["name"] as? String {
                    let reason = dict["reason"] as? String ?? dict["description"] as? String
                    let autoWire = (dict["autoWire"] as? Bool) ?? (dict["autoWireCode"] as? Bool) ?? false
                    result.append(DependencyItemSpec(name: name, reason: reason, autoWire: autoWire))
                }
            }
        }
        return result
    }
}
