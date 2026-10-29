import Foundation

enum VoiceStrings {
    static var allowPersonalVoice: String { NSLocalizedString("MainMenu.allowPersonalVoice", bundle: .module, comment: "") }
    static var appLanguage: String { NSLocalizedString("MainMenu.appLanguage", bundle: .module, comment: "") }
    static var changeVoiceButton: String { NSLocalizedString("MainMenu.changeVoiceButton", bundle: .module, comment: "") }
    static var createPersonalVoice: String { NSLocalizedString("MainMenu.createPersonalVoice", bundle: .module, comment: "") }
    static var defaultVoice: String { NSLocalizedString("MainMenu.defaultVoice", bundle: .module, comment: "") }
    static var doneButton: String { NSLocalizedString("DoneButton", bundle: .module, comment: "") }
    static var enhancedVoiceNotice: String { NSLocalizedString("MainMenu.enhancedVoiceNotice", bundle: .module, comment: "") }
    static var getMoreVoices: String { NSLocalizedString("MainMenu.getMoreVoices", bundle: .module, comment: "") }
    static var moreVoicesGotIt: String { NSLocalizedString("MainMenu.moreVoicesGotIt", bundle: .module, comment: "") }
    static var moreVoicesIntro: String { NSLocalizedString("MainMenu.moreVoicesIntro", bundle: .module, comment: "") }
    static var moreVoicesPathLegacy: String { NSLocalizedString("MainMenu.moreVoicesPathLegacy", bundle: .module, comment: "") }
    static var moreVoicesPathModern: String { NSLocalizedString("MainMenu.moreVoicesPathModern", bundle: .module, comment: "") }
    static var moreVoicesReturnDetail: String { NSLocalizedString("MainMenu.moreVoicesReturnDetail", bundle: .module, comment: "") }
    static func moreVoicesReturnTitle(_ value: String) -> String { String(format: NSLocalizedString("MainMenu.moreVoicesReturnTitle", bundle: .module, comment: ""), value) }
    static var moreVoicesStepOneDetail: String { NSLocalizedString("MainMenu.moreVoicesStepOneDetail", bundle: .module, comment: "") }
    static var moreVoicesStepOneTitle: String { NSLocalizedString("MainMenu.moreVoicesStepOneTitle", bundle: .module, comment: "") }
    static var moreVoicesStepThreeDetail: String { NSLocalizedString("MainMenu.moreVoicesStepThreeDetail", bundle: .module, comment: "") }
    static var moreVoicesStepThreeTitle: String { NSLocalizedString("MainMenu.moreVoicesStepThreeTitle", bundle: .module, comment: "") }
    static var moreVoicesStepTwoTitle: String { NSLocalizedString("MainMenu.moreVoicesStepTwoTitle", bundle: .module, comment: "") }
    static var moreVoicesTitle: String { NSLocalizedString("MainMenu.moreVoicesTitle", bundle: .module, comment: "") }
    static var noPersonalVoiceForLanguage: String { NSLocalizedString("MainMenu.noPersonalVoiceForLanguage", bundle: .module, comment: "") }
    static var noPersonalVoices: String { NSLocalizedString("MainMenu.noPersonalVoices", bundle: .module, comment: "") }
    static var noPremiumVoiceNotice: String { NSLocalizedString("MainMenu.noPremiumVoiceNotice", bundle: .module, comment: "") }
    static var personalVoice: String { NSLocalizedString("MainMenu.personalVoice", bundle: .module, comment: "") }
    static var personalVoiceAccessDenied: String { NSLocalizedString("MainMenu.personalVoiceAccessDenied", bundle: .module, comment: "") }
    static var personalVoiceAccessExplanation: String { NSLocalizedString("MainMenu.personalVoiceAccessExplanation", bundle: .module, comment: "") }
    static var personalVoiceHelp: String { NSLocalizedString("MainMenu.personalVoiceHelp", bundle: .module, comment: "") }
    static var personalVoiceSelectedNotice: String { NSLocalizedString("MainMenu.personalVoiceSelectedNotice", bundle: .module, comment: "") }
    static var personalVoiceSettingsHelp: String { NSLocalizedString("MainMenu.personalVoiceSettingsHelp", bundle: .module, comment: "") }
    static var personalVoiceUnsupported: String { NSLocalizedString("MainMenu.personalVoiceUnsupported", bundle: .module, comment: "") }
    static var premiumVoiceNotice: String { NSLocalizedString("MainMenu.premiumVoiceNotice", bundle: .module, comment: "") }
    static var premiumVoices: String { NSLocalizedString("MainMenu.premiumVoices", bundle: .module, comment: "") }
    static func previewVoice(_ value: String) -> String { String(format: NSLocalizedString("MainMenu.previewVoice", bundle: .module, comment: ""), value) }
    static var standardVoiceNotice: String { NSLocalizedString("MainMenu.standardVoiceNotice", bundle: .module, comment: "") }
    static var voiceLanguage: String { NSLocalizedString("MainMenu.voiceLanguage", bundle: .module, comment: "") }
}
