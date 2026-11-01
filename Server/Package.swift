// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Server",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "PatrolServer",
            targets: ["PatrolServer"]
        )
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(
            url: "https://github.com/hummingbird-project/hummingbird.git",
            from: "2.28.1"
        ),
    ],
    targets: [
        .target(
            name: "Server",
            dependencies: [
                .product(name: "DomainTypes", package: "Core"),
                .product(name: "Hummingbird", package: "hummingbird"),
            ]
        ),
        .executableTarget(
            name: "PatrolServer",
            dependencies: ["Server"]
        ),
        .testTarget(
            name: "ServerTests",
            dependencies: [
                "Server",
                .product(name: "DomainTypes", package: "Core"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HummingbirdTesting", package: "hummingbird"),
            ]
        ),
    ]
)
