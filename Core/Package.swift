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
            name: "Conditions",
            targets: ["Conditions"]
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "DomainTypes"
        ),
        .testTarget(
            name: "DomainTypesTests",
            dependencies: ["DomainTypes"]
        ),
        .target(
            name: "SurfConditions",
            dependencies: ["DomainTypes"]
        ),
        .target(
            name: "Hyde",
            dependencies: ["DomainTypes", "SurfConditions"]
        ),
        .testTarget(
            name: "HydeTests",
            dependencies: ["Hyde", "DomainTypes", "SurfConditions"]
        ),
        .target(
            name: "MockData",
            dependencies: ["DomainTypes"]
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
            name: "Conditions",
            dependencies: ["SurfConditions", "Cache", "DomainTypes"]
        ),
        .testTarget(
            name: "ConditionsTests",
            dependencies: ["Conditions", "SurfConditions", "Cache", "DomainTypes"]
        )
    ]
)
