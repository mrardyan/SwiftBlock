import Foundation

public struct BrickMetadata: Codable {
    public let title: String?
    public let description: String?
    public let defaultOutputPath: String?

    public init(title: String? = nil, description: String? = nil, defaultOutputPath: String? = nil) {
        self.title = title
        self.description = description
        self.defaultOutputPath = defaultOutputPath
    }
}

public typealias BlockMetadata = BrickMetadata

public struct BrickDiscoveryEngine {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// Smart Namespace Resolution (`[box/][category/]<brick>`)
    /// Resolves brick name or path to the full file directory path containing brick.yml
    public func resolveBrickPath(named nameOrPath: String, in baseDir: String) -> String? {
        let nameLower = nameOrPath.lowercased()
        
        // 1. Direct path check
        if fileManager.fileExists(atPath: nameOrPath) {
            return nameOrPath
        }
        
        // 2. Check explicitly under baseDir
        let candidatePath = "\(baseDir)/\(nameOrPath)"
        if fileManager.fileExists(atPath: candidatePath) {
            return candidatePath
        }
        
        // 3. Check local project overrides (.swiftblock/blocks/)
        let localOverride = "\(baseDir)/.swiftblock/blocks/\(nameOrPath)"
        if fileManager.fileExists(atPath: localOverride) {
            return localOverride
        }

        // 4. Check registered Box store (~/.swiftblock/store/v1/boxes/<nameOrPath>)
        let boxManager = BoxManager()
        let boxPath = "\(boxManager.boxesDirectory)/\(nameOrPath)"
        if fileManager.fileExists(atPath: boxPath) {
            return boxPath
        }

        // 5. Search under Bricks/ Singletons, Generatives/Architecture, Generatives/UI
        let searchSubdirs = [
            "Bricks/Singletons",
            "Bricks/Generatives/Architecture",
            "Bricks/Generatives/UI",
            "Bricks",
            "Blocks/Core",
            "Blocks/Modules",
            "Singletons",
            "Generatives/Architecture",
            "Generatives/UI"
        ]
        
        for subdir in searchSubdirs {
            let direct = "\(baseDir)/\(subdir)/\(nameOrPath)"
            if fileManager.fileExists(atPath: direct) {
                return direct
            }
            
            // Check case-insensitive folder names
            let parentDir = "\(baseDir)/\(subdir)"
            if let items = try? fileManager.contentsOfDirectory(atPath: parentDir) {
                for item in items {
                    if item.lowercased() == nameLower {
                        return "\(parentDir)/\(item)"
                    }
                }
            }
        }
        
        // 6. Recursive scan for matching brick directory across standard search roots
        var searchRoots = [
            baseDir,
            "\(baseDir)/Bricks",
            "\(FileManager.default.currentDirectoryPath)/Bricks",
            boxManager.boxesDirectory,
            "/usr/local/share/swiftblock/Bricks",
            "/usr/local/share/swiftblock/Blocks"
        ]
        if let envRoot = ProcessInfo.processInfo.environment["SWIFTBLOCK_ROOT"] {
            searchRoots.insert("\(envRoot)/Bricks", at: 0)
            searchRoots.insert(envRoot, at: 1)
        }
        for root in searchRoots {
            if fileManager.fileExists(atPath: root), let resolved = scanDirectory(root, targetName: nameLower) {
                return resolved
            }
        }
        
        return nil
    }
    
    private func scanDirectory(_ dir: String, targetName: String) -> String? {
        guard fileManager.fileExists(atPath: dir),
              let items = try? fileManager.contentsOfDirectory(atPath: dir) else {
            return nil
        }
        
        for item in items {
            let fullPath = "\(dir)/\(item)"
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: fullPath, isDirectory: &isDir), isDir.boolValue {
                if item.lowercased() == targetName {
                    let ymlPath = "\(fullPath)/brick.yml"
                    let jsonPath = "\(fullPath)/block.json"
                    if fileManager.fileExists(atPath: ymlPath) || fileManager.fileExists(atPath: jsonPath) {
                        return fullPath
                    }
                }
                if let subMatch = scanDirectory(fullPath, targetName: targetName) {
                    return subMatch
                }
            }
        }
        return nil
    }

    public func discoverBricks(in baseTemplatePath: String, category: Brick.Category) -> [BrickSpec] {
        let searchDirs = category == .feature ? ["Bricks/Generatives/Architecture", "Bricks/Generatives/UI", "Blocks/Modules"] : ["Bricks/Singletons", "Blocks/Core"]
        
        var specs: [BrickSpec] = []
        for dir in searchDirs {
            let categoryDir = "\(baseTemplatePath)/\(dir)"
            guard fileManager.fileExists(atPath: categoryDir),
                  let folderNames = try? fileManager.contentsOfDirectory(atPath: categoryDir) else {
                continue
            }
            
            for folderName in folderNames.sorted() {
                let fullPath = "\(categoryDir)/\(folderName)"
                var isDir: ObjCBool = false
                guard fileManager.fileExists(atPath: fullPath, isDirectory: &isDir), isDir.boolValue else {
                    continue
                }
                
                let manifest = BrickManifest.load(fromPath: fullPath)
                let commandName = manifest?.name ?? folderName.lowercased()
                let title = manifest?.name.capitalized ?? folderName
                let description = manifest?.description ?? "\(folderName) Brick"
                let defaultOutputPath = manifest?.defaultPath ?? (category == .feature ? "App/Sources/Features/{module}/\(folderName)" : "App/Sources/Core/\(folderName)")
                let moduleType = Brick(rawValue: commandName)
                
                let spec = BrickSpec(
                    type: moduleType,
                    commandName: commandName,
                    title: title,
                    description: description,
                    category: category,
                    defaultOutputPath: defaultOutputPath,
                    defaultTemplateSubpath: "\(dir)/\(folderName)"
                )
                specs.append(spec)
            }
        }

        return specs.isEmpty ? fallbackSpecs(for: category) : specs
    }

    public func discoverBlocks(in baseTemplatePath: String, category: Brick.Category) -> [BrickSpec] {
        return discoverBricks(in: baseTemplatePath, category: category)
    }

    public static func evaluateTokens(
        in pathTemplate: String,
        moduleName: String,
        blockName: String
    ) -> String {
        let moduleLower = moduleName.lowercased()
        let blockLower = blockName.lowercased()

        return pathTemplate
            .replacingOccurrences(of: "{module}", with: moduleLower)
            .replacingOccurrences(of: "{block}", with: blockLower)
            .replacingOccurrences(of: "{{name}}", with: moduleName)
            .replacingOccurrences(of: "__MODULE_NAME__", with: moduleName)
    }

    private func fallbackSpecs(for category: Brick.Category) -> [BrickSpec] {
        BrickRegistry.allBricks.filter { $0.category == category }
    }
}

public typealias BlockDiscoveryEngine = BrickDiscoveryEngine
