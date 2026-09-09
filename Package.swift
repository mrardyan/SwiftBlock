// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "iosgen",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "iosgen", targets: ["iosgen"]),
        .library(name: "IOSGenCore", targets: ["IOSGenCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
    ],
    targets: [
        .target(
            name: "IOSGenCore",
            dependencies: []
        ),
        .executableTarget(
            name: "iosgen",
            dependencies: [
                "IOSGenCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "IOSGenTests",
            dependencies: ["IOSGenCore"]
        )
    ]
)

