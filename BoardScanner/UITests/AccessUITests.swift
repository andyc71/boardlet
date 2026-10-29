import UIKit
import XCTest

final class AccessUITests: XCTestCase {
  @MainActor
  func testNarrowImportedFolderLabelsKeepReadableWidth() throws {
    continueAfterFailure = false
    let image = UIGraphicsImageRenderer(size: CGSize(width: 80, height: 80)).image { context in
      UIColor.systemBlue.setFill()
      context.fill(CGRect(x: 0, y: 0, width: 80, height: 80))
    }
    let png = try XCTUnwrap(image.pngData()).map { String(format: "%02x", $0) }.joined()
    let url = try SnapTestFixture.make(extraSQL: """
      UPDATE PageSetProperties SET GridDimension='11,6';
      UPDATE Page SET GridDimension='11,6' WHERE Id=1;
      UPDATE PageLayout SET PageLayoutSetting='11,6,True,0' WHERE Id=2;
      UPDATE ElementPlacement SET GridSpan='1,1' WHERE Id=1;
      UPDATE Button SET Label='QuickFires' WHERE Id=1;
      UPDATE PageSetData SET Data=X'\(png)' WHERE Id=1;
      """)
    defer { try? FileManager.default.removeItem(at: url) }
    let app = XCUIApplication()
    app.launchArguments = ["--ui-testing", "--fresh-start", "--library-id", UUID().uuidString,
                           "--import-test-document", url.path]
    app.launch()
    let folder = app.buttons["snapButton_1"]
    XCTAssertTrue(folder.waitForExistence(timeout: 20))
    for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
      app.setWindowOrientation(orientation)
      let label = folder.staticTexts["QuickFires"]
      XCTAssertTrue(label.exists)
      capture("Narrow imported folder label \(orientation.rawValue)", app)
      // XCTest exposes the rendered glyph bounds, not the allocated label width.
      // "Quick-Fires" legitimately wraps to two lines on the narrowest cells.
      let lineHeight = UIFont.preferredFont(forTextStyle: .headline).lineHeight
      XCTAssertLessThanOrEqual(label.frame.height, lineHeight * 2 + 2,
                               "The folder name must fit in at most two readable lines")
      XCTAssertGreaterThanOrEqual(label.frame.width, 40,
                                  "The picture must not squeeze the label into a few characters per line")
    }
    folder.tap()
    XCTAssertEqual(app.staticTexts["snapPageTitle"].label, "Child")
    app.setWindowOrientation(.portrait)
  }

  @MainActor
  func testImportActionsRemainReadableAtMaximumText() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = [
      "--ui-testing", "--fresh-start", "--library-id", UUID().uuidString,
      "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
    ]
    app.launch()
    app.setWindowOrientation(.landscapeLeft)
    app.setWindowOrientation(.portrait)
    let imports = app.scrollViews["importActions"]
    XCTAssertTrue(imports.waitForExistence(timeout: 5))
    XCTAssertLessThan(imports.frame.height, app.windows.firstMatch.frame.height / 3,
                     "Import actions must leave room for the board and welcome content")
    let photos = app.buttons["Photos"]
    XCTAssertTrue(photos.isHittable)
    XCTAssertTrue(photos.staticTexts["Photos"].exists)
    capture("Maximum text import actions before scrolling", app)
    let files = app.buttons["Files"]
    for _ in 0..<4 {
      let viewport = imports.frame
      let target = files.frame
      if viewport.intersection(target).width >= target.width - 1 { break }
      let distance = target.maxX > viewport.maxX
        ? min(target.maxX - viewport.maxX + 16, viewport.width / 2)
        : max(target.minX - viewport.minX - 16, -viewport.width / 2)
      // Start in the row's padding so the drag cannot begin on an import button.
      let start = imports.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
      start.press(forDuration: 0.1,
                  thenDragTo: start.withOffset(CGVector(dx: -distance, dy: 0)),
                  withVelocity: .slow, thenHoldForDuration: 0.5)
    }
    XCTAssertGreaterThanOrEqual(imports.frame.intersection(files.frame).width, files.frame.width - 1)
    XCTAssertTrue(files.isHittable)
    XCTAssertTrue(files.staticTexts["Files"].exists)
    capture("Maximum text import actions after scrolling", app)
    files.tap()
    let cancel = app.buttons["Cancel"]
    // Files is a system extension; use the same launch allowance as the native
    // artwork and backup journeys, and retain its state if presentation fails.
    let start = Date()
    let presented = cancel.waitForExistence(timeout: 15)
    let timing = XCTAttachment(string: "Files Cancel available: \(presented); wait: \(Date().timeIntervalSince(start)) seconds")
    timing.lifetime = .keepAlways
    add(timing)
    let picker = app.navigationBars["FullDocumentManagerViewControllerNavigationBar"]
    if presented {
      XCTAssertTrue(picker.waitForExistence(timeout: 5), "Files must present its document browser")
      XCTAssertTrue(cancel.isHittable)
    }
    capture("Maximum text Files presentation", app)
    if !presented {
      let hierarchy = XCTAttachment(string: app.debugDescription)
      hierarchy.lifetime = .keepAlways
      add(hierarchy)
    }
    XCTAssertTrue(presented)
    cancel.tap()
    XCTAssertTrue(picker.waitForNonExistence(timeout: 10))
    XCTAssertTrue(imports.waitForExistence(timeout: 5))
    XCTAssertTrue(files.isHittable, "Cancelling Files must return control to the import actions")
  }

  @MainActor
  func testStepScanningSelectsChoicesAndMessageActionsAndPausesForSheets() {
    continueAfterFailure = false
    let app = makeBoard()
    setMode("Step scanning", app)
    let select = app.buttons["scanSelect"]
    XCTAssertTrue(select.waitForExistence(timeout: 5))
    app.typeKey(.space, modifierFlags: [])
    XCTAssertEqual(select.label, "Select: Yes")
    app.typeKey(.rightArrow, modifierFlags: .command)
    XCTAssertEqual(select.label, "Select: No")
    select.tap()
    XCTAssertEqual(message(app), "No")
    XCTAssertEqual(select.label, "Start scan")
    select.tap()
    app.tapBoardControl("communicationSettings")
    app.buttons["Done"].tap()
    XCTAssertEqual(select.label, "Start scan")
    select.tap()
    app.buttons["scanPrevious"].tap()
    XCTAssertEqual(select.label, "Select: Clear message")
    select.tap()
    XCTAssertEqual(message(app), "Empty")
    select.tap()
    select.tap()
    XCTAssertEqual(message(app), "Yes")
    select.tap()
    app.buttons["scanPrevious"].tap()
    app.buttons["scanPrevious"].tap()
    XCTAssertEqual(select.label, "Select: Undo last word")
    select.tap()
    XCTAssertEqual(message(app), "Empty")
    select.tap()
    app.buttons["allPages"].tap()
    app.buttons["Done"].tap()
    XCTAssertEqual(select.label, "Start scan")
    capture("Step scanning", app)
  }

  @MainActor
  func testLandscapeScanScrollsFocusedTileIntoView() {
    continueAfterFailure = false
    let app = makeBoard()
    setMode("Step scanning", app)
    app.setWindowOrientation(.landscapeLeft)
    let select = app.buttons["scanSelect"]
    XCTAssertTrue(select.waitForExistence(timeout: 5))
    select.tap()
    for _ in 0..<8 { app.buttons["scanNext"].tap() }
    let focused = app.buttons.matching(
      NSPredicate(format: "identifier BEGINSWITH 'snapButton_' AND selected == true")
    ).firstMatch
    XCTAssertTrue(focused.waitForExistence(timeout: 5))
    XCTAssertTrue(focused.isHittable, "Scanning must reveal choices below the initial viewport")
    let viewport = app.scrollViews["snapGrid"]
    XCTAssertGreaterThanOrEqual(
      focused.frame.intersection(viewport.frame).height, focused.frame.height - 1,
      "The full highlighted tile, including its label, must fit in the viewport")
    XCTAssertEqual(focused.label, "Toilet")
    capture("Landscape highlighted final choice", app)
    select.tap()
    XCTAssertNotEqual(message(app), "Empty")
    XCTAssertTrue(app.buttons["speakMessage"].isHittable)
    capture("Landscape scanning and message controls", app)
    app.setWindowOrientation(.portrait)
  }

  @MainActor
  func testAccessibilityTextKeepsBoardAndActionsReachable() {
    continueAfterFailure = false
    let app = makeBoard(extraArguments: [
      "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
    ])
    let yes = app.buttons.matching(
      NSPredicate(format: "identifier BEGINSWITH 'snapButton_' AND label == 'Yes'")
    ).firstMatch
    XCTAssertTrue(yes.waitForExistence(timeout: 5))
    XCTAssertTrue(yes.isHittable)
    yes.tap()
    XCTAssertEqual(message(app), "Yes")
    let actions = app.scrollViews["messageActions"]
    XCTAssertTrue(actions.exists)
    for _ in 0..<5 where !app.buttons["showPhrases"].isHittable { actions.swipeLeft() }
    XCTAssertTrue(app.buttons["showPhrases"].isHittable)
    capture("Accessibility text and horizontally scrolling actions", app)
    app.buttons["showPhrases"].tap()
    XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 5))
    app.buttons["Done"].tap()
    XCTAssertTrue(yes.isHittable)
  }

  @MainActor
  func testKeyboardStepsThroughEveryChoiceAtMaximumText() {
    continueAfterFailure = false
    let app = makeBoard(extraArguments: [
      "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
    ])
    setMaximumButtonSizeAndStepScanning(app)
    app.setWindowOrientation(.landscapeLeft)
    defer { app.setWindowOrientation(.portrait) }
    app.typeKey(.space, modifierFlags: [])
    let select = app.buttons["scanSelect"]
    XCTAssertEqual(select.label, "Select: Yes")
    for word in ["No", "I want", "More", "Help", "Stop", "Water", "Eat", "Toilet"] {
      app.typeKey(.rightArrow, modifierFlags: .command)
      let arrived = XCTNSPredicateExpectation(
        predicate: NSPredicate(format: "label == %@", "Select: " + word), object: select)
      XCTAssertEqual(XCTWaiter.wait(for: [arrived], timeout: 3), .completed)
    }
    app.typeKey(.space, modifierFlags: [])
    XCTAssertEqual(message(app), "Toilet")
  }

  @MainActor
  func testMaximumTextAndButtonSizeKeepLandscapeScanChoiceVisible() {
    continueAfterFailure = false
    let app = makeBoard(extraArguments: [
      "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
    ])
    setMaximumButtonSizeAndStepScanning(app)
    app.setWindowOrientation(.landscapeLeft)
    defer { app.setWindowOrientation(.portrait) }
    let select = app.buttons["scanSelect"]
    XCTAssertTrue(select.waitForExistence(timeout: 5))
    select.tap()
    for _ in 0..<8 { app.buttons["scanNext"].tap() }
    let focused = app.buttons.matching(
      NSPredicate(format: "identifier BEGINSWITH 'snapButton_' AND selected == true")
    ).firstMatch
    XCTAssertTrue(focused.waitForExistence(timeout: 5))
    capture("Maximum text and button size in landscape", app)
    XCTAssertEqual(focused.label, "Toilet")
    let viewport = app.scrollViews["snapGrid"]
    XCTAssertGreaterThanOrEqual(
      focused.frame.intersection(viewport.frame).height, focused.frame.height - 1,
      "The full highlighted choice must fit even at maximum text and button size")
    XCTAssertGreaterThanOrEqual(
      focused.frame.intersection(viewport.frame).width, focused.frame.width - 1,
      "The full highlighted choice must fit horizontally as well")
    app.setWindowOrientation(.portrait)
    assertFullyVisible(focused, in: viewport)
    capture("Maximum text native scan after rotation to portrait", app)
    app.setWindowOrientation(.landscapeLeft)
    assertFullyVisible(focused, in: viewport)
    XCTAssertTrue(select.isHittable)
    select.tap()
    XCTAssertEqual(message(app), "Toilet")
  }

  @MainActor
  func testImportedMergedChoicesRemainVisibleAndSelectableAcrossRotation() throws {
    continueAfterFailure = false
    let picture = try XCTUnwrap(
      UIImage(systemName: "drop.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
        .pngData())
    let pictureHex = picture.map { String(format: "%02x", $0) }.joined()
    let url = try SnapTestFixture.make(
      extraSQL: """
        DELETE FROM ElementPlacement;
        DELETE FROM ButtonPageLink;
        DELETE FROM CommandSequence;
        UPDATE Button SET Label='Water', Message='I want water' WHERE Id=1;
        UPDATE Button SET Label='Help', Message='Please help me', PageSetImageId=1 WHERE Id=2;
        UPDATE Button SET Label='Hidden choice' WHERE Id=3;
        UPDATE PageSetData SET Data=X'\(pictureHex)' WHERE Id=1;
        INSERT INTO ElementPlacement VALUES(11,10,'4,4','3,3',1,2);
        INSERT INTO ElementPlacement VALUES(12,20,'8,8','2,2',1,2);
        INSERT INTO ElementPlacement VALUES(13,30,'0,0','1,1',0,2);
        """)
    defer { try? FileManager.default.removeItem(at: url) }
    let app = XCUIApplication()
    app.launchArguments = [
      "--ui-testing", "--fresh-start", "--library-id", UUID().uuidString,
      "--import-test-document", url.path,
      "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
    ]
    app.launch()
    app.setWindowOrientation(.landscapeLeft)
    app.setWindowOrientation(.portrait)
    defer { app.setWindowOrientation(.portrait) }
    XCTAssertTrue(app.scrollViews["snapGrid"].waitForExistence(timeout: 20))
    setMaximumButtonSizeAndStepScanning(app)
    app.setWindowOrientation(.landscapeLeft)
    let select = app.buttons["scanSelect"]
    select.tap()
    XCTAssertEqual(select.label, "Select: Water")
    let viewport = app.scrollViews["snapGrid"]
    let water = app.buttons["snapButton_1"]
    assertFullyVisible(water, in: viewport)
    capture("Imported three-row merged choice in landscape", app)
    XCTAssertFalse(app.buttons["snapButton_3"].exists)
    app.setWindowOrientation(.portrait)
    assertFullyVisible(water, in: viewport)
    XCTAssertTrue(water.isSelected)
    capture("Imported three-row merged choice in portrait", app)
    select.tap()
    XCTAssertEqual(message(app), "I want water")
    select.tap()
    app.buttons["scanNext"].tap()
    XCTAssertEqual(select.label, "Select: Help")
    let help = app.buttons["snapButton_2"]
    assertFullyVisible(help, in: viewport)
    app.setWindowOrientation(.landscapeLeft)
    assertFullyVisible(help, in: viewport)
    capture("Imported second merged choice in landscape", app)
    select.tap()
    XCTAssertEqual(message(app), "I want water Please help me")
  }

  @MainActor
  func testScreenshotBoardAtMaximumSizeInLandscape() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = [
      "--ui-testing", "--fresh-start", "--library-id", UUID().uuidString,
      "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
    ]
    app.launch()
    app.setWindowOrientation(.landscapeLeft)
    app.setWindowOrientation(.portrait)
    app.buttons["sampleBoard"].tap()
    XCTAssertTrue(app.buttons["card_0_0"].waitForExistence(timeout: 45))
    setMaximumButtonSizeAndStepScanning(app)
    app.setWindowOrientation(.landscapeLeft)
    defer { app.setWindowOrientation(.portrait) }
    let select = app.buttons["scanSelect"]
    select.tap()
    for _ in 0..<5 { app.buttons["scanNext"].tap() }
    let focused = app.buttons.matching(
      NSPredicate(format: "identifier BEGINSWITH 'card_' AND selected == true")
    ).firstMatch
    XCTAssertTrue(focused.waitForExistence(timeout: 5))
    capture("Screenshot board at maximum size in landscape", app)
    let viewport = app.scrollViews["cardGrid"]
    XCTAssertGreaterThanOrEqual(
      focused.frame.intersection(viewport.frame).height, focused.frame.height - 1,
      "The full screenshot choice must fit inside its viewport")
    XCTAssertGreaterThanOrEqual(
      focused.frame.intersection(viewport.frame).width, focused.frame.width - 1,
      "The full screenshot choice must fit horizontally as well")
    XCTAssertTrue(focused.isHittable)
    let selectedLabel = focused.label
    app.setWindowOrientation(.portrait)
    assertFullyVisible(focused, in: viewport)
    capture("Maximum text screenshot scan after rotation to portrait", app)
    app.setWindowOrientation(.landscapeLeft)
    assertFullyVisible(focused, in: viewport)
    select.tap()
    XCTAssertEqual(message(app), selectedLabel)
  }

  @MainActor
  func testAutomaticScanningPausesForTypingAndBackground() {
    continueAfterFailure = false
    let app = makeBoard()
    setMode("Automatic scanning", app)
    let select = app.buttons["scanSelect"]
    app.typeKey(.space, modifierFlags: [])
    let moved = NSPredicate(format: "label BEGINSWITH 'Select:' AND label != 'Select: Yes'")
    expectation(for: moved, evaluatedWith: select)
    waitForExpectations(timeout: 6)
    XCTAssertEqual(message(app), "Empty", "The timer must never choose a word")
    app.typeKey(".", modifierFlags: .command)
    XCTAssertEqual(select.label, "Start scan")
    select.tap()
    app.buttons["typeMessage"].tap()
    let field =
      app.textViews["typedMessage"].exists
      ? app.textViews["typedMessage"] : app.textFields["typedMessage"]
    field.tap()
    field.typeText("two words")
    app.buttons["Add"].tap()
    XCTAssertEqual(message(app), "two words")
    XCTAssertEqual(select.label, "Start scan")
    select.tap()
    XCUIDevice.shared.press(.home)
    app.activate()
    XCTAssertEqual(select.label, "Start scan")
  }

  @MainActor
  func testScanPageLinkAndReturnWithoutLosingMessage() throws {
    continueAfterFailure = false
    let url = try SnapTestFixture.make(
      extraSQL: """
        DELETE FROM PageLayout WHERE PageId=4;
        INSERT INTO Button VALUES(4,40,'Drink','I want water',0,0);
        INSERT INTO ElementPlacement VALUES(5,40,'1,0','1,1',1,3);
        """)
    defer { try? FileManager.default.removeItem(at: url) }
    let app = XCUIApplication()
    app.launchArguments = [
      "--ui-testing", "--fresh-start", "--library-id", UUID().uuidString,
      "--import-test-document", url.path,
    ]
    app.launch()
    app.setWindowOrientation(.landscapeLeft)
    app.setWindowOrientation(.portrait)
    XCTAssertTrue(app.buttons["snapButton_1"].waitForExistence(timeout: 20))
    setMode("Step scanning", app)
    let select = app.buttons["scanSelect"]
    select.tap()
    select.tap()
    XCTAssertEqual(app.staticTexts["snapPageTitle"].label, "Child")
    XCTAssertEqual(select.label, "Start scan")
    select.tap()
    XCTAssertEqual(select.label, "Select: Return")
    app.buttons["scanNext"].tap()
    XCTAssertEqual(select.label, "Select: Drink")
    select.tap()
    XCTAssertEqual(message(app), "I want water")
    select.tap()
    app.buttons["scanNext"].tap()
    app.buttons["scanNext"].tap()
    XCTAssertEqual(select.label, "Select: Previous page")
    select.tap()
    XCTAssertEqual(app.staticTexts["snapPageTitle"].label, "Home")
    XCTAssertEqual(message(app), "I want water")
    XCTAssertEqual(select.label, "Start scan")
    app.setWindowOrientation(.landscapeLeft)
    app.buttons["allPages"].tap()
    app.buttons["snapPage_orphan"].tap()
    XCTAssertTrue(app.staticTexts["This page has no grid layout."].exists)
    XCTAssertTrue(
      app.buttons["allPages"].isHittable, "A page without a layout must retain navigation")
    XCTAssertTrue(app.buttons["pageHome"].isHittable)
    app.buttons["pageHome"].tap()
    XCTAssertEqual(app.staticTexts["snapPageTitle"].label, "Home")
    XCTAssertEqual(select.label, "Start scan")
    app.setWindowOrientation(.portrait)
  }

  @MainActor private func assertFullyVisible(_ tile: XCUIElement, in viewport: XCUIElement) {
    // Orientation notifications can arrive before the animated viewport has settled.
    let visibleAfterRotation = XCTNSPredicateExpectation(
      predicate: NSPredicate { _, _ in
        let frame = tile.frame
        let visible = frame.intersection(viewport.frame)
        return visible.height >= frame.height - 1 && visible.width >= frame.width - 1
          && tile.isHittable
      }, object: tile)
    XCTAssertEqual(XCTWaiter.wait(for: [visibleAfterRotation], timeout: 5), .completed)
    let visible = tile.frame.intersection(viewport.frame)
    XCTAssertGreaterThanOrEqual(visible.height, tile.frame.height - 1)
    XCTAssertGreaterThanOrEqual(visible.width, tile.frame.width - 1)
    XCTAssertGreaterThanOrEqual(tile.frame.height, 44)
    XCTAssertGreaterThanOrEqual(tile.frame.width, 44)
    XCTAssertTrue(tile.isHittable)
  }

  @MainActor private func makeBoard(extraArguments: [String] = []) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments =
      ["--ui-testing", "--fresh-start", "--library-id", UUID().uuidString] + extraArguments
    app.launch()
    app.setWindowOrientation(.landscapeLeft)
    app.setWindowOrientation(.portrait)
    app.buttons["createMenu"].tap()
    app.buttons["New board"].tap()
    app.textFields["newBoardName"].tap()
    app.textFields["newBoardName"].typeText("Access board")
    let hide = app.buttons["Hide keyboard"]
    if hide.waitForExistence(timeout: 2), hide.isHittable { hide.tap() }
    app.buttons["createNativeBoard"].tap()
    XCTAssertTrue(app.staticTexts["Board created · Saved"].waitForExistence(timeout: 10))
    app.tapBoardControl("toggleEditing")
    return app
  }
  @MainActor private func setMaximumButtonSizeAndStepScanning(_ app: XCUIApplication) {
    app.tapBoardControl("communicationSettings")
    let method = app.buttons["selectionMethod"]
    for _ in 0..<8 where !method.isHittable { app.swipeUp() }
    method.tap()
    app.buttons["Step scanning"].tap()
    let size = app.sliders["Button size"]
    // The picker can return the large-text iPad form below the Access section.
    for _ in 0..<8 where !method.isHittable && !size.isHittable { app.swipeDown() }
    for _ in 0..<8 where !size.isHittable { app.swipeUp() }
    XCTAssertTrue(size.isHittable)
    size.adjust(toNormalizedSliderPosition: 1)
    app.buttons["Done"].tap()
  }
  @MainActor private func setMode(_ mode: String, _ app: XCUIApplication) {
    app.tapBoardControl("communicationSettings")
    app.buttons["selectionMethod"].tap()
    app.buttons[mode].tap()
    app.buttons["Done"].tap()
  }
  @MainActor private func message(_ app: XCUIApplication) -> String? {
    app.otherElements["communicationMessage"].value as? String
  }
  @MainActor private func capture(_ name: String, _ app: XCUIApplication) {
    let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    shot.name = name
    shot.lifetime = .keepAlways
    add(shot)
  }
}
