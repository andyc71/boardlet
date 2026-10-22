import XCTest
@testable import PECS_Maker

final class StartupExperienceTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suite: String!
    private var documents: URL!

    override func setUpWithError() throws {
        suite = "StartupTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)
        documents = FileManager.default.temporaryDirectory.appendingPathComponent(suite)
        try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        defaults.removePersistentDomain(forName: suite)
        try FileManager.default.removeItem(at: documents)
    }

    func testFreshInstallAndInterruptedWelcome() throws {
        let startup = StartupExperience(defaults: defaults, version: "4.0")
        startup.prepare(documents: documents)
        XCTAssertEqual(startup.screen, .welcome)
        // Starter boards created after preparation must not turn this into an existing user.
        try FileManager.default.createDirectory(at: documents.appendingPathComponent("topics"), withIntermediateDirectories: true)
        startup.prepare(documents: documents)
        XCTAssertEqual(startup.screen, .welcome)
    }

    func testBothChoicesPersistAndSkipCurrentReleaseNotes() {
        for style in InterfaceStyle.allCases {
            let startup = StartupExperience(defaults: defaults, version: "4.0")
            startup.finishWelcome(style: style)
            XCTAssertEqual(defaults.string(forKey: InterfaceStyle.storageKey), style.rawValue)
            XCTAssertEqual(startup.screen, .content)
            XCTAssertEqual(StartupExperience(defaults: defaults, version: "4.1").screen, .whatsNew)
        }
    }

    func testWelcomeDefaultsToScreenAndSkipsCurrentReleaseNotes() {
        defaults.set(InterfaceStyle.classic.rawValue, forKey: InterfaceStyle.storageKey)
        defaults.set(PageLayoutMedium.paper.rawValue, forKey: PageLayoutMedium.storageKey)
        let startup = StartupExperience(defaults: defaults, version: "4.0")
        startup.finishWelcome()
        XCTAssertEqual(defaults.string(forKey: InterfaceStyle.storageKey), InterfaceStyle.modern.rawValue)
        XCTAssertEqual(PageLayoutMedium.preferred(in: defaults), .screen)
        XCTAssertEqual(startup.screen, .content)
        XCTAssertEqual(StartupExperience(defaults: defaults, version: "4.1").screen, .whatsNew)
    }

    func testWelcomeCanBeRequestedAgainWithoutClearingPreferences() {
        let startup = StartupExperience(defaults: defaults, version: "4.0")
        startup.finishWelcome(style: .classic)
        startup.requestWelcome()
        XCTAssertEqual(startup.screen, .welcome)
        XCTAssertEqual(defaults.string(forKey: InterfaceStyle.storageKey), InterfaceStyle.classic.rawValue)
        XCTAssertEqual(defaults.string(forKey: StartupExperience.lastSeenVersionKey), "4.0")
        startup.finishWelcome()
        XCTAssertEqual(startup.screen, .content)
    }

    func testLayoutMediumUsesWelcomeChoiceAndRemembersOverride() {
        for style in InterfaceStyle.allCases {
            defaults.removeObject(forKey: PageLayoutMedium.storageKey)
            defaults.set(style.rawValue, forKey: InterfaceStyle.storageKey)
            XCTAssertEqual(PageLayoutMedium.preferred(in: defaults), style == .classic ? .paper : .screen)
            StartupExperience(defaults: defaults).finishWelcome(style: style)
            XCTAssertEqual(PageLayoutMedium.preferred(in: defaults), style == .classic ? .paper : .screen)
            let override: PageLayoutMedium = style == .classic ? .screen : .paper
            defaults.set(override.rawValue, forKey: PageLayoutMedium.storageKey)
            XCTAssertEqual(PageLayoutMedium.preferred(in: defaults), override)
        }
    }

    func testExistingBoardsSkipWelcome() throws {
        try FileManager.default.createDirectory(at: documents.appendingPathComponent("topics"), withIntermediateDirectories: true)
        let startup = StartupExperience(defaults: defaults, version: "4.0")
        startup.prepare(documents: documents)
        XCTAssertEqual(startup.screen, .whatsNew)
    }

    func testExistingSettingsSkipWelcomeEvenWithEmptyLibrary() {
        defaults.set(Date(), forKey: StartupExperience.legacyWhatsNewKey)
        let startup = StartupExperience(defaults: defaults, version: "4.0")
        startup.prepare(documents: documents)
        XCTAssertEqual(startup.screen, .whatsNew)
        startup.finishWhatsNew()
        XCTAssertEqual(StartupExperience(defaults: defaults, version: "4.0").screen, .content)
        XCTAssertEqual(StartupExperience(defaults: defaults, version: "4.1").screen, .whatsNew)
    }

    func testReleaseNotesAvailableInBothLanguages() {
        XCTAssertNotNil(ReleaseNotes.load(locale: "en"))
        XCTAssertNotNil(ReleaseNotes.load(locale: "es"))
        XCTAssertNotNil(ReleaseNotes.load(locale: "unavailable"))
    }
}
