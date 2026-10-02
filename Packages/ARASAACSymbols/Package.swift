// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "ARASAACSymbols",
    defaultLocalization: "en",
    platforms: [.iOS(.v16)],
    products: [.library(name: "ARASAACSymbols", targets: ["ARASAACSymbols"])],
    targets: [
        .target(name: "ARASAACSymbols", resources: [.process("Resources")]),
        .testTarget(name: "ARASAACSymbolsTests", dependencies: ["ARASAACSymbols"])
    ]
)
