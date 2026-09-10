import Foundation

public class LocalPackageGenerator {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func generateCorePackage(in projectPath: String, config: SwiftBlockConfig) throws {
        let versions = DependencyVersionRegistry.resolve(overrides: config.toolVersions)
        let corePackageDir = "\(projectPath)/Packages/Core"
        let sourcesDir = "\(corePackageDir)/Sources/Core"
        try fileManager.createDirectory(atPath: sourcesDir, withIntermediateDirectories: true)

        let coreSwiftFile = "\(sourcesDir)/Core.swift"
        if !fileManager.fileExists(atPath: coreSwiftFile) {
            var configureSteps: [String] = []
            for type in config.coreBlocks {
                switch type {
                case .storage: configureSteps.append("        let _ = AppStorage()")
                case .network: configureSteps.append("        let _ = NetworkClient()")
                case .logger: configureSteps.append("        let logger = AppLogger()\n        logger.info(\"CoreModule initialized.\")")
                case .config: configureSteps.append("        let _ = AppConfig()")
                case .auth: configureSteps.append("        let _ = UserAuth()")
                case .analytics: configureSteps.append("        let _ = AppAnalytics()")
                case .featureflag: configureSteps.append("        let _ = FeatureFlags()")
                default: break
                }
            }

            let stepsText = configureSteps.isEmpty
                ? "        // Entry point for Core infrastructure setup (e.g. Logger, Storage, Network)"
                : "        // Configured Core Foundation Modules:\n" + configureSteps.joined(separator: "\n")

            let content = """
            import Foundation

            /// Central entry point and namespace for shared Core infrastructure.
            @available(iOS 15.0, macOS 12.0, *)
            public struct CoreModule {
                public static let version = "1.0.0"

                /// Call this method during application launch (e.g. in @main App.init()) to initialize Core services.
                @available(iOS 15.0, macOS 12.0, *)
                public static func configure() {
            \(stepsText)
                }

                public init() {}
            }
            """
            let trimmedContent = content.trimmingCharacters(in: .newlines) + "\n"
            try trimmedContent.write(toFile: coreSwiftFile, atomically: true, encoding: .utf8)
        }

        let packageManifestPath = "\(corePackageDir)/Package.swift"
        let manifestContent = """
// swift-tools-version: \(versions.swiftToolsVersion)
import PackageDescription

let package = Package(
    name: "Core",
    platforms: [.iOS(.v\(versions.iOSDeploymentTarget.replacingOccurrences(of: ".0", with: ""))), .macOS(.v13)],
    products: [
        .library(name: "Core", targets: ["Core"]),
    ],
    targets: [
        .target(
            name: "Core",
            dependencies: [],
            path: "Sources/Core"
        ),
    ]
)
"""
        let trimmedManifest = manifestContent.trimmingCharacters(in: .newlines) + "\n"
        try trimmedManifest.write(toFile: packageManifestPath, atomically: true, encoding: .utf8)
    }

    public func generateFeaturePackage(moduleName: String, in projectPath: String, config: SwiftBlockConfig) throws {
        let versions = DependencyVersionRegistry.resolve(overrides: config.toolVersions)
        let capitalizedName = moduleName.capitalized
        let featurePackageDir = "\(projectPath)/Packages/\(capitalizedName)Feature"
        let sourcesDir = "\(featurePackageDir)/Sources/\(capitalizedName)Feature"
        try fileManager.createDirectory(atPath: sourcesDir, withIntermediateDirectories: true)

        let featureSwiftFile = "\(sourcesDir)/\(capitalizedName)Feature.swift"
        if !fileManager.fileExists(atPath: featureSwiftFile) {
            let content = """
            //
            // \(capitalizedName)Feature.swift
            // \(capitalizedName)Feature
            //
            import Foundation

            public struct \(capitalizedName)FeatureModule {
                public init() {}
            }
            """
            let trimmedContent = content.trimmingCharacters(in: .newlines) + "\n"
            try trimmedContent.write(toFile: featureSwiftFile, atomically: true, encoding: .utf8)
        }

        let packageManifestPath = "\(featurePackageDir)/Package.swift"
        let manifestContent = """
// swift-tools-version: \(versions.swiftToolsVersion)
import PackageDescription

let package = Package(
    name: "\(capitalizedName)Feature",
    platforms: [.iOS(.v\(versions.iOSDeploymentTarget.replacingOccurrences(of: ".0", with: ""))), .macOS(.v13)],
    products: [
        .library(name: "\(capitalizedName)Feature", targets: ["\(capitalizedName)Feature"]),
    ],
    targets: [
        .target(
            name: "\(capitalizedName)Feature",
            dependencies: [],
            path: "Sources/\(capitalizedName)Feature"
        ),
    ]
)
"""
        let trimmedManifest = manifestContent.trimmingCharacters(in: .newlines) + "\n"
        try trimmedManifest.write(toFile: packageManifestPath, atomically: true, encoding: .utf8)
    }
}
