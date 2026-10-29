import XCTest
import EngagementKit

/// Integration tests for policy-driven, inline invitations. Navigation is not an engagement event.
@MainActor
final class FeatureVotingUITests: XCTestCase {
    private let app = XCUIApplication()
    private var library: URL!
    private var voteButton: XCUIElement { app.buttons[AccessibilityIdentifiersFF.votePromptVoteButton] }

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        library = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: library, withIntermediateDirectories: true)
        app.launchArguments = ["-mfNoAnalytics", "-mfNoRatings", "-mfNoWhatsNew", "-mfLightMode", "-mfDocDoc:\(library.path)", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchEnvironment["PECS_TEST_STARTUP"] = "skip"
        app.launchEnvironment["PECS_TEST_INTERFACE"] = "default"
    }

    override func tearDownWithError() throws {
        app.terminate()
        try FileManager.default.removeItem(at: library)
    }

    func testEligibleInvitationIsInlineAndDismissalSurvivesRelaunch() {
        launch("eligible")
        XCTAssertTrue(voteButton.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(app.scrollViews["TopicSelectionView.gridScrollView"].buttons[AccessibilityIdentifiersFF.votePromptVoteButton].exists)
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = "Engagement-inline-library-invitation"
        capture.lifetime = .keepAlways
        add(capture)
        app.buttons[AccessibilityIdentifiersFF.votePromptDismissButton].tap()
        assertNoInvitation()
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "PECS_TEST_ENGAGEMENT")
        app.launch()
        openLibrary()
        XCTAssertTrue(app.scrollViews["TopicSelectionView.gridScrollView"].waitForExistence(timeout: 10))
        assertNoInvitation()
    }

    func testFreshInstallNavigationDoesNotQualify() {
        launch("fresh")
        XCTAssertTrue(app.scrollViews["TopicSelectionView.gridScrollView"].waitForExistence(timeout: 10))
        for _ in 0..<3 {
            app.buttons["TopicSelectionView.menuButton"].tap()
            app.buttons["MainMenu.settingsButton"].tap()
            app.navigationBars.buttons.firstMatch.tap()
        }
        assertNoInvitation()
    }

    func testLegacyDismissalIsPreserved() {
        launch("legacyDismissed")
        XCTAssertTrue(app.scrollViews["TopicSelectionView.gridScrollView"].waitForExistence(timeout: 10))
        assertNoInvitation()
    }

    func testWhatsNewSuppressesSolicitationsAfterContinue() {
        app.launchArguments.removeAll { $0 == "-mfNoWhatsNew" }
        app.launchEnvironment["PECS_TEST_STARTUP"] = "existing"
        launch("eligible")
        let continueButton = app.buttons[AccessibilityIdentifiersFF.FeaturesView.closeButton]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 10))
        XCTAssertFalse(voteButton.exists)
        continueButton.tap()
        openLibrary()
        XCTAssertTrue(app.scrollViews["TopicSelectionView.gridScrollView"].waitForExistence(timeout: 10))
        assertNoInvitation()
    }

    func testUserInitiatedVotingRemainsAvailableOnFreshInstall() {
        launch("fresh")
        let menu = app.buttons["TopicSelectionView.menuButton"]
        XCTAssertTrue(menu.waitForExistence(timeout: 10))
        menu.tap()
        app.buttons["MainMenu.settingsButton"].tap()
        let explicitVote = app.buttons["Settings.voteForFeatures"]
        for _ in 0..<6 where !explicitVote.isHittable { app.swipeUp() }
        XCTAssertTrue(explicitVote.isHittable)
        explicitVote.tap()
        XCTAssertTrue(app.staticTexts[AccessibilityIdentifiersFF.FeaturesView.title].waitForExistence(timeout: 5))
        let feature = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@",
            AccessibilityIdentifiersFF.FeaturesView.featureCellPrefix + "-")).firstMatch
        XCTAssertTrue(feature.waitForExistence(timeout: 5))
        feature.tap()
        XCTAssertTrue(app.staticTexts["Thank you for voting"].waitForExistence(timeout: 5))
        assertNoInvitation()
    }

    private func launch(_ fixture: String) {
        app.launchEnvironment["PECS_TEST_ENGAGEMENT"] = fixture
        app.launch()
        if app.launchEnvironment["PECS_TEST_STARTUP"] != "existing" { openLibrary() }
    }

    private func openLibrary() {
        let grid = app.scrollViews["TopicSelectionView.gridScrollView"]
        if !grid.waitForExistence(timeout: 2) {
            let home = app.buttons["BoardHierarchy.home"]
            if home.exists {
                home.tap()
            } else {
                let back = app.navigationBars.buttons["chevron.left"]
                XCTAssertTrue(back.waitForExistence(timeout: 10), app.debugDescription)
                back.tap()
            }
        }
        XCTAssertTrue(grid.waitForExistence(timeout: 10), app.debugDescription)
    }

    private func assertNoInvitation() {
        let unexpected = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true"), object: voteButton)
        unexpected.isInverted = true
        XCTAssertEqual(XCTWaiter.wait(for: [unexpected], timeout: 2), .completed)
    }
}
