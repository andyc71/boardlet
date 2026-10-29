import XCTest

@MainActor
final class OpenDocumentUITests: XCTestCase {
  func testURLLaunchImportsBothFormatsAndPreservesLibraryAfterInvalidFile() throws {
    continueAfterFailure = false
    let imported = try SnapTestFixture.make(extraSQL: """
      UPDATE PageSetProperties SET FriendlyName='URL imported page set';
      INSERT INTO Button VALUES(4,40,'Drink','Please bring water',0,0);
      INSERT INTO ElementPlacement VALUES(5,40,'1,0','1,1',1,3);
      """)
    let native = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".boardscan")
    let invalid = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".boardscan")
    defer {
      for url in [imported, native, invalid] { try? FileManager.default.removeItem(at: url) }
    }
    try Data(Self.nativeDocument.utf8).write(to: native)
    try Data("This is not a board".utf8).write(to: invalid)
    let app = XCUIApplication()
    let arguments = ["--ui-testing", "--library-id", UUID().uuidString,
                     "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    app.launchArguments = arguments + ["--fresh-start"]
    XCUIDevice.shared.orientation = .landscapeLeft
    XCUIDevice.shared.orientation = .portrait
    // Deliver URLs through XCTest's launch API, never the debug import argument.
    app.open(imported)
    XCTAssertTrue(app.buttons["snapButton_1"].waitForExistence(timeout: 20))
    app.buttons["snapButton_1"].tap()
    app.buttons["snapButton_4"].tap()
    XCTAssertEqual(app.otherElements["communicationMessage"].value as? String, "Please bring water")

    app.terminate()
    app.launchArguments = arguments
    // Restoration and incoming URL delivery can both run during this cold launch.
    app.open(native)
    XCTAssertTrue(app.buttons["snapButton_water"].waitForExistence(timeout: 20))
    XCTAssertEqual(app.staticTexts["snapPageTitle"].label, "URL native board")
    XCTAssertEqual(app.otherElements["communicationMessage"].value as? String, "Empty")
    app.buttons["snapButton_water"].tap()
    XCTAssertEqual(app.otherElements["communicationMessage"].value as? String, "I want water")
    app.tapBoardControl("boardLibrary")
    XCTAssertTrue(app.buttons["libraryBoard_URL imported page set"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["libraryBoard_URL native board"].exists)
    app.buttons["libraryBoard_URL imported page set"].tap()
    XCTAssertTrue(app.buttons["snapButton_1"].waitForExistence(timeout: 10))
    app.buttons["snapButton_1"].tap()
    app.buttons["snapButton_4"].tap()
    XCTAssertEqual(app.otherElements["communicationMessage"].value as? String, "Please bring water")

    app.terminate()
    app.open(invalid)
    let error = app.alerts["Board Scanner"]
    XCTAssertTrue(error.waitForExistence(timeout: 15))
    error.buttons["OK"].tap()
    XCTAssertTrue(app.buttons["snapButton_1"].waitForExistence(timeout: 10))
    app.tapBoardControl("boardLibrary")
    XCTAssertTrue(app.buttons["libraryBoard_URL imported page set"].waitForExistence(timeout: 5))
    XCTAssertTrue(app.buttons["libraryBoard_URL native board"].exists)
    XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'libraryBoard_'")).count, 2)
    capture(app, "URL imports retained after invalid document")
    app.buttons["libraryBoard_URL native board"].tap()
    app.terminate()
    app.launch()
    XCTAssertTrue(app.buttons["snapButton_water"].waitForExistence(timeout: 15))
    app.buttons["snapButton_water"].tap()
    XCTAssertEqual(app.otherElements["communicationMessage"].value as? String, "I want water")
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

  // An external version-2 archive exercises decoding rather than a test-only import path.
  private static let nativeDocument = #"""
    {"version":2,"pageSet":{"title":"URL native board","schemaVersion":"4.20","homePageID":"home",
    "pages":[{"id":"home","title":"URL native board","pageType":1,"layouts":[
    {"id":1,"setting":"","columns":2,"rows":2,"placements":[
    {"id":1,"elementID":"water","column":0,"row":0,"columnSpan":1,"rowSpan":1,"visible":true}]}]}],
    "buttons":{"water":{"id":"water","label":"Water","message":"I want water",
    "destinationIDs":[],"serializedCommands":""}},"assets":{}}}
    """#
}
