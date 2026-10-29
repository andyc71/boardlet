// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EngagementKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v16)],
    products: ["EngagementKit", "EngagementCore", "EngagementRatings", "EngagementVoting", "EngagementWhatsNew", "EngagementTipKit"].map {
        .library(name: $0, targets: [$0])
    },
    dependencies: [
        .package(url: "https://github.com/andyc71/SharedSwiftUI.git", branch: "main"),
        .package(url: "https://github.com/andyc71/MailFramework.git", branch: "main")
    ],
    targets: [
        .target(name: "EngagementCore"),
        .target(name: "EngagementContent", dependencies: ["SharedSwiftUI"]),
        .target(name: "EngagementRatings", dependencies: ["EngagementCore"]),
        .target(name: "EngagementVoting", dependencies: ["EngagementCore", "EngagementContent", "MailFramework", "SharedSwiftUI"]),
        .target(name: "EngagementWhatsNew", dependencies: ["EngagementCore", "EngagementContent", "SharedSwiftUI"]),
        .target(name: "EngagementTipKit", dependencies: ["EngagementCore"]),
        .target(name: "EngagementKit", dependencies: ["EngagementContent", "EngagementCore", "EngagementRatings", "EngagementVoting", "EngagementWhatsNew"]),
        .testTarget(name: "EngagementKitTests", dependencies: ["EngagementKit", "EngagementTipKit"], resources: [.copy("Assets")])
    ]
)
