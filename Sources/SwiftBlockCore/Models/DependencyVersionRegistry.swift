import Foundation

public struct DependencyVersionRegistry: Codable, Equatable {
    public var tuist: String
    public var xcodegen: String
    public var swiftlint: String
    public var swiftformat: String
    public var periphery: String
    public var gitleaks: String
    public var precommit: String
    public var danger: String
    public var swiftgen: String
    public var licenseplist: String
    public var swiftToolsVersion: String
    public var iOSDeploymentTarget: String

    public static let defaults = DependencyVersionRegistry(
        tuist: "4.40.0",
        xcodegen: "2.42.0",
        swiftlint: "0.57.0",
        swiftformat: "0.54.0",
        periphery: "2.20.0",
        gitleaks: "8.21.0",
        precommit: "3.8.0",
        danger: "3.20.0",
        swiftgen: "6.6.3",
        licenseplist: "3.25.1",
        swiftToolsVersion: "6.0",
        iOSDeploymentTarget: "17.0"
    )

    public init(
        tuist: String = "4.40.0",
        xcodegen: String = "2.42.0",
        swiftlint: String = "0.57.0",
        swiftformat: String = "0.54.0",
        periphery: String = "2.20.0",
        gitleaks: String = "8.21.0",
        precommit: String = "3.8.0",
        danger: String = "3.20.0",
        swiftgen: String = "6.6.3",
        licenseplist: String = "3.25.1",
        swiftToolsVersion: String = "6.0",
        iOSDeploymentTarget: String = "17.0"
    ) {
        self.tuist = tuist
        self.xcodegen = xcodegen
        self.swiftlint = swiftlint
        self.swiftformat = swiftformat
        self.periphery = periphery
        self.gitleaks = gitleaks
        self.precommit = precommit
        self.danger = danger
        self.swiftgen = swiftgen
        self.licenseplist = licenseplist
        self.swiftToolsVersion = swiftToolsVersion
        self.iOSDeploymentTarget = iOSDeploymentTarget
    }

    public static func resolve(overrides: [String: String] = [:]) -> DependencyVersionRegistry {
        var base = defaults

        // Tier 2: Check global user config ~/.swiftblock/config.json
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let globalConfigPath = "\(homeDir)/.swiftblock/config.json"
        if FileManager.default.fileExists(atPath: globalConfigPath),
           let data = try? Data(contentsOf: URL(fileURLWithPath: globalConfigPath)),
           let globalDict = try? JSONDecoder().decode([String: String].self, from: data) {
            base.apply(dict: globalDict)
        }

        // Tier 1: Check project-level overrides
        base.apply(dict: overrides)

        return base
    }

    public mutating func apply(dict: [String: String]) {
        if let val = dict["tuist"] { self.tuist = val }
        if let val = dict["xcodegen"] { self.xcodegen = val }
        if let val = dict["swiftlint"] { self.swiftlint = val }
        if let val = dict["swiftformat"] { self.swiftformat = val }
        if let val = dict["periphery"] { self.periphery = val }
        if let val = dict["gitleaks"] { self.gitleaks = val }
        if let val = dict["precommit"] { self.precommit = val }
        if let val = dict["danger"] { self.danger = val }
        if let val = dict["swiftgen"] { self.swiftgen = val }
        if let val = dict["licenseplist"] { self.licenseplist = val }
        if let val = dict["swiftToolsVersion"] ?? dict["swift"] { self.swiftToolsVersion = val }
        if let val = dict["iOSDeploymentTarget"] ?? dict["ios"] { self.iOSDeploymentTarget = val }
    }
}
