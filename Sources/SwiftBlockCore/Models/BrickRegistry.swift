import Foundation

public struct BrickSpec: Equatable {
    public let type: Brick
    public let commandName: String
    public let title: String
    public let description: String
    public let category: Brick.Category
    public let defaultOutputPath: String
    public let defaultTemplateSubpath: String
    public let baseplates: [String]?

    public init(
        type: Brick,
        commandName: String,
        title: String,
        description: String,
        category: Brick.Category,
        defaultOutputPath: String,
        defaultTemplateSubpath: String,
        baseplates: [String]? = nil
    ) {
        self.type = type
        self.commandName = commandName
        self.title = title
        self.description = description
        self.category = category
        self.defaultOutputPath = defaultOutputPath
        self.defaultTemplateSubpath = defaultTemplateSubpath
        self.baseplates = baseplates
    }

    /// Whether this brick can be snapped into the given baseplate (vapor vs swiftui).
    /// Bricks without `baseplates` metadata are considered compatible with everything.
    public func isCompatible(withVapor isVapor: Bool) -> Bool {
        guard let baseplates = baseplates, !baseplates.isEmpty else { return true }
        let allowed = baseplates.map { $0.lowercased() }
        return isVapor ? allowed.contains("vapor") : allowed.contains("swiftui")
    }
}

public struct BrickRegistry {
    /// Curated specs for the well-known bricks. Kept for stable metadata/titles; the full catalog
    /// is auto-discovered from the installed Bricks directories via `discoveredSpecs()`.
    public static let curatedSpecs: [BrickSpec] = [
        // Feature Bricks
        BrickSpec(
            type: .scene,
            commandName: "scene",
            title: "Scene",
            description: "MVVM View + ViewModel + State",
            category: .feature,
            defaultOutputPath: "App/Sources/Features",
            defaultTemplateSubpath: "Modules/Scene"
        ),
        BrickSpec(
            type: .usecase,
            commandName: "usecase",
            title: "UseCase",
            description: "Domain Protocol + Implementation",
            category: .feature,
            defaultOutputPath: "App/Sources/Domain/UseCases",
            defaultTemplateSubpath: "Modules/UseCase"
        ),
        BrickSpec(
            type: .repository,
            commandName: "repository",
            title: "Repository",
            description: "Data Protocol + Implementation",
            category: .feature,
            defaultOutputPath: "App/Sources/Data/Repositories",
            defaultTemplateSubpath: "Modules/Repository"
        ),
        BrickSpec(
            type: .service,
            commandName: "service",
            title: "Service",
            description: "API Service Protocol + Implementation",
            category: .feature,
            defaultOutputPath: "App/Sources/Data/Services",
            defaultTemplateSubpath: "Modules/Service"
        ),
        BrickSpec(
            type: .entity,
            commandName: "entity",
            title: "Entity",
            description: "Domain Entity / DTO Model",
            category: .feature,
            defaultOutputPath: "App/Sources/Domain/Entities",
            defaultTemplateSubpath: "Modules/Entity"
        ),
        BrickSpec(
            type: .coordinator,
            commandName: "coordinator",
            title: "Coordinator",
            description: "Navigation Flow Routing",
            category: .feature,
            defaultOutputPath: "App/Sources/Presentation/Coordinators",
            defaultTemplateSubpath: "Modules/Coordinator"
        ),
        BrickSpec(
            type: .component,
            commandName: "component",
            title: "Component",
            description: "Reusable UI Component",
            category: .feature,
            defaultOutputPath: "App/Sources/Presentation/Components",
            defaultTemplateSubpath: "Modules/Component"
        ),
        BrickSpec(
            type: .mapper,
            commandName: "mapper",
            title: "Mapper",
            description: "DTO to Domain Entity Transformer",
            category: .feature,
            defaultOutputPath: "App/Sources/Domain/Mappers",
            defaultTemplateSubpath: "Modules/Mapper"
        ),
        BrickSpec(
            type: .validator,
            commandName: "validator",
            title: "Validator",
            description: "Form Input Field Validator",
            category: .feature,
            defaultOutputPath: "App/Sources/Presentation/Validators",
            defaultTemplateSubpath: "Modules/Validator"
        ),

        // Core Bricks
        BrickSpec(
            type: .storage,
            commandName: "storage",
            title: "Storage",
            description: "Local Persistence Storage Engine",
            category: .core,
            defaultOutputPath: "App/Sources/Core/Storage",
            defaultTemplateSubpath: "Core/Storage"
        ),
        BrickSpec(
            type: .network,
            commandName: "network",
            title: "Network",
            description: "Network Client / HTTP Request Engine",
            category: .core,
            defaultOutputPath: "App/Sources/Core/Network",
            defaultTemplateSubpath: "Core/Network"
        ),
        BrickSpec(
            type: .logger,
            commandName: "logger",
            title: "Logger",
            description: "Unified OSLog / Crash Logger Engine",
            category: .core,
            defaultOutputPath: "App/Sources/Core/Logger",
            defaultTemplateSubpath: "Core/Logger"
        ),
        BrickSpec(
            type: .analytics,
            commandName: "analytics",
            title: "Analytics",
            description: "Event Analytics & Metrics Engine",
            category: .core,
            defaultOutputPath: "App/Sources/Core/Analytics",
            defaultTemplateSubpath: "Core/Analytics"
        ),
        BrickSpec(
            type: .config,
            commandName: "config",
            title: "Config",
            description: "Environment Config & Feature Flags",
            category: .config,
            defaultOutputPath: "App/Sources/Core/Config",
            defaultTemplateSubpath: "Config/Config"
        ),
        BrickSpec(
            type: .auth,
            commandName: "auth",
            title: "Auth",
            description: "User Session & Token State Manager (Keychain / iOS)",
            category: .core,
            defaultOutputPath: "App/Sources/Core/Auth",
            defaultTemplateSubpath: "Core/Auth",
            baseplates: ["swiftui"]
        ),
        BrickSpec(
            type: .vaporauth,
            commandName: "vaporauth",
            title: "VaporAuth",
            description: "JWT & Session Auth Manager for Vapor backend API",
            category: .core,
            defaultOutputPath: "Sources/App/Core/Auth",
            defaultTemplateSubpath: "Core/VaporAuth",
            baseplates: ["vapor"]
        ),
        BrickSpec(
            type: .featureflag,
            commandName: "featureflag",
            title: "FeatureFlag",
            description: "Feature Flags & Remote Toggles Engine",
            category: .config,
            defaultOutputPath: "App/Sources/Core/FeatureFlag",
            defaultTemplateSubpath: "Config/FeatureFlag"
        ),
        BrickSpec(
            type: .biometrics,
            commandName: "biometrics",
            title: "Biometrics",
            description: "Face ID & Touch ID LocalAuthentication Manager",
            category: .core,
            defaultOutputPath: "App/Sources/Core/Biometrics",
            defaultTemplateSubpath: "Core/Biometrics"
        ),
        BrickSpec(
            type: .deeplink,
            commandName: "deeplink",
            title: "DeepLink",
            description: "URL Scheme & Universal Link Routing Engine",
            category: .core,
            defaultOutputPath: "App/Sources/Core/DeepLink",
            defaultTemplateSubpath: "Core/DeepLink"
        ),
        BrickSpec(
            type: .permissions,
            commandName: "permissions",
            title: "Permissions",
            description: "Unified System Permissions Manager",
            category: .core,
            defaultOutputPath: "App/Sources/Core/Permissions",
            defaultTemplateSubpath: "Core/Permissions"
        ),
        BrickSpec(
            type: .location,
            commandName: "location",
            title: "Location",
            description: "CoreLocation Service & Location Stream Manager",
            category: .core,
            defaultOutputPath: "App/Sources/Core/Location",
            defaultTemplateSubpath: "Core/Location"
        ),
        BrickSpec(
            type: .notification,
            commandName: "notification",
            title: "Notification",
            description: "Local & Push Notification Scheduler",
            category: .core,
            defaultOutputPath: "App/Sources/Core/Notification",
            defaultTemplateSubpath: "Core/Notification"
        )
    ]

    /// Full brick catalog: curated specs merged with auto-discovered bricks from the Bricks
    /// directories. Curated specs win on name collision.
    public static var allBricks: [BrickSpec] {
        let discovered = discoveredSpecs()
        var merged: [String: BrickSpec] = [:]
        for spec in discovered { merged[spec.commandName] = spec }
        for spec in curatedSpecs { merged[spec.commandName] = spec }
        return merged.values.sorted { $0.commandName < $1.commandName }
    }

    /// Curated specs only. Used for path-strategy resolution where user `pathTemplates` should
    /// take precedence over the brick author's default path.
    public static func curatedSpec(for type: Brick) -> BrickSpec? {
        curatedSpecs.first { $0.type == type }
    }

    /// Auto-discovers every brick template under the known Bricks roots by scanning for
    /// `brick.yml` / `block.json` manifests. Command names derive from the folder name, so any
    /// brick added to the correct directory is immediately snapable without registry changes.
    public static func discoveredSpecs() -> [BrickSpec] {
        if let cached = discoveredCache { return cached }

        let fileManager = FileManager.default
        var roots: [String] = []
        if let envRoot = ProcessInfo.processInfo.environment["SWIFTBLOCK_ROOT"], !envRoot.isEmpty {
            roots.append("\(envRoot)/Bricks")
            roots.append(envRoot)
        }
        roots.append("\(fileManager.currentDirectoryPath)/Bricks")
        roots.append("/usr/local/share/swiftblock/Bricks")
        roots.append("/usr/local/share/swiftblock/Blocks")

        var result: [String: BrickSpec] = [:]
        for root in roots {
            guard fileManager.fileExists(atPath: root),
                  let enumerator = fileManager.enumerator(at: URL(fileURLWithPath: root), includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else {
                continue
            }
            for case let url as URL in enumerator {
                let file = url.lastPathComponent
                guard file == "brick.yml" || file == "brick.yaml" || file == "block.json" else { continue }
                let brickFolder = url.deletingLastPathComponent()
                guard let manifest = BrickManifest.load(fromPath: brickFolder.path) else { continue }
                let folderName = brickFolder.lastPathComponent
                let commandName = folderName.lowercased()
                guard result[commandName] == nil else { continue }
                let category = Self.category(for: manifest.category, defaultPath: manifest.defaultPath)
                result[commandName] = BrickSpec(
                    type: Brick(rawValue: commandName),
                    commandName: commandName,
                    title: manifest.name.capitalized,
                    description: manifest.description,
                    category: category,
                    defaultOutputPath: manifest.defaultPath.isEmpty
                        ? Self.fallbackPath(category: category, commandName: commandName)
                        : manifest.defaultPath,
                    defaultTemplateSubpath: brickFolder.path.replacingOccurrences(of: root + "/", with: ""),
                    baseplates: manifest.baseplates
                )
            }
        }

        let sorted = result.values.sorted { $0.commandName < $1.commandName }
        discoveredCache = sorted
        return sorted
    }

    private static var discoveredCache: [BrickSpec]?

    /// Maps a manifest `category` string to a `Brick.Category`. Used both by auto-discovery and
    /// by generation so that unregistered bricks get the correct category regardless of search roots.
    public static func category(for raw: String, defaultPath: String = "") -> Brick.Category {
        let c = raw.lowercased()
        if c.contains("feature") || c.contains("architecture") || c.contains("generative") {
            return .feature
        }
        if c.contains("config") {
            return .config
        }
        if c.contains("utils") || c.contains("utility") || c.contains("value") || c.contains("formatter") || c.contains("validator") || c.contains("ui") {
            return .utils
        }
        if defaultPath.lowercased().contains("feature") {
            return .feature
        }
        return .core
    }

    private static func fallbackPath(category: Brick.Category, commandName: String) -> String {
        switch category {
        case .feature: return "App/Sources/Features/{module}/\(commandName)"
        case .config: return "App/Sources/Core/Config/\(commandName)"
        case .utils: return "App/Sources/Core/\(commandName.capitalized)"
        default: return "App/Sources/Core/\(commandName.capitalized)"
        }
    }

    public static var featureBricks: [BrickSpec] {
        allBricks.filter { $0.category == .feature }
    }

    public static var coreBricks: [BrickSpec] {
        allBricks.filter { $0.category != .feature }
    }

    public static func spec(for type: Brick) -> BrickSpec? {
        allBricks.first { $0.type == type }
    }

    public static func spec(forCommand command: String) -> BrickSpec? {
        let normalized = command.lowercased()
        let separator: Character? = normalized.contains("/") ? "/" : (normalized.contains(".") ? "." : nil)
        if let sep = separator {
            let parts = normalized.split(separator: sep, maxSplits: 1).map(String.init)
            if parts.count == 2 {
                let categoryStr = parts[0]
                let nameStr = parts[1]
                return allBricks.first {
                    ($0.category.rawValue == categoryStr || (categoryStr == "feature" && $0.category != .core)) &&
                    $0.commandName.lowercased() == nameStr
                } ?? allBricks.first { $0.commandName.lowercased() == nameStr }
            }
        }
        return allBricks.first { $0.commandName.lowercased() == normalized }
    }
}

// MARK: - Built-in Brick Presets Extension
extension Brick {
    public enum Feature {
        public static let scene: Brick = "scene"
        public static let usecase: Brick = "usecase"
        public static let repository: Brick = "repository"
        public static let service: Brick = "service"
        public static let entity: Brick = "entity"
        public static let coordinator: Brick = "coordinator"
        public static let component: Brick = "component"
        public static let mapper: Brick = "mapper"
        public static let validator: Brick = "validator"
    }

    public enum Core {
        public static let storage: Brick = "storage"
        public static let network: Brick = "network"
        public static let logger: Brick = "logger"
        public static let analytics: Brick = "analytics"
        public static let config: Brick = "config"
        public static let auth: Brick = "auth"
        public static let vaporauth: Brick = "vaporauth"
        public static let featureflag: Brick = "featureflag"
        public static let validator: Brick = "validator"
        public static let biometrics: Brick = "biometrics"
        public static let deeplink: Brick = "deeplink"
        public static let permissions: Brick = "permissions"
        public static let location: Brick = "location"
        public static let notification: Brick = "notification"
    }

    // Conveniences
    public static let scene = Feature.scene
    public static let usecase = Feature.usecase
    public static let repository = Feature.repository
    public static let service = Feature.service
    public static let entity = Feature.entity
    public static let coordinator = Feature.coordinator
    public static let component = Feature.component
    public static let mapper = Feature.mapper
    public static let validator = Feature.validator

    public static let storage = Core.storage
    public static let network = Core.network
    public static let logger = Core.logger
    public static let analytics = Core.analytics
    public static let config = Core.config
    public static let auth = Core.auth
    public static let vaporauth = Core.vaporauth
    public static let featureflag = Core.featureflag
    public static let biometrics = Core.biometrics
    public static let deeplink = Core.deeplink
    public static let permissions = Core.permissions
    public static let location = Core.location
    public static let notification = Core.notification

    public static var allCases: [Brick] {
        [
            Feature.scene, Feature.usecase, Feature.repository, Feature.service, Feature.entity,
            Feature.coordinator, Feature.component, Feature.mapper, Feature.validator,
            Core.storage, Core.network, Core.logger, Core.analytics, Core.config, Core.auth, Core.vaporauth, Core.featureflag,
            Core.biometrics, Core.deeplink, Core.permissions, Core.location, Core.notification
        ]
    }
}

// MARK: - Built-in Brick.Category Presets Extension
extension Brick.Category {
    public static let feature: Brick.Category = "feature"
    public static let core: Brick.Category = "core"
    public static let config: Brick.Category = "config"
    public static let utils: Brick.Category = "utils"
    public static let ui: Brick.Category = "ui"
    public static let domain: Brick.Category = "domain"
    public static let data: Brick.Category = "data"
    public static let presentation: Brick.Category = "presentation"

    public var isSingleton: Bool {
        return self == .core || self == .config || self == .utils || rawValue == "infrastructure" || rawValue == "singletons"
    }
}
