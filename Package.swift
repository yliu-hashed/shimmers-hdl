// swift-tools-version: 6.2

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "shimmers-hdl",
    platforms: [.macOS(.v26)],
    products: [
        .library(
            name: "Shimmers",
            targets: ["Shimmers"]
        ),
        .library(
            name: "ShimmersCLIWrapper",
            targets: ["ShimmersCLIWrapper"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.6.0")),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", .upToNextMinor(from: "602.0.0")),
        .package(url: "https://github.com/swiftlang/swift-subprocess.git", branch: "main")
    ],
    targets: [
        .macro(
            name: "ShimmersMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(
            name: "Shimmers",
            dependencies: [
                .target(name: "ShimmersMacros"),
                .product(name: "Subprocess", package: "swift-subprocess"),
            ],
        ),
        .target(
            name: "ShimmersCLIWrapper",
            dependencies: [
                .target(name: "Shimmers"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
        ),
        .testTarget(
            name: "ShimmersInternalLogicTests",
            dependencies: ["Shimmers"],
        ),
        .testTarget(
            name: "ShimmersInternalRuntimeTests",
            dependencies: ["Shimmers"],
        ),
    ],
)
