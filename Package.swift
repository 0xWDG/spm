// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "spm",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "SPMCore", targets: ["SPMCore"]),
        .executable(name: "spm", targets: ["spm"])
    ],
    targets: [
        .target(
            name: "SPMCore",
            path: "Sources/spm"
        ),
        .executableTarget(
            name: "spm",
            dependencies: ["SPMCore"],
            path: "Sources/spmCLI"
        ),
        .testTarget(
            name: "spmTests",
            dependencies: ["SPMCore"]
        )
    ]
)
