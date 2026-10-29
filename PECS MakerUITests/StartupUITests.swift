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
        checkWelcome(choice: "blankBoard", destination: "NoPhotosView.tipView")
    }

    func testMissingDefaultTitleTableRecoversAfterSpanishRelaunch() throws {
        let library = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: library, withIntermediateDirectories: true)
        defer { app.terminate(); try? FileManager.default.removeItem(at: library) }
        app.launchArguments += [LaunchArguments.noWhatsNew, "-mfDocDoc:\(library.path)",
                                "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchEnvironment["PECS_TEST_STARTUP"] = "skip"
        app.launchEnvironment["PECS_TEST_INTERFACE"] = "default"
        app.launch()
        XCTAssertTrue(app.buttons["NoPhotosView.addPhotosButton"].waitForExistence(timeout: 15))
        app.terminate()
        let topics = library.appendingPathComponent("topics")
        let board = try XCTUnwrap(FileManager.default.contentsOfDirectory(at: topics, includingPropertiesForKeys: nil)
            .first { FileManager.default.fileExists(atPath: $0.appendingPathComponent("index.json").path) })
        let filename = "strings-b692830a747a74b24f30b9334740e12200231ae7ead7bc9ae3b1c6739db84c34.json"
        let table = board.appendingPathComponent("locales/en/" + filename)
        let original = try Data(contentsOf: table)
        try FileManager.default.removeItem(at: table)
        app.launchArguments = app.launchArguments.map { $0 == "(en)" ? "(es)" : ($0 == "en_US" ? "es_ES" : $0) }
        app.launch()
        XCTAssertTrue(app.buttons["NoPhotosView.addPhotosButton"].waitForExistence(timeout: 15))
        XCTAssertEqual(try Data(contentsOf: table), original)
        app.buttons["BoardHierarchy.home"].tap()
        XCTAssertTrue(app.buttons["TopicSelectionView.TopicButton.0"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", filename)).firstMatch.exists)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Recovered missing default title in Spanish"
        screenshot.lifetime = .keepAlways
        add(screenshot)
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

extension StartupUITests {
    func testAppLanguageRoundTripPreservesSpanishCardEdit() throws {
        let library = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {
            app.terminate()
            try? FileManager.default.removeItem(at: library)
        }
        let bundle = Bundle(for: StartupUITests.self)
        let source = try XCTUnwrap(bundle.url(forResource: "StarterBoards", withExtension: nil))
        let names = try JSONDecoder().decode([String].self, from: Data(contentsOf: source.appendingPathComponent("order.json")))
        let name = try XCTUnwrap(names.first)
        let topics = library.appendingPathComponent("topics")
        try FileManager.default.createDirectory(at: topics, withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: source.appendingPathComponent("topics").appendingPathComponent(name),
                                         to: topics.appendingPathComponent(name))
        app.launchEnvironment["PECS_TEST_STARTUP"] = "skip"
        app.launchEnvironment["PECS_TEST_INTERFACE"] = "default"

        func openCard(language: String) {
            app.terminate()
            app.launchArguments = ["-mfNoAnalytics", "-mfNoRatings", "-mfNoFeatureVoting", "-mfLightMode",
                                   "-mfDocDoc:\(library.path)", "-AppleLanguages", "(\(language))",
                                   "-AppleLocale", language == "es" ? "es_ES" : "en_GB"]
            app.launch()
            let board = app.buttons["TopicSelectionView.TopicButton.0"]
            if board.waitForExistence(timeout: 5) { board.tap() }
            let card = app.buttons[A12SSUI.PhotoCell.image(for: 0)]
            XCTAssertTrue(card.waitForExistence(timeout: 10), app.debugDescription)
            card.tap()
            XCTAssertTrue(app.textFields[AccessibilityIdentifiers.PhotoZoomView.titleField].waitForExistence(timeout: 5))
        }

        openCard(language: "en")
        XCTAssertEqual(app.textFields[AccessibilityIdentifiers.PhotoZoomView.titleField].value as? String, "Hello")
        app.buttons[AccessibilityIdentifiers.PhotoZoomView.cancelButton].tap()
        openCard(language: "es")
        let field = app.textFields[AccessibilityIdentifiers.PhotoZoomView.titleField]
        XCTAssertEqual(field.value as? String, "Hola")
        field.tap()
        field.clearText()
        field.typeText("Mi saludo")
        app.buttons[AccessibilityIdentifiers.PhotoZoomView.saveButton].tap()
        openCard(language: "en")
        XCTAssertEqual(field.value as? String, "Hello")
        app.buttons[AccessibilityIdentifiers.PhotoZoomView.cancelButton].tap()
        openCard(language: "es")
        XCTAssertEqual(field.value as? String, "Mi saludo")
    }
}

extension StartupUITests {
    func testStarterRestoreThroughSymlinkShowsAllBoardsAndRetainsImages() throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let realLibrary = root.appendingPathComponent("real")
        let linkedLibrary = root.appendingPathComponent("linked")
        try fm.createDirectory(at: realLibrary, withIntermediateDirectories: true)
        try fm.createSymbolicLink(at: linkedLibrary, withDestinationURL: realLibrary)
        defer {
            app.terminate()
            try? fm.removeItem(at: root)
        }
        app.launchArguments += ["-mfDocDoc:\(linkedLibrary.path)", "-AppleLanguages", "(en)", "-AppleLocale", "en_GB"]
        app.launchEnvironment["PECS_TEST_STARTUP"] = "new"
        app.launchEnvironment["PECS_TEST_INTERFACE"] = "default"
        app.launch()
        XCTAssertTrue(app.buttons["Welcome.readyMadeBoards"].waitForExistence(timeout: 10))
        tapReadyMadeBoards { 24 }
        let source = try XCTUnwrap(Bundle(for: StartupUITests.self).url(forResource: "StarterBoards", withExtension: nil))
        let names = try JSONDecoder().decode([String].self, from: Data(contentsOf: source.appendingPathComponent("order.json")))
        XCTAssertEqual(names.count, 24)
        for index in names.indices {
            XCTAssertTrue(app.buttons["TopicSelectionView.TopicButton.\(index)"].exists, names[index])
        }
        // Match the reported damaged-library state before using the Settings action.
        app.terminate()
        let topics = realLibrary.appendingPathComponent("topics")
        for name in names.dropFirst(2) {
            try fm.removeItem(at: topics.appendingPathComponent(name).appendingPathComponent("locales"))
        }
        app.launchEnvironment["PECS_TEST_STARTUP"] = "skip"
        app.launch()
        let menu = app.buttons["TopicSelectionView.menuButton"]
        XCTAssertTrue(menu.waitForExistence(timeout: 10), app.debugDescription)
        menu.tap()
        app.buttons["MainMenu.settingsButton"].tap()
        let addBoards = app.buttons["Settings.addDefaultBoards"]
        for _ in 0..<8 where !addBoards.isHittable { app.swipeUp() }
        XCTAssertTrue(addBoards.isHittable)
        addBoards.tap()
        let confirmation = app.alerts.firstMatch
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        confirmation.buttons["Add"].tap()
        let success = app.alerts.firstMatch
        XCTAssertTrue(success.staticTexts["22 boards added"].waitForExistence(timeout: 10))
        success.buttons["OK"].tap()
        XCTAssertTrue(app.buttons["TopicSelectionView.TopicButton.0"].waitForExistence(timeout: 10))
        for (index, name) in names.enumerated() {
            XCTAssertTrue(app.buttons["TopicSelectionView.TopicButton.\(index)"].exists, name)
            let directory = topics.appendingPathComponent(name)
            let document = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: directory.appendingPathComponent("index.json"))) as? [String: Any])
            let photos = try XCTUnwrap(document["photos"] as? [String: Any])
            let cards = try XCTUnwrap(photos["photoItems"] as? [[String: Any]])
            XCTAssertEqual(cards.count, 20)
            for card in cards {
                let image = try XCTUnwrap(card["imageFileName"] as? String)
                XCTAssertTrue(fm.fileExists(atPath: directory.appendingPathComponent(image).path), image)
            }
        }
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = "Restored Starter Boards"
        capture.lifetime = .keepAlways
        add(capture)
    }
}
