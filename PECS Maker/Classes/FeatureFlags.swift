import Foundation

/// Variant capabilities with debug overrides for disabling features in UI tests.
struct FeatureFlags {
    let voiceEnabled: Bool
    let arasaacSymbolsEnabled: Bool

    init(environment: [String: String] = [:]) {
        #if EasyPECSPlus
        voiceEnabled = environment["PECS_FEATURE_VOICE"] != "0"
        #else
        voiceEnabled = false
        #endif
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
