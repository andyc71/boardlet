import XCTest
import EngagementKit
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
        let startup = StartupExperience(defaults: defaults)
        startup.prepare(documents: documents)
        XCTAssertEqual(startup.screen, .welcome)
        // Starter boards created after preparation must not turn this into an existing user.
        try FileManager.default.createDirectory(at: documents.appendingPathComponent("topics"), withIntermediateDirectories: true)
        startup.prepare(documents: documents)
        XCTAssertEqual(startup.screen, .welcome)
    }

    func testBothChoicesPersistAndFinishWelcome() {
        for style in InterfaceStyle.allCases {
            let startup = StartupExperience(defaults: defaults)
            startup.finishWelcome(style: style)
            XCTAssertEqual(defaults.string(forKey: InterfaceStyle.storageKey), (InterfaceStyle.canChange ? style : .classic).rawValue)
            XCTAssertEqual(startup.screen, .content)
        }
    }

    func testWelcomeUsesEditionDefaults() {
        defaults.set(InterfaceStyle.classic.rawValue, forKey: InterfaceStyle.storageKey)
        defaults.set(PageLayoutMedium.paper.rawValue, forKey: PageLayoutMedium.storageKey)
        let startup = StartupExperience(defaults: defaults)
        startup.finishWelcome()
        XCTAssertEqual(defaults.string(forKey: InterfaceStyle.storageKey), InterfaceStyle.defaultValue.rawValue)
        XCTAssertEqual(PageLayoutMedium.preferred(in: defaults), InterfaceStyle.canChange ? .screen : .paper)
        XCTAssertEqual(startup.screen, .content)
    }

    func testWelcomeCanBeRequestedAgainWithoutClearingPreferences() {
        let startup = StartupExperience(defaults: defaults)
        startup.finishWelcome(style: .classic)
        startup.requestWelcome()
        XCTAssertEqual(startup.screen, .welcome)
        XCTAssertEqual(defaults.string(forKey: InterfaceStyle.storageKey), InterfaceStyle.classic.rawValue)
        startup.finishWelcome()
        XCTAssertEqual(startup.screen, .content)
    }

    func testLayoutMediumUsesWelcomeChoiceAndRemembersOverride() {
        for style in InterfaceStyle.allCases {
            defaults.removeObject(forKey: PageLayoutMedium.storageKey)
            defaults.set(style.rawValue, forKey: InterfaceStyle.storageKey)
            XCTAssertEqual(PageLayoutMedium.preferred(in: defaults), (!InterfaceStyle.canChange || style == .classic) ? .paper : .screen)
            StartupExperience(defaults: defaults).finishWelcome(style: style)
            XCTAssertEqual(PageLayoutMedium.preferred(in: defaults), (!InterfaceStyle.canChange || style == .classic) ? .paper : .screen)
            let override: PageLayoutMedium = style == .classic ? .screen : .paper
            defaults.set(override.rawValue, forKey: PageLayoutMedium.storageKey)
            XCTAssertEqual(PageLayoutMedium.preferred(in: defaults), InterfaceStyle.canChange ? override : .paper)
        }
    }

    func testEditionPreferencesResetExistingStandardSettings() {
        defaults.set(InterfaceStyle.modern.rawValue, forKey: InterfaceStyle.storageKey)
        defaults.set(PageLayoutMedium.screen.rawValue, forKey: PageLayoutMedium.storageKey)
        StartupExperience(defaults: defaults).applyEditionPreferences()
        XCTAssertEqual(defaults.string(forKey: InterfaceStyle.storageKey), InterfaceStyle.defaultValue.rawValue)
        XCTAssertEqual(PageLayoutMedium.preferred(in: defaults), InterfaceStyle.canChange ? .screen : .paper)
    }

    func testExistingBoardsSkipWelcome() throws {
        try FileManager.default.createDirectory(at: documents.appendingPathComponent("topics"), withIntermediateDirectories: true)
        let startup = StartupExperience(defaults: defaults)
        startup.prepare(documents: documents)
        XCTAssertEqual(startup.screen, .content)
    }

    func testExistingSettingsSkipWelcomeEvenWithEmptyLibrary() {
        defaults.set(Date(), forKey: StartupExperience.legacyWhatsNewKey)
        let startup = StartupExperience(defaults: defaults)
        startup.prepare(documents: documents)
        XCTAssertEqual(startup.screen, .content)
        XCTAssertEqual(StartupExperience(defaults: defaults).screen, .content)
    }

    @MainActor
    func testReleaseNotesAvailableInBothLanguages() {
        for locale in ["en", "es", "es_ES", "unavailable"] {
            let model = WhatsNewViewModel(locale: locale, fileNamePrefix: "WhatsNew", defaults: defaults)
            XCTAssertNil(model.lastError)
            XCTAssertFalse(model.showWhatsNewScreen)
        }
    }
}
