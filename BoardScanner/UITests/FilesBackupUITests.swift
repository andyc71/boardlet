import XCTest

/// Opt-in native Files journey. Creates only a uniquely named local test backup.
@MainActor
final class FilesBackupUITests: XCTestCase {
  func testExportAndRestoreIntoSeparateLibrary() throws {
    continueAfterFailure = false
    let title = "BoardScanner-Backup-" + UUID().uuidString
    let app = XCUIApplication()
    launch(app, library: UUID().uuidString, fresh: true)
    XCUIDevice.shared.orientation = .landscapeLeft
    XCUIDevice.shared.orientation = .portrait
    app.buttons["createMenu"].tap()
    app.buttons["New board"].tap()
    app.textFields["newBoardName"].tap()
    app.textFields["newBoardName"].typeText(title)
    app.buttons["createNativeBoard"].tap()
    XCTAssertTrue(app.staticTexts["Board created · Saved"].waitForExistence(timeout: 15))
    app.buttons["pageOptions"].tap()
    app.buttons["Add page"].tap()
    app.textFields["pageName"].tap()
    app.textFields["pageName"].typeText("Drinks")
    app.buttons["savePage"].tap()
    XCTAssertTrue(app.staticTexts["Page added · Saved"].waitForExistence(timeout: 10))
    app.buttons["pageHome"].tap()
    water(in: app).tap()
    let message =
      app.textFields["snapEditMessage"].exists
      ? app.textFields["snapEditMessage"] : app.textViews["snapEditMessage"]
    message.tap()
    message.typeKey("a", modifierFlags: .command)
    message.typeText("I want water")
    XCTAssertTrue(app.images["buttonArtworkPreview"].exists)
    // The iPad keyboard changes the sheet's frame after text entry.
    let hideKeyboard = app.buttons["Hide keyboard"]
    if hideKeyboard.exists && hideKeyboard.isHittable { hideKeyboard.tap() }
    app.buttons["saveSnapButton"].tap()
    XCTAssertTrue(app.staticTexts["Button updated · Saved"].waitForExistence(timeout: 10))
    app.buttons["Export"].tap()
    let pickerBar = app.navigationBars["FullDocumentManagerViewControllerNavigationBar"]
    XCTAssertTrue(pickerBar.waitForExistence(timeout: 15))
    capture(app, "Native backup export picker")
    let localRoot = app.otherElements.matching(
      NSPredicate(
        format:
          "identifier BEGINSWITH 'DOC.browsingRoot Source: com.apple.FileProvider.LocalStorage, Title: On My '"
      )
    ).firstMatch
    if !localRoot.exists {
      if pickerBar.buttons["BackButton"].exists { pickerBar.buttons["BackButton"].tap() }
      let local = app.cells.matching(
        NSPredicate(format: "label CONTAINS 'On My iPhone' OR label CONTAINS 'On My iPad'")
      ).firstMatch
      XCTAssertTrue(local.waitForExistence(timeout: 5))
      local.tap()
    }
    capture(app, "Local backup export destination")
    XCTAssertTrue(
      localRoot.waitForExistence(timeout: 5),
      "Only export into the simulator's local Files location")
    XCTAssertTrue(
      (app.textFields["DOCPicker.filenameTextField"].value as? String)?.hasPrefix(title) == true)
    pickerBar.buttons["DOCPicker.actionButton"].tap()
    XCTAssertTrue(pickerBar.waitForNonExistence(timeout: 15))
    XCTAssertFalse(app.alerts["Board Scanner"].exists)

    // A fresh, separate library proves restore reads the external file, not an autosaved copy.
    app.terminate()
    let restoredLibrary = UUID().uuidString
    launch(app, library: restoredLibrary, fresh: true)
    XCTAssertTrue(app.buttons["sampleBoard"].waitForExistence(timeout: 10))
    app.buttons["Files"].tap()
    XCTAssertTrue(pickerBar.waitForExistence(timeout: 15))
    let search = pickerBar.searchFields.firstMatch
    if !search.exists { pickerBar.buttons["Search"].tap() }
    search.tap()
    search.typeText(title + "\n")
    let nameSuggestion = app.buttons.matching(
      NSPredicate(format: "label BEGINSWITH 'Name Contains' AND label CONTAINS %@", title)
    ).firstMatch
    if nameSuggestion.exists {
      nameSuggestion.tap()
      XCTAssertTrue(nameSuggestion.waitForNonExistence(timeout: 5))
    }
    // iPhone retains a covered browse collection; iPad presents search inline
    // after its name-suggestion popover is submitted.
    let searchContainer = app.otherElements["DOCSearchControllerContainerViewIdentifier"]
    let results = searchContainer.exists ? searchContainer : app
    let backup = results.collectionViews["File View"].cells.matching(
      NSPredicate(format: "label BEGINSWITH %@", title))
    let uniqueResult = XCTNSPredicateExpectation(
      predicate: NSPredicate { _, _ in
        backup.allElementsBoundByIndex.filter(\.isHittable).count == 1
      }, object: nil)
    let found = XCTWaiter.wait(for: [uniqueResult], timeout: 15)
    capture(app, "Exported backup in native import picker")
    XCTAssertEqual(found, .completed)
    let visibleBackups = backup.allElementsBoundByIndex.filter(\.isHittable)
    XCTAssertEqual(visibleBackups.count, 1)
    try XCTUnwrap(visibleBackups.first).tap()
    XCTAssertTrue(pickerBar.waitForNonExistence(timeout: 15))
    XCTAssertTrue(water(in: app).waitForExistence(timeout: 15))
    XCTAssertEqual(app.staticTexts["snapPageTitle"].label, title)
    app.buttons["allPages"].tap()
    let drinks = app.buttons.matching(
      NSPredicate(format: "identifier BEGINSWITH 'snapPage_' AND label CONTAINS 'Drinks'")
    ).firstMatch
    XCTAssertTrue(
      drinks.waitForExistence(timeout: 5),
      "The backup must include pages beyond the exported current page")
    drinks.tap()
    XCTAssertEqual(app.staticTexts["snapPageTitle"].label, "Drinks")
    app.buttons["pageHome"].tap()
    water(in: app).tap()
    XCTAssertEqual(app.otherElements["communicationMessage"].value as? String, "I want water")
    app.tapBoardControl("toggleEditing")
    water(in: app).tap()
    XCTAssertTrue(app.images["buttonArtworkPreview"].waitForExistence(timeout: 5))
    capture(app, "Restored backup retains spoken message and picture")
    app.navigationBars["Edit button"].buttons["Cancel"].tap()
    app.terminate()
    launch(app, library: restoredLibrary)
    XCTAssertTrue(water(in: app).waitForExistence(timeout: 15))
    water(in: app).tap()
    XCTAssertEqual(app.otherElements["communicationMessage"].value as? String, "I want water")
  }

  private func launch(_ app: XCUIApplication, library: String, fresh: Bool = false) {
    app.launchArguments = [
      "--ui-testing", "--library-id", library, "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
    ]
    if fresh { app.launchArguments.append("--fresh-start") }
    app.launch()
  }

  private func water(in app: XCUIApplication) -> XCUIElement {
    app.buttons.matching(
      NSPredicate(format: "identifier BEGINSWITH 'snapButton_' AND label == 'Water'")
    ).firstMatch
  }

  private func capture(_ app: XCUIApplication, _ name: String) {
    let hierarchy = XCTAttachment(string: app.debugDescription)
    hierarchy.name = name + " hierarchy"
    hierarchy.lifetime = .keepAlways
    add(hierarchy)
    let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    screenshot.name = name
    screenshot.lifetime = .keepAlways
    add(screenshot)
  }
}
