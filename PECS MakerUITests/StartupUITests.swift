import XCTest

@MainActor
final class StartupUITests: XCTestCase {
    private let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app.launchArguments = ["-mfNoAnalytics", "-mfNoRatings", "-mfNoFeatureVoting", "-mfLightMode"]
    }

    override func tearDownWithError() throws { app.terminate() }

    func testReadyMadeWelcomeOpensCollectionAndPersistsAcrossLaunches() {
        checkWelcome(choice: "readyMadeBoards", destination: "TopicSelectionView.gridScrollView")
    }

    func testBlankWelcomeOpensEditorAndPersistsAcrossLaunches() {
        checkWelcome(choice: "blankBoard", destination: "NoPhotosView.addPhotosButton")
    }

    func testReadyMadeWelcomeAddsMissingBoardsWithoutDuplicatingThem() throws {
        // The explicit library bypasses automatic launch installation, reproducing
        // a library whose starter boards have not been added (or were removed).
        let library = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: library, withIntermediateDirectories: true)
        defer {
            app.terminate()
            try? FileManager.default.removeItem(at: library)
        }
        app.launchArguments.append("-mfDocDoc:\(library.path)")
        app.launchEnvironment["PECS_TEST_STARTUP"] = "new"
        app.launch()
        XCTAssertTrue(app.buttons["Welcome.readyMadeBoards"].waitForExistence(timeout: 10))
        let topics = library.appendingPathComponent("topics")
        let before = try FileManager.default.contentsOfDirectory(atPath: topics.path)
        XCTAssertFalse(before.contains { $0.hasPrefix("Greetings - ") })
        tapReadyMadeBoards {
            let after = try! FileManager.default.contentsOfDirectory(atPath: topics.path)
            return after.count - before.count
        }
        let firstBoard = app.buttons["TopicSelectionView.TopicButton.0"]
        XCTAssertTrue(firstBoard.waitForExistence(timeout: 10))
        XCTAssertEqual(firstBoard.label, "Greetings")
        let installed = try FileManager.default.contentsOfDirectory(atPath: topics.path)
        XCTAssertGreaterThan(installed.count, before.count)

        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["Welcome.readyMadeBoards"].waitForExistence(timeout: 10))
        tapReadyMadeBoards { 0 }
        XCTAssertTrue(firstBoard.waitForExistence(timeout: 10))
        XCTAssertEqual(Set(try FileManager.default.contentsOfDirectory(atPath: topics.path)), Set(installed))
    }

    func testSettingsCanShowWelcomeAgainAndKeepBoards() {
        checkWelcome(choice: "readyMadeBoards", destination: "TopicSelectionView.gridScrollView")
        let firstBoard = app.buttons["TopicSelectionView.TopicButton.0"]
        let firstBoardName = firstBoard.label
        app.buttons["TopicSelectionView.menuButton"].tap()
        app.buttons["MainMenu.settingsButton"].tap()
        let showWelcome = app.buttons["Settings.showWelcome"]
        for _ in 0..<4 where !showWelcome.isHittable { app.swipeUp() }
        XCTAssertTrue(showWelcome.isHittable)
        showWelcome.tap()
        XCTAssertTrue(app.staticTexts["Welcome.title"].waitForExistence(timeout: 5))
        tapReadyMadeBoards()
        XCTAssertTrue(firstBoard.waitForExistence(timeout: 10))
        XCTAssertEqual(firstBoard.label, firstBoardName)
    }

    private func tapReadyMadeBoards(expectedCount: (() -> Int)? = nil) {
        app.buttons["Welcome.readyMadeBoards"].tap()
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 10))
        XCTAssertTrue(alert.staticTexts["Tap a board to edit it."].exists)
        if let count = expectedCount?() {
            XCTAssertTrue(alert.staticTexts[count == 1 ? "1 board added" : "\(count) boards added"].exists)
        }
        alert.buttons["OK"].tap()
    }

    private func checkWelcome(choice: String, destination: String) {
        app.launchEnvironment["PECS_TEST_STARTUP"] = "new"
        app.launch()
        XCTAssertTrue(app.staticTexts["Welcome.title"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["FeaturesView.title"].exists)
        XCTAssertFalse(app.buttons["Welcome.screen"].exists)
        XCTAssertFalse(app.buttons["Welcome.paper"].exists)
        XCTAssertTrue(app.buttons["Welcome.readyMadeBoards"].isHittable)
        XCTAssertTrue(app.buttons["Welcome.blankBoard"].isHittable)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Welcome-\(choice)"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        if choice == "readyMadeBoards" { tapReadyMadeBoards() }
        else { app.buttons["Welcome.\(choice)"].tap() }
        XCTAssertTrue(app.staticTexts["Welcome.title"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)[destination].waitForExistence(timeout: 10))
        if choice == "readyMadeBoards" {
            XCTAssertTrue(app.buttons["TopicSelectionView.TopicButton.0"].waitForExistence(timeout: 5))
        }
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "PECS_TEST_STARTUP")
        app.launch()
        XCTAssertFalse(app.staticTexts["Welcome.title"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["FeaturesView.title"].exists)
        XCTAssertTrue(app.descendants(matching: .any)[destination].waitForExistence(timeout: 10))
    }

    func testExistingUserSeesReleaseNotesOnce() {
        app.launchEnvironment["PECS_TEST_STARTUP"] = "existing"
        app.launch()
        XCTAssertTrue(app.staticTexts["FeaturesView.title"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["Welcome.title"].exists)
        app.buttons["FeaturesView.closeButton"].tap()
        XCTAssertTrue(app.staticTexts["FeaturesView.title"].waitForNonExistence(timeout: 5))
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "PECS_TEST_STARTUP")
        app.launch()
        XCTAssertFalse(app.staticTexts["FeaturesView.title"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Welcome.title"].exists)
    }
}
