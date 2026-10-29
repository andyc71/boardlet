import XCTest

/// Run with the BoardScannerRealPhotos scheme after seeding the six supplied originals.
/// The dated, identical Photos labels were observed in the actual picker. The selection
/// is scoped to exactly six assets; image identity is then checked against parsed cells.
@MainActor
final class RealScreenshotUITests: XCTestCase {
  func testPhoto1Animals() { validate(photo: 1, name: "Animals", cards: 28, identity: "animal") }
  func testPhoto2Descriptors() {
    validate(photo: 2, name: "Descriptors", cards: 60, identity: "kind")
  }
  func testPhoto3Places() { validate(photo: 3, name: "Places", cards: 56, identity: "place") }
  func testPhoto4Time() { validate(photo: 4, name: "Time", cards: 58, identity: "time") }
  func testPhoto5HomePage() {
    validate(photo: 5, name: "Home Page", cards: 66, identity: "Keyboard")
  }
  func testPhoto6FoodAndDrink() {
    validate(photo: 6, name: "Food & Drink", cards: 28, identity: "food")
  }

  func testPhotoArtworkCancellationSelectionAndRelaunch() {
    continueAfterFailure = false
    let app = XCUIApplication()
    let library = UUID().uuidString
    let arguments = [
      "--ui-testing", "--library-id", library, "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
    ]
    app.launchArguments = arguments + ["--fresh-start"]
    app.launch()
    XCUIDevice.shared.orientation = .landscapeLeft
    XCUIDevice.shared.orientation = .portrait
    app.buttons["createMenu"].tap()
    app.buttons["New board"].tap()
    let starter = app.switches["starterWords"]
    XCTAssertTrue(starter.waitForExistence(timeout: 5))
    SystemPhotoPickerDriver(app: app).captureEvidence(named: "Blank board switch before selection")
    // The labelled row contains the actual switch control in the observed UI.
    starter.switches.firstMatch.tap()
    XCTAssertEqual(starter.value as? String, "0", "Create this board without starter artwork")
    app.textFields["newBoardName"].tap()
    app.textFields["newBoardName"].typeText("Photo artwork")
    app.buttons["createNativeBoard"].tap()
    XCTAssertTrue(app.staticTexts["Board created · Saved"].waitForExistence(timeout: 15))
    app.buttons["emptyCell_0_0"].tap()
    let label =
      app.textFields["snapEditLabel"].exists
      ? app.textFields["snapEditLabel"] : app.textViews["snapEditLabel"]
    label.tap()
    label.typeText("My picture")
    let hideKeyboard = app.buttons["Hide keyboard"]
    if hideKeyboard.waitForExistence(timeout: 2) && hideKeyboard.isHittable { hideKeyboard.tap() }
    app.buttons["chooseButtonArtwork"].tap()
    app.buttons["buttonArtworkPhotos"].tap()
    let picker = SystemPhotoPickerDriver(app: app)
    picker.assertOpen()
    // Three sheets expose Cancel; target the native picker's navigation bar.
    app.navigationBars["Photos"].buttons["Cancel"].tap()
    picker.assertDismissed()
    XCTAssertTrue(app.buttons["buttonArtworkPhotos"].waitForExistence(timeout: 5))
    app.navigationBars["Choose picture"].buttons["Cancel"].tap()
    XCTAssertTrue(app.buttons["chooseButtonArtwork"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.images["buttonArtworkPreview"].exists)
    XCTAssertEqual(label.value as? String, "My picture")

    app.buttons["chooseButtonArtwork"].tap()
    app.buttons["buttonArtworkPhotos"].tap()
    picker.assertOpen()
    let supplied = app.images.matching(
      NSPredicate(format: "label == %@", "Photo, 27 October, 12:45"))
    XCTAssertEqual(supplied.count, 6, "Only the six supplied test photos may be selected.")
    let thumbnail = supplied.element(boundBy: 0)
    XCTAssertTrue(thumbnail.exists)
    XCTAssertTrue(app.frame.contains(CGPoint(x: thumbnail.frame.midX, y: thumbnail.frame.midY)))
    picker.captureEvidence(named: "Artwork source – supplied Food and Drink screenshot")
    thumbnail.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    picker.confirmSingleSelectionIfNeeded()
    picker.assertDismissed()
    XCTAssertTrue(app.images["buttonArtworkPreview"].waitForExistence(timeout: 15))
    picker.captureEvidence(named: "Selected photo artwork")
    app.buttons["saveSnapButton"].tap()
    XCTAssertTrue(app.staticTexts["Button updated · Saved"].waitForExistence(timeout: 10))

    app.terminate()
    app.launchArguments = arguments
    app.launch()
    let tile = app.buttons.matching(
      NSPredicate(format: "identifier BEGINSWITH 'snapButton_' AND label == 'My picture'")
    ).firstMatch
    XCTAssertTrue(tile.waitForExistence(timeout: 15))
    tile.tap()
    XCTAssertEqual(app.otherElements["communicationMessage"].value as? String, "My picture")
    app.tapBoardControl("toggleEditing")
    tile.tap()
    XCTAssertTrue(app.images["buttonArtworkPreview"].waitForExistence(timeout: 5))
    picker.captureEvidence(named: "Photo artwork retained after relaunch")
  }

  private func validate(photo: Int, name: String, cards: Int, identity: String) {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = [
      "--ui-testing", "--fresh-start", "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
    ]
    XCUIDevice.shared.orientation = .portrait
    app.launch()
    app.buttons["Photos"].tap()
    let picker = SystemPhotoPickerDriver(app: app)
    picker.assertOpen()
    let supplied = app.images.matching(
      NSPredicate(format: "label == %@", "Photo, 27 October, 12:45"))
    XCTAssertEqual(
      supplied.count, 6,
      "Expected exactly the six original uploads; do not select from unrelated library assets.")
    // Inspection of the native thumbnails establishes newest-first order: 6, 5, 4, 3, 2, 1.
    // The shared driver's unique-label method cannot distinguish equal timestamps.
    // Tap the observed frame center only after checking the selected cell is visible.
    let thumbnail = supplied.element(boundBy: 6 - photo)
    XCTAssertTrue(thumbnail.exists)
    XCTAssertTrue(app.frame.contains(CGPoint(x: thumbnail.frame.midX, y: thumbnail.frame.midY)))
    picker.captureEvidence(named: "Photo \(photo) – \(name) – source in Photos")
    thumbnail.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    picker.confirmSingleSelectionIfNeeded()
    picker.assertDismissed()
    let ready = app.staticTexts.matching(
      NSPredicate(format: "identifier == 'boardStatus' AND label BEGINSWITH %@", "\(cards) cards")
    ).firstMatch
    XCTAssertTrue(ready.waitForExistence(timeout: 40), app.debugDescription)
    XCTAssertTrue(
      app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "6 rows × 11 columns"))
        .firstMatch.exists)
    XCTAssertEqual(
      app.buttons["card_1_0"].label, identity,
      "Imported content must identify the selected source screenshot.")
    XCTAssertEqual(app.buttons["card_0_0"].label, photo == 5 ? "QuickFires" : "Home")
    if photo == 1 || photo == 6 {
      XCTAssertFalse(app.buttons["card_0_1"].exists, "Empty source slots must stay empty.")
    }
    XCTAssertFalse(
      app.buttons.matching(
        NSPredicate(
          format: "label == 'Speak' OR label == 'Clear' OR label == 'Delete' OR label == 'Share'")
      ).firstMatch.exists,
      "Top app controls must not be imported as board cards.")
    picker.captureEvidence(named: "Photo \(photo) – \(name) – recreated board")
    if photo == 2 {
      XCTAssertEqual(
        app.buttons["card_0_10"].label, "Feelings",
        "A stray OCR slash must not become part of the card caption.")
    }
    app.tapBoardControl("toggleEditing")
    app.buttons["Save"].tap()
    XCTAssertTrue(app.staticTexts["Saved on this device"].waitForExistence(timeout: 10))
    app.buttons["Detection"].tap()
    XCTAssertTrue(app.images["detectionPreview"].waitForExistence(timeout: 10))
    picker.captureEvidence(named: "Photo \(photo) – \(name) – detection and picture crops")
  }
}
