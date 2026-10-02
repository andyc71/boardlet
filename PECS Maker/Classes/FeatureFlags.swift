import Foundation

/// Shared defaults for every app variant. Debug builds allow UI tests to exercise
/// disabled features without changing the shipping configuration.
struct FeatureFlags {
    let voiceEnabled: Bool
    let arasaacSymbolsEnabled: Bool

    init(environment: [String: String] = [:]) {
        voiceEnabled = environment["PECS_FEATURE_VOICE"] != "0"
        arasaacSymbolsEnabled = environment["PECS_FEATURE_ARASAAC"] != "0"
    }

    static let current: FeatureFlags = {
#if DEBUG
        FeatureFlags(environment: ProcessInfo.processInfo.environment)
#else
        FeatureFlags()
#endif
    }()
}
