import Foundation

public struct ParsedGitURL: Equatable {
    public let repoURL: String
    public let fragment: String?

    public init(repoURL: String, fragment: String?) {
        self.repoURL = repoURL
        self.fragment = fragment
    }
}

public enum BoxManagerError: Error, LocalizedError, Equatable {
    case boxNotFound(String)
    case cloneFailed(String)
    case invalidGitURL(String)

    public var errorDescription: String? {
        switch self {
        case .boxNotFound(let name):
            return "Box '\(name)' is not registered in SwiftBlock box store."
        case .cloneFailed(let reason):
            return "Failed to clone Git repository: \(reason)"
        case .invalidGitURL(let url):
            return "Invalid Git URL provided: '\(url)'."
        }
    }
}

public class BoxManager {
    public let storeRootPath: String
    private let fileManager: FileManager

    public var boxesDirectory: String {
        "\(storeRootPath)/store/v1/boxes"
    }

    public var gitCacheDirectory: String {
        "\(storeRootPath)/store/v1/git"
    }

    public var boxesConfigFile: String {
        "\(storeRootPath)/store/v1/boxes.yml"
    }

    public init(
        storeRootPath: String? = nil,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        if let custom = storeRootPath {
            self.storeRootPath = custom
        } else if let envHome = ProcessInfo.processInfo.environment["SWIFTBLOCK_HOME"] {
            self.storeRootPath = envHome
        } else {
            let userHome = NSHomeDirectory()
            self.storeRootPath = "\(userHome)/.swiftblock"
        }
    }

    public static func parseGitURL(_ urlString: String) -> ParsedGitURL {
        if let fragmentRange = urlString.range(of: "#") {
            let repoURL = String(urlString[..<fragmentRange.lowerBound])
            let fragment = String(urlString[fragmentRange.upperBound...])
            return ParsedGitURL(repoURL: repoURL, fragment: fragment.isEmpty ? nil : fragment)
        }
        return ParsedGitURL(repoURL: urlString, fragment: nil)
    }

    public static func isGitURL(_ urlString: String) -> Bool {
        let lower = urlString.lowercased()
        return lower.hasPrefix("http://") ||
               lower.hasPrefix("https://") ||
               lower.hasPrefix("git@") ||
               lower.hasSuffix(".git") ||
               urlString.contains(".git#")
    }

    public func addBox(name: String, gitURL: String, isVerbose: Bool = false) throws {
        let normalizedName = name.lowercased().trimmingCharacters(in: .whitespaces)
        guard !normalizedName.isEmpty else {
            throw BoxManagerError.invalidGitURL("Box name cannot be empty")
        }

        try fileManager.createDirectory(atPath: boxesDirectory, withIntermediateDirectories: true)
        let targetBoxPath = "\(boxesDirectory)/\(normalizedName)"

        if fileManager.fileExists(atPath: targetBoxPath) {
            try? fileManager.removeItem(atPath: targetBoxPath)
        }

        let parsed = Self.parseGitURL(gitURL)
        if isVerbose {
            print("🔹 [Box] Registering box '\(normalizedName)' from \(parsed.repoURL)...")
        }

        let gitBinary = findGitExecutable()
        let exitCode = runProcess(executable: gitBinary, arguments: ["clone", "--depth", "1", parsed.repoURL, targetBoxPath], currentDirectoryPath: boxesDirectory)
        guard exitCode == 0 else {
            throw BoxManagerError.cloneFailed("git clone failed for '\(parsed.repoURL)'")
        }

        var boxes = listBoxes()
        boxes[normalizedName] = gitURL
        try saveBoxesConfig(boxes)
    }

    public func removeBox(name: String) throws {
        let normalizedName = name.lowercased().trimmingCharacters(in: .whitespaces)
        let targetBoxPath = "\(boxesDirectory)/\(normalizedName)"
        if fileManager.fileExists(atPath: targetBoxPath) {
            try? fileManager.removeItem(atPath: targetBoxPath)
        }

        var boxes = listBoxes()
        boxes.removeValue(forKey: normalizedName)
        try saveBoxesConfig(boxes)
    }

    public func listBoxes() -> [String: String] {
        guard fileManager.fileExists(atPath: boxesConfigFile),
              let content = try? String(contentsOfFile: boxesConfigFile, encoding: .utf8) else {
            return [:]
        }
        let parsed = SimpleYAMLParser.parse(content)
        var result: [String: String] = [:]
        for (k, v) in parsed {
            if let str = v as? String {
                result[k.lowercased()] = str
            }
        }
        return result
    }

    public func updateBoxes(name: String? = nil, isVerbose: Bool = false) throws {
        let boxes = listBoxes()
        let gitBinary = findGitExecutable()

        let targets: [String]
        if let name = name?.lowercased() {
            guard boxes[name] != nil else {
                throw BoxManagerError.boxNotFound(name)
            }
            targets = [name]
        } else {
            targets = Array(boxes.keys)
        }

        for boxName in targets {
            let boxPath = "\(boxesDirectory)/\(boxName)"
            if fileManager.fileExists(atPath: boxPath) {
                if isVerbose {
                    print("🔹 [Box] Updating box '\(boxName)'...")
                }
                _ = runProcess(executable: gitBinary, arguments: ["pull"], currentDirectoryPath: boxPath)
            }
        }
    }

    public func fetchGitRepository(urlString: String, isVerbose: Bool = false) throws -> (cachedPath: String, fragment: String?) {
        let parsed = Self.parseGitURL(urlString)
        try fileManager.createDirectory(atPath: gitCacheDirectory, withIntermediateDirectories: true)

        let repoSlug = sanitizeSlug(parsed.repoURL)
        let targetCachePath = "\(gitCacheDirectory)/\(repoSlug)"

        let gitBinary = findGitExecutable()

        if fileManager.fileExists(atPath: targetCachePath) {
            if isVerbose {
                print("🔹 [GitCache] Updating remote repository cache for \(parsed.repoURL)...")
            }
            _ = runProcess(executable: gitBinary, arguments: ["pull"], currentDirectoryPath: targetCachePath)
        } else {
            if isVerbose {
                print("🔹 [GitCache] Fetching remote repository \(parsed.repoURL)...")
            }
            let exitCode = runProcess(executable: gitBinary, arguments: ["clone", "--depth", "1", parsed.repoURL, targetCachePath], currentDirectoryPath: gitCacheDirectory)
            guard exitCode == 0 else {
                throw BoxManagerError.cloneFailed("git clone failed for '\(parsed.repoURL)'")
            }
        }

        let resolvedPath: String
        if let frag = parsed.fragment {
            resolvedPath = "\(targetCachePath)/\(frag)"
        } else {
            resolvedPath = targetCachePath
        }

        return (cachedPath: resolvedPath, fragment: parsed.fragment)
    }

    public func discoverMonorepoBricks(at path: String) -> [(relativePath: String, manifest: BrickManifest)] {
        var results: [(relativePath: String, manifest: BrickManifest)] = []
        guard fileManager.fileExists(atPath: path) else { return results }

        let enumerator = fileManager.enumerator(atPath: path)
        while let file = enumerator?.nextObject() as? String {
            if file.hasSuffix("brick.yml") || file.hasSuffix("block.json") || file.hasSuffix("brick.yaml") {
                let fullPath = "\(path)/\(file)"
                if let manifest = BrickManifest.load(fromPath: fullPath) {
                    let relativeDir = (file as NSString).deletingLastPathComponent
                    results.append((relativePath: relativeDir, manifest: manifest))
                }
            }
        }
        return results.sorted(by: { $0.manifest.name < $1.manifest.name })
    }

    private func saveBoxesConfig(_ boxes: [String: String]) throws {
        let parentDir = (boxesConfigFile as NSString).deletingLastPathComponent
        try fileManager.createDirectory(atPath: parentDir, withIntermediateDirectories: true)

        var yaml = "# SwiftBlock Box Registry Configuration\n"
        for (k, v) in boxes.sorted(by: { $0.key < $1.key }) {
            yaml += "\(k): \"\(v)\"\n"
        }
        try yaml.write(toFile: boxesConfigFile, atomically: true, encoding: .utf8)
    }

    private func sanitizeSlug(_ urlString: String) -> String {
        let allowed = CharacterSet.alphanumerics
        return urlString.components(separatedBy: allowed.inverted).joined(separator: "_")
    }

    private func findGitExecutable() -> String {
        if fileManager.fileExists(atPath: "/usr/bin/git") { return "/usr/bin/git" }
        if fileManager.fileExists(atPath: "/usr/local/bin/git") { return "/usr/local/bin/git" }
        if fileManager.fileExists(atPath: "/opt/homebrew/bin/git") { return "/opt/homebrew/bin/git" }
        return "git"
    }

    private func runProcess(executable: String, arguments: [String], currentDirectoryPath: String) -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.currentDirectoryURL = URL(fileURLWithPath: currentDirectoryPath)
        try? process.run()
        process.waitUntilExit()
        return process.terminationStatus
    }
}
