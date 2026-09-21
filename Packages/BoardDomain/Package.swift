// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BoardDomain",
    platforms: [
        .iOS("16.6"),
        .macOS(.v13)
    ],
    products: [
        .library(name: "BoardDomain", targets: ["BoardDomain"])
    ],
    targets: [
        .target(name: "BoardDomain"),
        .testTarget(name: "BoardDomainTests", dependencies: ["BoardDomain"])
    ]
)
