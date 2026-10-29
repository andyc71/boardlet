import XCTest

final class SpeechStripUITests: XCTestCase {
    @MainActor
    func testSharedVoicePickerSelectionAndPreview() throws {
        let input = try SnapTestFixture.make()
        defer { try? FileManager.default.removeItem(at: input) }
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--fresh-start", "--library-id", UUID().uuidString,
                               "--import-test-document", input.path]
        app.launch()
        app.setWindowOrientation(.portrait)
        XCTAssertTrue(app.buttons["boardOptions"].waitForExistence(timeout: 20))
        app.buttons["boardOptions"].tap()
        app.buttons["communicationSettings"].tap()
        let change = app.buttons["Change Voice"]
        for _ in 0..<6 where !change.isHittable { app.swipeUp() }
        XCTAssertTrue(change.waitForExistence(timeout: 5))
        change.tap()
        XCTAssertTrue(app.buttons["MainMenu.voiceLanguagePicker"].waitForExistence(timeout: 5))
        let defaultVoice = app.buttons["MainMenu.defaultVoiceButton"]
        defaultVoice.tap()
        XCTAssertTrue(defaultVoice.isSelected)
        app.buttons["MainMenu.defaultVoicePreviewButton"].tap()
        XCTAssertTrue(defaultVoice.isSelected)
        app.buttons["Done"].firstMatch.tap()
        XCTAssertTrue(change.waitForExistence(timeout: 5))
    }

    @MainActor
    func testCompactStripUsesHalfCardHeightAndFittingGridStaysInPlace() throws {
        continueAfterFailure = false
        let input = try SnapTestFixture.make(extraSQL: SnapTestFixture.roleCommandsSQL + """
        UPDATE PageSetProperties SET GridDimension='6,2';
        UPDATE PageLayout SET PageLayoutSetting='6,2,True,0' WHERE Id=2;
        """)
        defer {
            try? FileManager.default.removeItem(at: input)
            XCUIDevice.shared.orientation = .portrait
        }
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--fresh-start", "--library-id", UUID().uuidString,
                               "--import-test-document", input.path]
        app.launch()
        XCTAssertTrue(app.buttons["snapButton_5"].waitForExistence(timeout: 20))
        app.setWindowOrientation(.landscapeLeft)
        let card = app.buttons["snapButton_5"]
        let halfHeight = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            abs(app.buttons["speakMessage"].frame.height - card.frame.height * 2 / 3) < 1
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [halfHeight], timeout: 5), .completed)
        for identifier in ["speakMessage", "undoMessage", "clearMessage"] {
            XCTAssertEqual(app.buttons[identifier].frame.height, card.frame.height * 2 / 3, accuracy: 1)
            XCTAssertTrue(app.buttons[identifier].isHittable)
        }
        let message = app.descendants(matching: .any).matching(identifier: "communicationMessage").firstMatch
        XCTAssertEqual(message.frame.height, card.frame.height * 2 / 3, accuracy: 1)
        let grid = app.descendants(matching: .any).matching(identifier: "snapGrid").firstMatch
        let title = app.staticTexts["snapPageTitle"]
        XCTAssertTrue(title.exists)
        XCTAssertGreaterThan(title.frame.minX, app.buttons["clearMessage"].frame.maxX)
        XCTAssertFalse(app.buttons["boardOptions"].isHittable)
        XCTAssertFalse(app.staticTexts["Tap pictures…"].exists)
        XCTAssertEqual(app.buttons["speakMessage"].frame.width, card.frame.width * 2 / 3, accuracy: 1)
        let landscapeWidth = card.frame.width
        app.setWindowOrientation(.portrait)
        app.setWindowOrientation(.landscapeLeft)
        let restored = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            abs(card.frame.width - landscapeWidth) < 1
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [restored], timeout: 5), .completed)
        let before = card.frame
        grid.swipeLeft()
        XCTAssertEqual(card.frame.minX, before.minX, accuracy: 1)
        grid.swipeRight()
        XCTAssertEqual(card.frame.minX, before.minX, accuracy: 1)
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "Compact half-height speech strip"
        shot.lifetime = .keepAlways
        add(shot)
    }

    @MainActor
    func testSpeakCardSwitchesToStopAndKeyboardCardStillWorks() throws {
        continueAfterFailure = false
        let input = try SnapTestFixture.make(extraSQL: SnapTestFixture.roleCommandsSQL + """
        UPDATE PageSetProperties SET GridDimension='6,2';
        UPDATE PageLayout SET PageLayoutSetting='6,2,True,0' WHERE Id=2;
        """)
        defer { try? FileManager.default.removeItem(at: input) }
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--fresh-start", "--library-id", UUID().uuidString,
                               "--import-test-document", input.path]
        app.launch()
        app.setWindowOrientation(.portrait)
        XCTAssertTrue(app.buttons["snapButton_5"].waitForExistence(timeout: 20))
        XCTAssertFalse(app.buttons["editMessage"].exists)
        XCTAssertFalse(app.buttons["typeMessage"].exists)
        XCTAssertFalse(app.buttons["showPhrases"].exists)
        XCTAssertFalse(app.buttons["stopSpeech"].exists)
        let card = app.buttons["snapButton_5"]
        for identifier in ["speakMessage", "undoMessage", "clearMessage"] {
            let control = app.buttons[identifier]
            XCTAssertEqual(control.frame.width, card.frame.width, accuracy: 1)
            XCTAssertEqual(control.frame.height, card.frame.height, accuracy: 1)
            XCTAssertEqual(control.frame.minY, app.buttons["speakMessage"].frame.minY, accuracy: 1)
        }
        XCTAssertEqual(app.buttons["speakMessage"].frame.minX,
                       app.buttons["snapButton_1"].frame.minX, accuracy: 1)
        let message = app.descendants(matching: .any).matching(identifier: "communicationMessage").firstMatch
        XCTAssertLessThan(app.buttons["speakMessage"].frame.maxX, message.frame.minX)
        app.buttons["snapButton_5"].tap()
        let field = app.descendants(matching: .any).matching(identifier: "typedMessage").firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("I want to talk with you about what we can do together today. We could go to the park and have a picnic.")
        app.buttons["Add"].tap()
        XCTAssertTrue(app.buttons["stopSpeech"].waitForExistence(timeout: 5))
        app.buttons["stopSpeech"].tap()
        XCTAssertTrue(app.buttons["speakMessage"].waitForExistence(timeout: 5))
        app.buttons["speakMessage"].tap()
        XCTAssertTrue(app.buttons["stopSpeech"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["speakMessage"].exists)
        app.buttons["stopSpeech"].tap()
        XCTAssertTrue(app.buttons["speakMessage"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["stopSpeech"].exists)
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "Speak card before the message"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
