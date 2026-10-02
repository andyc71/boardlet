import Testing
@testable import PECS_Maker

struct FeatureFlagsTests {
    @Test func featuresAreEnabledByDefault() {
        let flags = FeatureFlags()
        #expect(flags.voiceEnabled)
        #expect(flags.arasaacSymbolsEnabled)
        #expect(FeatureFlags.current.voiceEnabled)
        #expect(FeatureFlags.current.arasaacSymbolsEnabled)
    }

    @Test(arguments: ["PECS_FEATURE_VOICE", "PECS_FEATURE_ARASAAC"])
    func featuresCanBeDisabledIndependently(key: String) {
        let flags = FeatureFlags(environment: [key: "0"])
        #expect(flags.voiceEnabled == (key != "PECS_FEATURE_VOICE"))
        #expect(flags.arasaacSymbolsEnabled == (key != "PECS_FEATURE_ARASAAC"))
    }
}
