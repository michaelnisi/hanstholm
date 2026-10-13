// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "probe",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(path: "../../../../Core")
    ],
    targets: [
        .executableTarget(
            name: "probe",
            dependencies: [
                .product(name: "Hyde", package: "Core"),
                .product(name: "ConditionsPlugin", package: "Core"),
                .product(name: "DomainTypes", package: "Core"),
            ]
        )
    ]
)
