// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swiftblock",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "swiftblock", targets: ["swiftblock"]),
        .library(name: "SwiftBlockCore", targets: ["SwiftBlockCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
    ],
    targets: [
        .target(
            name: "SwiftBlockCore",
            dependencies: []
        ),
        .executableTarget(
            name: "swiftblock",
            dependencies: [
                "SwiftBlockCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "SwiftBlockTests",
            dependencies: ["SwiftBlockCore"]
        )
    ]
)
