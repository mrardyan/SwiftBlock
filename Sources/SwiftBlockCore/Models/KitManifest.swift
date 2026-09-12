import Foundation

public struct BrickReference {
    public let brick: String
    public let args: [String: String]?
    
    public init(brick: String, args: [String: String]? = nil) {
        self.brick = brick
        self.args = args
    }
}

public struct KitManifest {
    public let name: String
    public let description: String
    public let variables: [VariableSpec]
    public let bricks: [BrickReference]
    public let postSnapHooks: [String]
    
    public init(name: String, description: String = "", variables: [VariableSpec] = [], bricks: [BrickReference] = [], postSnapHooks: [String] = []) {
        self.name = name
        self.description = description
        self.variables = variables
        self.bricks = bricks
        self.postSnapHooks = postSnapHooks
    }
    
    public static func load(fromPath path: String) -> KitManifest? {
        let fileManager = FileManager.default
        let ymlPath = path.hasSuffix(".yml") || path.hasSuffix(".yaml") ? path : path + ".yml"
        
        guard fileManager.fileExists(atPath: ymlPath),
              let content = try? String(contentsOfFile: ymlPath, encoding: .utf8) else {
            return nil
        }
        
        let dict = SimpleYAMLParser.parse(content)
        let name = (dict["name"] as? String) ?? (path as NSString).lastPathComponent.replacingOccurrences(of: ".yml", with: "")
        let description = (dict["description"] as? String) ?? ""
        
        var variables: [VariableSpec] = []
        if let varsList = dict["variables"] as? [[String: Any]] {
            for v in varsList {
                if let vName = v["name"] as? String {
                    let vType = (v["type"] as? String) ?? "string"
                    let vPrompt = (v["prompt"] as? String) ?? "Enter \(vName):"
                    let vDefault = v["default"] != nil ? "\(v["default"]!)" : nil
                    variables.append(VariableSpec(name: vName, type: vType, prompt: vPrompt, defaultValue: vDefault))
                }
            }
        }
        
        var bricks: [BrickReference] = []
        if let bricksList = dict["bricks"] as? [[String: Any]] {
            for b in bricksList {
                if let brickName = b["brick"] as? String {
                    let args = b["args"] as? [String: String]
                    bricks.append(BrickReference(brick: brickName, args: args))
                }
            }
        }
        
        var hooks: [String] = []
        if let hooksDict = dict["hooks"] as? [String: Any],
           let postSnap = hooksDict["post_snap"] as? [[String: Any]] {
            for h in postSnap {
                if let cmd = h["command"] as? String {
                    hooks.append(cmd)
                }
            }
        }
        
        return KitManifest(name: name, description: description, variables: variables, bricks: bricks, postSnapHooks: hooks)
    }
}
