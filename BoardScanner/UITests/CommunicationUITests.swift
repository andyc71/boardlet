import XCTest

final class CommunicationUITests: XCTestCase {
    @MainActor
    func testImportedHomeAndKeyboardIgnoreHistoricalPageReferences() throws {
        continueAfterFailure = false
        let url = try SnapTestFixture.make(extraSQL: SnapTestFixture.roleCommandsSQL + """
        DELETE FROM ButtonPageLink WHERE PageUniqueId='missing';
        """)
        defer { try? FileManager.default.removeItem(at: url) }
        let libraryID = UUID().uuidString
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--fresh-start", "--library-id", libraryID,
                               "--import-test-document", url.path]
        app.launch()
        app.setWindowOrientation(.portrait)
        for pass in 0..<2 {
            XCTAssertTrue(app.buttons["snapButton_1"].waitForExistence(timeout: 20))
            app.tapBoardControl("toggleEditing")
            let warning = app.buttons["snapImportWarning"]
            XCTAssertTrue(warning.exists)
            XCTAssertFalse(warning.label.contains("links"), warning.label)
            warning.tap()
            XCTAssertTrue(app.staticTexts["snapNavigationSummary"].waitForExistence(timeout: 5))
            XCTAssertEqual(app.staticTexts["snapNavigationSummary"].label, "0 page links have unavailable destinations.")
            app.buttons["Done"].tap()
            app.tapBoardControl("toggleEditing")
            app.buttons["snapButton_1"].tap()
            XCTAssertEqual(app.staticTexts["snapPageTitle"].label, "Child")
            app.buttons["snapButton_4"].tap()
            XCTAssertEqual(app.staticTexts["snapPageTitle"].label, "Home")
            app.buttons["snapButton_5"].tap()
            let field = app.textViews["typedMessage"].exists ? app.textViews["typedMessage"] : app.textFields["typedMessage"]
            XCTAssertTrue(field.waitForExistence(timeout: 5))
            field.tap()
            field.typeText("I want water")
            app.buttons["Add"].tap()
            XCTAssertEqual(app.otherElements["communicationMessage"].value as? String, "I want water")
            if pass == 0 {
                app.terminate()
                app.launchArguments = ["--ui-testing", "--library-id", libraryID]
                app.launch()
            }
        }
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Imported role commands after relaunch"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    @MainActor
    func testScreenshotCommunicationAndEditingAreSeparate() {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--fresh-start"]
        app.launch()
        app.buttons["sampleBoard"].tap()
        let card = app.buttons["card_0_0"]
        XCTAssertTrue(card.waitForExistence(timeout: 45))
        card.tap()
        let message = app.otherElements["communicationMessage"]
        XCTAssertEqual(message.value as? String, "Water")
        card.tap()
        XCTAssertEqual(message.value as? String, "Water Water")
        app.buttons["undoMessage"].tap()
        XCTAssertEqual(message.value as? String, "Water")
        XCTAssertTrue(app.buttons["speakMessage"].isEnabled)
        app.buttons["speakMessage"].tap()
        app.buttons["clearMessage"].tap()
        XCTAssertEqual(message.value as? String, "Empty")
        XCTAssertFalse(app.buttons["speakMessage"].isEnabled)
        app.buttons["typeMessage"].tap()
        let field = app.textViews["typedMessage"].exists ? app.textViews["typedMessage"] : app.textFields["typedMessage"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("I need help")
        app.buttons["Add"].tap()
        XCTAssertEqual(message.value as? String, "I need help")
        app.tapBoardControl("toggleEditing")
        card.tap()
        XCTAssertTrue(app.buttons["saveCard"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()
        app.tapBoardControl("toggleEditing")
        XCTAssertEqual(message.value as? String, "I need help")
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "AAC screenshot board and message strip"
        shot.lifetime = .keepAlways
        add(shot)
    }

    @MainActor
    func testSnapMessagePersistsAcrossPageNavigation() throws {
        let url = try SnapTestFixture.make(extraSQL: """
        INSERT INTO Button VALUES(4,40,'Drink','I want a drink',0,0);
        INSERT INTO ElementPlacement VALUES(5,40,'1,0','1,1',1,3);
        """)
        defer { try? FileManager.default.removeItem(at: url) }
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--fresh-start", "--import-test-document", url.path]
        app.launch()
        XCTAssertTrue(app.buttons["snapButton_1"].waitForExistence(timeout: 20))
        app.buttons["snapButton_1"].tap()
        let message = app.otherElements["communicationMessage"]
        XCTAssertEqual(message.value as? String, "Empty")
        app.buttons["snapButton_4"].tap()
        XCTAssertEqual(message.value as? String, "I want a drink")
        app.buttons["pageHome"].tap()
        XCTAssertEqual(app.staticTexts["snapPageTitle"].label, "Home")
        XCTAssertEqual(message.value as? String, "I want a drink")
        app.buttons["snapButton_1"].tap()
        app.buttons["snapButton_4"].tap()
        XCTAssertEqual(message.value as? String, "I want a drink I want a drink")
    }
    @MainActor
    func testCustomSpokenMessageSurvivesSaveAndRelaunch() throws {
        let url = try SnapTestFixture.make(extraSQL: """
        INSERT INTO Button VALUES(4,40,'Drink','',0,0);
        INSERT INTO ElementPlacement VALUES(5,40,'1,0','1,1',1,3);
        """)
        defer { try? FileManager.default.removeItem(at: url) }
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--fresh-start", "--import-test-document", url.path]
        app.launch()
        XCTAssertTrue(app.buttons["snapButton_1"].waitForExistence(timeout: 20))
        app.buttons["snapButton_1"].tap()
        app.tapBoardControl("toggleEditing")
        app.buttons["snapButton_4"].tap()
        let field = app.textFields["snapEditMessage"].exists ? app.textFields["snapEditMessage"] : app.textViews["snapEditMessage"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("Please bring water")
        app.buttons["saveSnapButton"].tap()
        XCTAssertTrue(app.staticTexts["Button updated · Saved"].waitForExistence(timeout: 5))
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Saved on this device"].waitForExistence(timeout: 10))
        app.terminate()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        XCTAssertTrue(app.buttons["snapButton_1"].waitForExistence(timeout: 20))
        app.buttons["snapButton_1"].tap()
        app.buttons["snapButton_4"].tap()
        XCTAssertEqual(app.otherElements["communicationMessage"].value as? String, "Please bring water")
        XCTAssertEqual(app.buttons["snapButton_4"].label, "Drink")
    }

}
