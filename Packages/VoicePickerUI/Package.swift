// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "VoicePickerUI", defaultLocalization: "en", platforms: [.iOS(.v16)],
    products: [.library(name: "VoicePickerUI", targets: ["VoicePickerUI"])],
    targets: [.target(name: "VoicePickerUI", resources: [.process("Resources")])])
