// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "OpenSymbols",
    platforms: [.iOS(.v16)],
    products: [.library(name: "OpenSymbols", targets: ["OpenSymbols"])],
    targets: [
        .target(name: "OpenSymbols"),
        .testTarget(name: "OpenSymbolsTests", dependencies: ["OpenSymbols"])
    ]
)
