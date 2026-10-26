import Foundation

/// Decides startup before starter boards or repository initialization can make a new install look used.
struct StartupExperience {
    enum Screen { case welcome, whatsNew, content }
    enum StartingPoint { case readyMadeBoards, blankBoard }

    static let welcomeRequiredKey = "startup.welcomeRequired"
    static let lastSeenVersionKey = "startup.lastSeenVersion"
    static let legacyWhatsNewKey = "com.brightblue.WhatsNewManager.lastDisplayedFeatureSet"

    let defaults: UserDefaults
    let version: String

    init(defaults: UserDefaults = .standard,
         version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1") {
        self.defaults = defaults
        self.version = version
    }

    func prepare(documents: URL) {
        guard defaults.object(forKey: Self.welcomeRequiredKey) == nil else { return }
        let previousSettings = [Self.lastSeenVersionKey, Self.legacyWhatsNewKey, InterfaceStyle.storageKey,
                                "RepoFactory.currentTopicDir", "appMode", "PECSRepoFactory.topicOrder"]
            .contains { defaults.object(forKey: $0) != nil }
        let previousFiles = ["topics", ".starter-boards-v1.json", "FamilyIndex.plist", "FamilyIndex.json"]
            .contains { FileManager.default.fileExists(atPath: documents.appendingPathComponent($0).path) }
        defaults.set(!(previousSettings || previousFiles), forKey: Self.welcomeRequiredKey)
    }

    var screen: Screen {
        if defaults.bool(forKey: Self.welcomeRequiredKey) { return .welcome }
        return defaults.string(forKey: Self.lastSeenVersionKey) == version ? .content : .whatsNew
    }

    func requestWelcome() {
        defaults.set(true, forKey: Self.welcomeRequiredKey)
    }

    /// Apply the Standard edition's fixed settings to existing installations too.
    func applyEditionPreferences() {
        guard !InterfaceStyle.canChange else { return }
        defaults.set(InterfaceStyle.classic.rawValue, forKey: InterfaceStyle.storageKey)
        defaults.set(PageLayoutMedium.paper.rawValue, forKey: PageLayoutMedium.storageKey)
    }

    func finishWelcome(style: InterfaceStyle = InterfaceStyle.defaultValue) {
        let style = InterfaceStyle.canChange ? style : .classic
        defaults.set(style.rawValue, forKey: InterfaceStyle.storageKey)
        defaults.set((style == .classic ? PageLayoutMedium.paper : .screen).rawValue,
                     forKey: PageLayoutMedium.storageKey)
        defaults.set(false, forKey: Self.welcomeRequiredKey)
        // New users start with the current experience; release notes are for subsequent updates.
        finishWhatsNew()
    }

    func finishWhatsNew() {
        defaults.set(version, forKey: Self.lastSeenVersionKey)
    }
}
