import XCTest

final class PhraseCommunicationUITests: XCTestCase {
    @MainActor
    func testCorrectSaveRecallAndReusePhraseAfterRelaunch() {
        continueAfterFailure = false
        let app = XCUIApplication()
        let libraryID = UUID().uuidString
        app.launchArguments = ["--ui-testing", "--fresh-start", "--library-id", libraryID]
        app.launch()
        XCUIDevice.shared.orientation = .landscapeLeft
        XCUIDevice.shared.orientation = .portrait
        app.buttons["createMenu"].tap()
        app.buttons["New board"].tap()
        app.textFields["newBoardName"].tap()
        app.textFields["newBoardName"].typeText("Conversation")
        app.buttons["createNativeBoard"].tap()
        XCTAssertTrue(app.staticTexts["Board created · Saved"].waitForExistence(timeout: 10))
        app.tapBoardControl("toggleEditing")
        tile("Yes", app).tap()
        tile("No", app).tap()
        let message = app.otherElements["communicationMessage"]
        XCTAssertEqual(message.value as? String, "Yes No")
        app.buttons["editMessage"].tap()
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'messageToken_' AND label == 'Yes'")).firstMatch.tap()
        XCTAssertTrue(app.buttons["clearCorrectedWords"].waitForExistence(timeout: 5))
        app.buttons["clearCorrectedWords"].tap()
        let corrected = field("correctedWords", app)
        corrected.tap(); corrected.typeText("Please")
        app.buttons["applyCorrectedWords"].tap()
        app.buttons["Done"].tap()
        XCTAssertEqual(message.value as? String, "Please No")
        XCTAssertEqual(tile("Yes", app).label, "Yes", "Correcting the sentence must leave board vocabulary intact")
        app.buttons["showPhrases"].tap()
        app.buttons["saveCurrentPhrase"].tap()
        app.textFields["phraseTitle"].tap()
        app.textFields["phraseTitle"].typeText("My request")
        app.buttons["savePhrase"].tap()
        findRequest(app)
        // Compact iPhone search hides the navigation toolbar until search closes.
        if !app.buttons["Done"].exists { app.buttons["close"].tap() }
        app.buttons["Done"].tap()
        app.buttons["clearMessage"].tap()
        app.buttons["editMessage"].tap()
        app.buttons["reuseLastMessage"].tap()
        app.buttons["Done"].tap()
        XCTAssertEqual(message.value as? String, "Please No")
        app.terminate()
        app.launchArguments = ["--ui-testing", "--library-id", libraryID]
        app.launch()
        XCTAssertTrue(app.buttons["showPhrases"].waitForExistence(timeout: 15))
        XCTAssertEqual(message.value as? String, "Empty", "A permanent conversation history must not be restored")
        app.buttons["showPhrases"].tap()
        findRequest(app)
        phrase("My request", app).tap()
        XCTAssertEqual(message.value as? String, "Please No")
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Reusable phrase in message composer"
        shot.lifetime = .keepAlways
        add(shot)
        app.buttons["showPhrases"].tap()
        findRequest(app)
        app.buttons["Options for My request"].tap()
        app.buttons["Delete phrase"].tap()
        app.alerts.buttons["Delete"].tap()
        XCTAssertFalse(phrase("My request", app).exists)
        app.buttons["Undo phrase deletion"].tap()
        XCTAssertTrue(phrase("My request", app).exists)
    }

    @MainActor private func findRequest(_ app: XCUIApplication) {
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("My request\n")
        XCTAssertTrue(phrase("My request", app).waitForExistence(timeout: 5))
    }

    @MainActor private func tile(_ label: String, _ app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'snapButton_' AND label == %@", label)).firstMatch
    }
    @MainActor private func phrase(_ label: String, _ app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'phrase_' AND label == %@", label)).firstMatch
    }
    @MainActor private func field(_ id: String, _ app: XCUIApplication) -> XCUIElement {
        app.textFields[id].exists ? app.textFields[id] : app.textViews[id]
    }
}
