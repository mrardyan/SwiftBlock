import Foundation

public struct BlockSpec: Equatable {
    public let type: ModuleType
    public let commandName: String
    public let title: String
    public let description: String
    public let category: ModuleCategory
    public let defaultOutputPath: String
    public let defaultTemplateSubpath: String

    public init(
        type: ModuleType,
        commandName: String,
        title: String,
        description: String,
        category: ModuleCategory,
        defaultOutputPath: String,
        defaultTemplateSubpath: String
    ) {
        self.type = type
        self.commandName = commandName
        self.title = title
        self.description = description
        self.category = category
        self.defaultOutputPath = defaultOutputPath
        self.defaultTemplateSubpath = defaultTemplateSubpath
    }
}

public struct BlockRegistry {
    public static let allBlocks: [BlockSpec] = [
        // Feature Blocks
        BlockSpec(
            type: .scene,
            commandName: "scene",
            title: "Scene",
            description: "MVVM View + ViewModel + State",
            category: .feature,
            defaultOutputPath: "App/Sources/Features",
            defaultTemplateSubpath: "Modules/Scene"
        ),
        BlockSpec(
            type: .usecase,
            commandName: "usecase",
            title: "UseCase",
            description: "Domain Protocol + Implementation",
            category: .feature,
            defaultOutputPath: "App/Sources/Domain/UseCases",
            defaultTemplateSubpath: "Modules/UseCase"
        ),
        BlockSpec(
            type: .repository,
            commandName: "repository",
            title: "Repository",
            description: "Data Protocol + Implementation",
            category: .feature,
            defaultOutputPath: "App/Sources/Data/Repositories",
            defaultTemplateSubpath: "Modules/Repository"
        ),
        BlockSpec(
            type: .service,
            commandName: "service",
            title: "Service",
            description: "API Service Protocol + Implementation",
            category: .feature,
            defaultOutputPath: "App/Sources/Data/Services",
            defaultTemplateSubpath: "Modules/Service"
        ),
        BlockSpec(
            type: .entity,
            commandName: "entity",
            title: "Entity",
            description: "Domain Entity / DTO Model",
            category: .feature,
            defaultOutputPath: "App/Sources/Domain/Entities",
            defaultTemplateSubpath: "Modules/Entity"
        ),
        BlockSpec(
            type: .coordinator,
            commandName: "coordinator",
            title: "Coordinator",
            description: "Navigation Flow Routing",
            category: .feature,
            defaultOutputPath: "App/Sources/Presentation/Coordinators",
            defaultTemplateSubpath: "Modules/Coordinator"
        ),
        BlockSpec(
            type: .component,
            commandName: "component",
            title: "Component",
            description: "Reusable UI Component",
            category: .feature,
            defaultOutputPath: "App/Sources/Presentation/Components",
            defaultTemplateSubpath: "Modules/Component"
        ),
        BlockSpec(
            type: .mapper,
            commandName: "mapper",
            title: "Mapper",
            description: "DTO to Domain Entity Transformer",
            category: .feature,
            defaultOutputPath: "App/Sources/Domain/Mappers",
            defaultTemplateSubpath: "Modules/Mapper"
        ),
        BlockSpec(
            type: .validator,
            commandName: "validator",
            title: "Validator",
            description: "Form Input Field Validator",
            category: .feature,
            defaultOutputPath: "App/Sources/Presentation/Validators",
            defaultTemplateSubpath: "Modules/Validator"
        ),

        // Core Blocks
        BlockSpec(
            type: .storage,
            commandName: "storage",
            title: "Storage",
            description: "Local Persistence Storage Engine",
            category: .core,
            defaultOutputPath: "App/Sources/Core/Storage",
            defaultTemplateSubpath: "Core/Storage"
        ),
        BlockSpec(
            type: .network,
            commandName: "network",
            title: "Network",
            description: "Network Client / HTTP Request Engine",
            category: .core,
            defaultOutputPath: "App/Sources/Core/Network",
            defaultTemplateSubpath: "Core/Network"
        ),
        BlockSpec(
            type: .logger,
            commandName: "logger",
            title: "Logger",
            description: "Unified OSLog / Crash Logger Engine",
            category: .core,
            defaultOutputPath: "App/Sources/Core/Logger",
            defaultTemplateSubpath: "Core/Logger"
        ),
        BlockSpec(
            type: .analytics,
            commandName: "analytics",
            title: "Analytics",
            description: "Event Analytics & Metrics Engine",
            category: .core,
            defaultOutputPath: "App/Sources/Core/Analytics",
            defaultTemplateSubpath: "Core/Analytics"
        ),
        BlockSpec(
            type: .config,
            commandName: "config",
            title: "Config",
            description: "Environment Config & Feature Flags",
            category: .core,
            defaultOutputPath: "App/Sources/Core/Config",
            defaultTemplateSubpath: "Core/Config"
        ),
        BlockSpec(
            type: .auth,
            commandName: "auth",
            title: "Auth",
            description: "User Session & Token State Manager",
            category: .core,
            defaultOutputPath: "App/Sources/Core/Auth",
            defaultTemplateSubpath: "Core/Auth"
        ),
        BlockSpec(
            type: .featureflag,
            commandName: "featureflag",
            title: "FeatureFlag",
            description: "Feature Flags & Remote Toggles Engine",
            category: .core,
            defaultOutputPath: "App/Sources/Core/FeatureFlag",
            defaultTemplateSubpath: "Core/FeatureFlag"
        )
    ]

    public static var featureBlocks: [BlockSpec] {
        allBlocks.filter { $0.category == .feature }
    }

    public static var coreBlocks: [BlockSpec] {
        allBlocks.filter { $0.category == .core }
    }

    public static func spec(for type: ModuleType) -> BlockSpec? {
        allBlocks.first { $0.type == type }
    }

    public static func spec(forCommand command: String) -> BlockSpec? {
        allBlocks.first { $0.commandName.lowercased() == command.lowercased() }
    }
}
