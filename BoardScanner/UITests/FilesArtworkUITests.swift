import XCTest

/// Opt-in fixture created by Scripts/seed-artwork.py; no existing documents selected.
@MainActor
final class FilesArtworkUITests: XCTestCase {
  func testFilesArtworkSelectionAndRelaunch() throws {
    guard let filename = ProcessInfo.processInfo.environment["BOARD_SCANNER_ARTWORK_FIXTURE"],
      filename.hasPrefix("BoardScanner-Artwork-"), filename.hasSuffix(".png"),
      !filename.contains("/")
    else { throw XCTSkip("Seed a simulator artwork fixture and pass its filename") }
    continueAfterFailure = false
    let name = String(filename.dropLast(4))
    let app = XCUIApplication()
    let library = UUID().uuidString
    app.launchArguments = [
      "--ui-testing", "--fresh-start", "--library-id", library, "-AppleLanguages", "(en)",
      "-AppleLocale", "en_US",
    ]
    app.launch()
    XCUIDevice.shared.orientation = .landscapeLeft
    XCUIDevice.shared.orientation = .portrait
    app.buttons["createMenu"].tap()
    app.buttons["New board"].tap()
    app.textFields["newBoardName"].tap()
    app.textFields["newBoardName"].typeText("Files artwork")
    app.buttons["createNativeBoard"].tap()
    XCTAssertTrue(app.staticTexts["Board created · Saved"].waitForExistence(timeout: 15))
    let yes = app.buttons.matching(
      NSPredicate(format: "identifier BEGINSWITH 'snapButton_' AND label == 'Yes'")
    ).firstMatch
    yes.tap()
    app.buttons["chooseButtonArtwork"].tap()
    app.buttons["buttonArtworkFiles"].tap()
    let pickerBar = app.navigationBars["FullDocumentManagerViewControllerNavigationBar"]
    XCTAssertTrue(pickerBar.waitForExistence(timeout: 15))
    let search = pickerBar.searchFields.firstMatch
    if !search.exists { pickerBar.buttons["Search"].tap() }
    XCTAssertTrue(search.waitForExistence(timeout: 5))
    search.tap()
    search.typeText(name)
    let fixture = app.collectionViews["File View"].cells.matching(
      NSPredicate(format: "label CONTAINS %@", name))
    let found = fixture.firstMatch.waitForExistence(timeout: 15)
    SystemPhotoPickerDriver(app: app).captureEvidence(named: "Files artwork fixture search")
    XCTAssertTrue(found)
    XCTAssertEqual(fixture.count, 1, "Only the uniquely named generated fixture may be selected")
    fixture.firstMatch.tap()
    XCTAssertTrue(pickerBar.waitForNonExistence(timeout: 15))
    XCTAssertTrue(app.images["buttonArtworkPreview"].waitForExistence(timeout: 15))
    SystemPhotoPickerDriver(app: app).captureEvidence(named: "Selected Files artwork")
    app.buttons["saveSnapButton"].tap()
    XCTAssertTrue(app.staticTexts["Button updated · Saved"].waitForExistence(timeout: 10))
    app.terminate()
    app.launchArguments = ["--ui-testing", "--library-id", library]
    app.launch()
    XCTAssertTrue(yes.waitForExistence(timeout: 15))
    yes.tap()
    XCTAssertEqual(app.otherElements["communicationMessage"].value as? String, "Yes")
    app.tapBoardControl("toggleEditing")
    yes.tap()
    XCTAssertTrue(app.images["buttonArtworkPreview"].waitForExistence(timeout: 5))
    SystemPhotoPickerDriver(app: app).captureEvidence(
      named: "Files artwork retained after relaunch")
  }
}
