// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "AACStandardSymbols",
    defaultLocalization: "en",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [.library(name: "AACStandardSymbols", targets: ["AACStandardSymbols"])],
    targets: [
        .target(name: "AACStandardSymbols", resources: [.process("Resources")]),
        .testTarget(name: "AACStandardSymbolsTests", dependencies: ["AACStandardSymbols"])
    ]
)
