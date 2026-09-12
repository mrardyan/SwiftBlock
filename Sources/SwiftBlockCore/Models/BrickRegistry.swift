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
}

public struct BrickRegistry {
    public static let allBricks: [BrickSpec] = [
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
            category: .core,
            defaultOutputPath: "App/Sources/Core/Config",
            defaultTemplateSubpath: "Core/Config"
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
            category: .core,
            defaultOutputPath: "App/Sources/Core/FeatureFlag",
            defaultTemplateSubpath: "Core/FeatureFlag"
        ),
        BrickSpec(
            type: .formatter,
            commandName: "formatter",
            title: "Formatter",
            description: "Currency, Date, and Number Formatting Engine",
            category: .core,
            defaultOutputPath: "App/Sources/Core/Formatter",
            defaultTemplateSubpath: "Core/Formatter"
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

    public static var featureBricks: [BrickSpec] {
        allBricks.filter { $0.category == .feature }
    }

    public static var coreBricks: [BrickSpec] {
        allBricks.filter { $0.category == .core }
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
        public static let formatter: Brick = "formatter"
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
    public static let formatter = Core.formatter
    public static let biometrics = Core.biometrics
    public static let deeplink = Core.deeplink
    public static let permissions = Core.permissions
    public static let location = Core.location
    public static let notification = Core.notification

    public static var allCases: [Brick] {
        [
            Feature.scene, Feature.usecase, Feature.repository, Feature.service, Feature.entity,
            Feature.coordinator, Feature.component, Feature.mapper, Feature.validator,
            Core.storage, Core.network, Core.logger, Core.analytics, Core.config, Core.auth, Core.vaporauth, Core.featureflag, Core.formatter,
            Core.biometrics, Core.deeplink, Core.permissions, Core.location, Core.notification
        ]
    }
}

// MARK: - Built-in Brick.Category Presets Extension
extension Brick.Category {
    public static let feature: Brick.Category = "feature"
    public static let core: Brick.Category = "core"
    public static let ui: Brick.Category = "ui"
    public static let domain: Brick.Category = "domain"
    public static let data: Brick.Category = "data"
    public static let presentation: Brick.Category = "presentation"

    public var isSingleton: Bool {
        return self == .core || rawValue == "infrastructure" || rawValue == "singletons"
    }
}
