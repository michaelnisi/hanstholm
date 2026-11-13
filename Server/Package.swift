// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Server",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.28.1"),
        .package(path: "../Core"),
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "DomainTypes", package: "Core"),
            ]
        ),
        .executableTarget(
            name: "Server",
            dependencies: ["App"]
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                "App",
                .product(name: "HummingbirdTesting", package: "hummingbird"),
                .product(name: "DomainTypes", package: "Core"),
            ]
        ),
    ]
)
