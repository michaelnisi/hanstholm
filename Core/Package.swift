// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Core",
    platforms: [
        .watchOS(.v10),
        .macOS(.v14),
        .iOS(.v17)
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
            name: "SurfConditions",
            targets: ["SurfConditions"]
        ),
        .library(
            name: "Conditions",
            targets: ["Conditions"]
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
