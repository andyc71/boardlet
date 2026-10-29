import XCTest

final class BoardLibraryUITests: XCTestCase {
    @MainActor
    func testAutosaveSwitchRenameDuplicateDeleteAndRestore() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let first = try SnapTestFixture.make(extraSQL: """
        UPDATE PageSetProperties SET FriendlyName='First board';
        INSERT INTO Button VALUES(4,40,'Drink','',0,0);
        INSERT INTO ElementPlacement VALUES(5,40,'2,0','1,1',1,2);
        """)
        let second = try SnapTestFixture.make(extraSQL: "UPDATE PageSetProperties SET FriendlyName='Second board';")
        defer {
            try? FileManager.default.removeItem(at: first)
            try? FileManager.default.removeItem(at: second)
        }
        let libraryID = UUID().uuidString
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--fresh-start", "--library-id", libraryID, "--import-test-document", first.path]
        app.launch()
        XCTAssertTrue(app.buttons["snapButton_4"].waitForExistence(timeout: 20))
        app.tapBoardControl("toggleEditing")
        app.buttons["snapButton_4"].tap()
        let field = app.textFields["snapEditMessage"].exists ? app.textFields["snapEditMessage"] : app.textViews["snapEditMessage"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("Please bring water")
        app.buttons["saveSnapButton"].tap()
        XCTAssertTrue(app.staticTexts["Button updated · Saved"].waitForExistence(timeout: 10))
        // No manual Save: the edited board must already be durable before the next import.
        app.terminate()
        app.launchArguments = ["--ui-testing", "--library-id", libraryID, "--import-test-document", second.path]
        app.launch()
        XCTAssertTrue(app.buttons["snapButton_1"].waitForExistence(timeout: 20))
        app.tapBoardControl("boardLibrary")
        XCTAssertTrue(app.buttons["libraryBoard_First board"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["libraryBoard_Second board"].exists)
        app.buttons["manageBoard_First board"].tap()
        app.buttons["Rename"].tap()
        let name = app.alerts["Rename board"].textFields["Board name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "First board".count) + "Meals")
        let enteredName = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", "Meals"), object: name)
        XCTAssertEqual(XCTWaiter.wait(for: [enteredName], timeout: 5), .completed)
        // Resolve the current centre after typing moves the alert above the keyboard.
        app.alerts["Rename board"].buttons["Rename"]
            .coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["libraryBoard_Meals"].waitForExistence(timeout: 10))
        app.buttons["manageBoard_Meals"].tap()
        app.buttons["Duplicate"].tap()
        XCTAssertTrue(app.buttons["libraryBoard_Meals copy"].waitForExistence(timeout: 10))
        app.buttons["manageBoard_Meals"].tap()
        app.buttons["Delete"].tap()
        app.buttons["Delete board"].tap()
        XCTAssertTrue(app.buttons["restoreBoard_Meals"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["libraryBoard_Meals"].exists)
        app.buttons["restoreBoard_Meals"].tap()
        XCTAssertTrue(app.buttons["libraryBoard_Meals"].waitForExistence(timeout: 10))
        app.buttons["libraryBoard_Meals copy"].tap()
        XCTAssertTrue(app.buttons["snapButton_4"].waitForExistence(timeout: 10))
        app.buttons["snapButton_4"].tap()
        XCTAssertEqual(app.otherElements["communicationMessage"].value as? String, "Please bring water")
        app.terminate()
        app.launchArguments = ["--ui-testing", "--library-id", libraryID]
        app.launch()
        XCTAssertTrue(app.buttons["snapButton_4"].waitForExistence(timeout: 10))
        app.buttons["snapButton_4"].tap()
        XCTAssertEqual(app.otherElements["communicationMessage"].value as? String, "Please bring water")
        app.tapBoardControl("boardLibrary")
        XCTAssertTrue(app.buttons["libraryBoard_Meals copy"].waitForExistence(timeout: 5))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Persistent AAC board library"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
