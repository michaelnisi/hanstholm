// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Core",
    platforms: [
        .watchOS(.v26),
        .macOS(.v14),
        .iOS(.v26)
    ],
    products: [
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
            name: "ConditionsPlugin",
            targets: ["ConditionsPlugin"]
        ),
        .library(
            name: "Conditions",
            targets: ["Conditions"]
        ),
        .library(
            name: "SurfUI",
            targets: ["SurfUI"]
        )
    ],
    targets: [
        .target(
            name: "DomainTypes"
        ),
        .testTarget(
            name: "DomainTypesTests",
            dependencies: ["DomainTypes"]
        ),
        .target(
            name: "ConditionsPlugin",
            dependencies: ["DomainTypes"]
        ),
        .target(
            name: "Hyde",
            dependencies: ["DomainTypes", "ConditionsPlugin"]
        ),
        .testTarget(
            name: "HydeTests",
            dependencies: ["Hyde", "DomainTypes", "ConditionsPlugin"]
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
            dependencies: ["ConditionsPlugin", "Cache", "DomainTypes"]
        ),
        .testTarget(
            name: "ConditionsTests",
            dependencies: ["Conditions", "ConditionsPlugin", "Cache", "DomainTypes"]
        ),
        .target(
            name: "SurfUI"
        ),
        .testTarget(
            name: "SurfUITests",
            dependencies: ["SurfUI"]
        )
    ]
)
