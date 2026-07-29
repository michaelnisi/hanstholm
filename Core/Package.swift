// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Core",
    platforms: [
        .watchOS(.v10),
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Hyde",
            targets: ["Hyde"]
        ),
        .library(
            name: "DomainTypes",
            targets: ["DomainTypes"]
        ),
        .library(
            name: "MockData",
            targets: ["MockData"]
        ),
        .library(
            name: "Cache",
            targets: ["Cache"]
        ),
        .library(
            name: "SurfConditions",
            targets: ["SurfConditions"]
        ),
        .library(
            name: "HydePlugin",
            targets: ["HydePlugin"]
        ),
        .library(
            name: "Conditions",
            targets: ["Conditions"]
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Hyde"
        ),
        .testTarget(
            name: "HydeTests",
            dependencies: ["Hyde"]
        ),
        .target(
            name: "DomainTypes"
        ),
        .testTarget(
            name: "DomainTypesTests",
            dependencies: ["DomainTypes"]
        ),
        .target(
            name: "MockData",
            dependencies: ["Hyde", "DomainTypes"]
        ),
        .target(
            name: "Cache",
            dependencies: ["DomainTypes"]
        ),
        .testTarget(
            name: "CacheTests",
            dependencies: ["Cache", "DomainTypes"]
        ),
        .target(
            name: "SurfConditions",
            dependencies: ["DomainTypes"]
        ),
        .target(
            name: "HydePlugin",
            dependencies: ["Hyde", "DomainTypes", "SurfConditions"]
        ),
        .testTarget(
            name: "HydePluginTests",
            dependencies: ["HydePlugin", "Hyde", "DomainTypes", "SurfConditions"]
        ),
        .target(
            name: "Conditions",
            dependencies: ["SurfConditions", "Cache", "DomainTypes"]
        ),
        .testTarget(
            name: "ConditionsTests",
            dependencies: ["Conditions", "SurfConditions", "Cache", "DomainTypes"]
        )
    ]
)
