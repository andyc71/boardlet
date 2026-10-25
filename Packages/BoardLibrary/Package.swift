// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "BoardLibrary", platforms: [.iOS(.v16), .macOS(.v13)], products: [.library(name: "BoardLibrary", targets: ["BoardLibrary"])], targets: [.target(name: "BoardLibrary", linkerSettings: [.linkedLibrary("sqlite3")]), .testTarget(name: "BoardLibraryTests", dependencies: ["BoardLibrary"]), .executableTarget(name: "BoardLibraryBenchmark", dependencies: ["BoardLibrary"])])
