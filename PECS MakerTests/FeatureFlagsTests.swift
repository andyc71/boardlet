import Testing
@testable import PECS_Maker

struct FeatureFlagsTests {
    @Test func standardDisablesChoiceBoardByDefault() {
        let flags = FeatureFlags()
        #expect(!flags.voiceEnabled)
        #expect(flags.arasaacSymbolsEnabled)
        #expect(!FeatureFlags.current.voiceEnabled)
        #expect(FeatureFlags.current.arasaacSymbolsEnabled)
    }

    @Test(arguments: ["PECS_FEATURE_VOICE", "PECS_FEATURE_ARASAAC"])
    func standardKeepsChoiceBoardDisabledWhenOtherFlagsChange(key: String) {
        let flags = FeatureFlags(environment: [key: "0"])
        #expect(!flags.voiceEnabled)
        #expect(flags.arasaacSymbolsEnabled == (key != "PECS_FEATURE_ARASAAC"))
    }

    @Test func debugOverrideCannotEnableChoiceBoardInStandard() {
        #expect(!FeatureFlags(environment: ["PECS_FEATURE_VOICE": "1"]).voiceEnabled)
    }
}
