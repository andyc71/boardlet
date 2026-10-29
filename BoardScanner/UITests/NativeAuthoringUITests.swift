import XCTest

final class NativeAuthoringUITests: XCTestCase {
    @MainActor
    func testFilesCancellationAndArtworkRemovalCommitOnlyOnSave() {
        continueAfterFailure = false
        let app = XCUIApplication()
        let library = UUID().uuidString
        app.launchArguments = ["--ui-testing", "--fresh-start", "--library-id", library, "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        app.setWindowOrientation(.landscapeLeft)
        app.setWindowOrientation(.portrait)
        XCTAssertTrue(app.buttons["createMenu"].isHittable, "The welcome screen's Create control must receive taps")
        app.buttons["createMenu"].tap()
        app.buttons["New board"].tap()
        app.textFields["newBoardName"].tap()
        app.textFields["newBoardName"].typeText("Artwork changes")
        app.buttons["createNativeBoard"].tap()
        XCTAssertTrue(app.staticTexts["Board created · Saved"].waitForExistence(timeout: 15))
        tile("Water", in: app).tap()
        XCTAssertTrue(app.images["buttonArtworkPreview"].waitForExistence(timeout: 5))
        app.buttons["chooseButtonArtwork"].tap()
        app.buttons["buttonArtworkFiles"].tap()
        let pickerBar = app.navigationBars["FullDocumentManagerViewControllerNavigationBar"]
        XCTAssertTrue(pickerBar.waitForExistence(timeout: 15))
        SystemPhotoPickerDriver(app: app).captureEvidence(named: "Files artwork picker before cancellation")
        let cancel = pickerBar.buttons["Cancel"].exists
            ? pickerBar.buttons["Cancel"] : app.navigationBars["DOCSidebarView"].buttons["Cancel"]
        cancel.tap()
        XCTAssertTrue(pickerBar.waitForNonExistence(timeout: 10))
        XCTAssertTrue(app.buttons["buttonArtworkFiles"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["artworkImportError"].exists, "Cancelling Files is not an import error")
        app.navigationBars["Choose picture"].buttons["Cancel"].tap()
        XCTAssertTrue(app.images["buttonArtworkPreview"].waitForExistence(timeout: 5))

        app.buttons["Remove picture"].tap()
        XCTAssertFalse(app.images["buttonArtworkPreview"].exists)
        app.navigationBars["Edit button"].buttons["Cancel"].tap()
        tile("Water", in: app).tap()
        XCTAssertTrue(app.images["buttonArtworkPreview"].waitForExistence(timeout: 5), "Cancelling an edit must preserve saved artwork")
        app.buttons["Remove picture"].tap()
        app.buttons["saveSnapButton"].tap()
        XCTAssertTrue(app.staticTexts["Button updated · Saved"].waitForExistence(timeout: 10))
        app.terminate()
        app.launchArguments = ["--ui-testing", "--library-id", library]
        app.launch()
        XCTAssertTrue(tile("Water", in: app).waitForExistence(timeout: 15))
        tile("Water", in: app).tap()
        XCTAssertEqual(app.otherElements["communicationMessage"].value as? String, "Water")
        app.tapBoardControl("toggleEditing")
        tile("Water", in: app).tap()
        XCTAssertTrue(app.buttons["chooseButtonArtwork"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.images["buttonArtworkPreview"].exists)
        XCTAssertFalse(app.buttons["Remove picture"].exists)
        SystemPhotoPickerDriver(app: app).captureEvidence(named: "Saved artwork removal after relaunch")
    }

    @MainActor
    func testCreatePagePictureLinkAndCommunicateAfterRelaunch() {
        continueAfterFailure = false
        let app = XCUIApplication()
        let library = UUID().uuidString
        app.launchArguments = ["--ui-testing", "--fresh-start", "--library-id", library]
        app.launch()
        // Normalize the running scene as well as the simulator device. Setting
        // orientation before launch can leave iPad sheets in the prior layout.
        app.setWindowOrientation(.landscapeLeft)
        app.setWindowOrientation(.portrait)
        app.buttons["createMenu"].tap()
        app.buttons["New board"].tap()
        app.textFields["newBoardName"].tap()
        app.textFields["newBoardName"].typeText("Daily talk")
        app.buttons["createNativeBoard"].tap()
        XCTAssertTrue(app.staticTexts["Board created · Saved"].waitForExistence(timeout: 15))
        XCTAssertEqual(app.buttons["toggleEditing"].label, "Communicate")
        app.buttons["pageOptions"].tap()
        app.buttons["Add page"].tap()
        app.textFields["pageName"].tap()
        app.textFields["pageName"].typeText("Drinks")
        app.buttons["savePage"].tap()
        XCTAssertTrue(app.staticTexts["Page added · Saved"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["snapPageTitle"].label, "Drinks")
        app.buttons["emptyCell_0_0"].tap()
        let label = field("snapEditLabel", in: app)
        label.tap(); label.typeText("Water please")
        let message = field("snapEditMessage", in: app)
        message.tap(); message.typeText("Please bring water")
        // The iPad keyboard resizes the sheet after typing; dismiss it before
        // querying the picture row so XCTest does not use its pre-resize frame.
        let hideKeyboard = app.buttons["Hide keyboard"]
        if hideKeyboard.waitForExistence(timeout: 5) && hideKeyboard.isHittable { hideKeyboard.tap() }
        app.buttons["chooseButtonArtwork"].tap()
        XCTAssertTrue(app.buttons["builtinSymbol_Water"].waitForExistence(timeout: 5))
        app.buttons["builtinSymbol_Water"].tap()
        XCTAssertTrue(app.images["buttonArtworkPreview"].waitForExistence(timeout: 5))
        app.buttons["saveSnapButton"].tap()
        XCTAssertTrue(app.staticTexts["Button updated · Saved"].waitForExistence(timeout: 10))
        app.buttons["pageHome"].tap()
        tile("Yes", in: app).tap()
        let action = app.buttons["buttonAction"]
        for _ in 0..<3 {
            if action.exists && action.isHittable { break }
            app.collectionViews.firstMatch.swipeUp()
        }
        action.tap()
        app.buttons["Open page"].tap()
        let destination = app.buttons["buttonDestination"]
        for _ in 0..<4 {
            if destination.exists && destination.isHittable { break }
            app.collectionViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(destination.waitForExistence(timeout: 5))
        destination.tap()
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'snapPage_' AND label CONTAINS 'Drinks'")).firstMatch.tap()
        app.buttons["saveSnapButton"].tap()
        XCTAssertTrue(app.staticTexts["Button updated · Saved"].waitForExistence(timeout: 10))
        app.terminate()
        app.launchArguments = ["--ui-testing", "--library-id", library]
        app.launch()
        XCTAssertTrue(tile("Yes", in: app).waitForExistence(timeout: 15))
        XCTAssertTrue(tile("Yes", in: app).isHittable, "The editor toolbar must not block communication after relaunch")
        tile("Yes", in: app).tap()
        XCTAssertEqual(app.staticTexts["snapPageTitle"].label, "Drinks")
        XCTAssertEqual(app.otherElements["communicationMessage"].value as? String, "Empty")
        tile("Water please", in: app).tap()
        XCTAssertEqual(app.otherElements["communicationMessage"].value as? String, "Please bring water")
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Authored page and spoken message"
        shot.lifetime = .keepAlways
        add(shot)
        app.tapBoardControl("toggleEditing")
        tile("Water please", in: app).tap()
        XCTAssertTrue(app.images["buttonArtworkPreview"].waitForExistence(timeout: 5))
    }

    @MainActor private func tile(_ label: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'snapButton_' AND label == %@", label)).firstMatch
    }
    @MainActor private func field(_ id: String, in app: XCUIApplication) -> XCUIElement {
        app.textFields[id].exists ? app.textFields[id] : app.textViews[id]
    }
}
