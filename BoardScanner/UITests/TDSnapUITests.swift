import XCTest

final class TDSnapUITests: XCTestCase {
    @MainActor
    func testFilePickerSwitchesBetweenBoardAndSymbolImports() throws {
        continueAfterFailure = false
        let url = try SnapTestFixture.make()
        defer { try? FileManager.default.removeItem(at: url) }
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--fresh-start", "--library-id", UUID().uuidString,
                               "--import-test-document", url.path]
        app.launch()
        app.setWindowOrientation(.landscapeLeft)
        app.setWindowOrientation(.portrait)
        let title = app.staticTexts["snapPageTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 20))
        app.tapBoardControl("toggleEditing")
        for symbols in [false, true, false] {
            if symbols {
                app.buttons["pageOptions"].tap()
                app.buttons["importSymbolLibrary"].tap()
            } else {
                app.buttons["Files"].tap()
            }
            let cancel = app.buttons["Cancel"]
            XCTAssertTrue(cancel.waitForExistence(timeout: 10))
            cancel.tap()
            XCTAssertTrue(cancel.waitForNonExistence(timeout: 5))
            XCTAssertFalse(app.alerts["Board Scanner"].exists)
            XCTAssertEqual(title.label, "Home")
        }
    }

    @MainActor
    func testImportNavigateAllPagesAndRestore() throws {
        let url = try SnapTestFixture.make()
        defer { try? FileManager.default.removeItem(at: url) }
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--fresh-start", "--import-test-document", url.path]
        app.launch()
        let title = app.staticTexts["snapPageTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 20))
        XCTAssertEqual(title.label, "Home")
        app.buttons["snapButton_1"].tap()
        XCTAssertEqual(title.label, "Child")
        app.buttons["snapButton_2"].tap()
        XCTAssertTrue(app.staticTexts["Linked pages"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Page unavailable: missing"].exists)
        app.buttons["Shared"].tap()
        XCTAssertEqual(title.label, "Shared")
        app.buttons["snapButton_3"].tap()
        XCTAssertEqual(title.label, "Child")
        app.buttons["pageBack"].tap()
        XCTAssertEqual(title.label, "Shared")
        app.buttons["pageHome"].tap()
        XCTAssertEqual(title.label, "Home")
        app.buttons["allPages"].tap()
        app.buttons["snapPage_orphan"].tap()
        XCTAssertEqual(title.label, "Unlinked")
        app.tapBoardControl("toggleEditing")
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Saved on this device"].waitForExistence(timeout: 10))
        app.terminate()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        XCTAssertTrue(title.waitForExistence(timeout: 15))
        XCTAssertEqual(title.label, "Home")
        app.buttons["allPages"].tap()
        XCTAssertTrue(app.buttons["snapPage_orphan"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Imported TD Snap hierarchy"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testSuppliedPageSetBrowser() throws {
        guard let path = ProcessInfo.processInfo.environment["TD_SNAP_FIXTURE"], !path.isEmpty else {
            throw XCTSkip("Set TD_SNAP_FIXTURE to check the supplied page set in the UI.")
        }
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--fresh-start", "--library-id", UUID().uuidString,
                               "--import-test-document", path]
        app.launch()
        app.setWindowOrientation(.landscapeLeft)
        app.setWindowOrientation(.portrait)
        let title = app.staticTexts["snapPageTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 30))
        XCTAssertEqual(title.label, "Home Page")
        app.tapBoardControl("toggleEditing")
        let warning = app.buttons["snapImportWarning"]
        XCTAssertTrue(warning.exists)
        XCTAssertFalse(warning.label.contains("links"), warning.label)
        warning.tap()
        XCTAssertTrue(app.staticTexts["snapNavigationSummary"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["snapNavigationSummary"].label, "0 page links have unavailable destinations.")
        app.buttons["Done"].tap()
        app.tapBoardControl("toggleEditing")
        app.buttons["snapButton_2805"].tap()
        let typedMessage = app.descendants(matching: .any).matching(identifier: "typedMessage").firstMatch
        XCTAssertTrue(typedMessage.waitForExistence(timeout: 5), "The source Keyboard command must open the message editor")
        app.buttons["Cancel"].tap()
        let home = XCTAttachment(screenshot: app.screenshot())
        home.name = "Supplied TD Snap home page"
        home.lifetime = .keepAlways
        add(home)
        app.buttons["allPages"].tap()
        XCTAssertTrue(app.navigationBars["All 307 pages"].waitForExistence(timeout: 5))
        let search = app.searchFields.firstMatch
        search.tap()
        search.typeText("Food & Drink\n")
        app.buttons["snapPage_392b8b8b-ec1e-4b27-a9aa-dadf8aa82207"].tap()
        XCTAssertTrue(app.navigationBars["All 307 pages"].waitForNonExistence(timeout: 10))
        expectation(for: NSPredicate(format: "label == 'Food & Drink'"), evaluatedWith: title)
        waitForExpectations(timeout: 10)
        XCTAssertEqual(title.label, "Food & Drink")
        let destination = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        destination.name = "Supplied Food and Drink page after browser dismissal"
        destination.lifetime = .keepAlways
        add(destination)
        let importedHome = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'snapButton_' AND label == 'Home'")
        ).firstMatch
        XCTAssertTrue(importedHome.exists)
        importedHome.tap()
        expectation(for: NSPredicate(format: "label == 'Home Page'"), evaluatedWith: title)
        waitForExpectations(timeout: 10)
        XCTAssertEqual(title.label, "Home Page")
    }

    @MainActor
    func testSuppliedLibraryRecoverySaveAndRestore() throws {
        let env = ProcessInfo.processInfo.environment
        guard let input = env["TD_SNAP_FIXTURE"], !input.isEmpty,
              let library = env["TD_SYMBOL_LIBRARY"], !library.isEmpty else {
            throw XCTSkip("Supply the local page set and symbol library")
        }
        continueAfterFailure = false
        let libraryID = UUID().uuidString
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--library-id", libraryID, "--fresh-start", "--import-test-document", input, "--symbol-library", library]
        app.launch()
        app.setWindowOrientation(.landscapeLeft)
        app.setWindowOrientation(.portrait)
        let title = app.staticTexts["snapPageTitle"]
        guard title.waitForExistence(timeout: 40) else {
            let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            screenshot.name = "Supplied import did not reach its home page"
            screenshot.lifetime = .keepAlways
            add(screenshot)
            let hierarchy = XCTAttachment(string: app.debugDescription)
            hierarchy.lifetime = .keepAlways
            add(hierarchy)
            XCTFail("Supplied import did not reach its home page within 40 seconds")
            return
        }
        XCTAssertEqual(title.label, "Home Page")
        func retainArtwork(_ name: String) {
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = name
            shot.lifetime = .keepAlways
            add(shot)
        }
        for id in ["2804", "2805", "2806"] {
            XCTAssertTrue(app.buttons["snapButton_" + id].isHittable, id)
        }
        retainArtwork("White action symbols on Home Page — portrait")
        let dashboard = app.buttons["snapButton_2807"]
        let viewport = app.scrollViews["snapGrid"]
        for _ in 0..<4 {
            if viewport.frame.contains(dashboard.frame) { break }
            let start = viewport.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
            let end = viewport.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.5)
        }
        XCTAssertTrue(dashboard.isHittable, "Dashboard is on the fourth row of the source grid")
        XCTAssertTrue(viewport.frame.contains(dashboard.frame), "Retain the whole Dashboard glyph and label")
        retainArtwork("White Dashboard symbol after scrolling")
        app.scrollViews["snapGrid"].swipeDown()
        app.setWindowOrientation(.landscapeLeft)
        XCTAssertTrue(app.buttons["snapButton_2804"].isHittable)
        retainArtwork("White action symbols on Home Page — landscape")
        app.setWindowOrientation(.portrait)
        app.tapBoardControl("toggleEditing")
        XCTAssertEqual(app.buttons["snapImportWarning"].label, "1 unavailable image")
        app.buttons["Options"].tap()
        XCTAssertTrue(app.buttons["importSymbolLibrary"].waitForExistence(timeout: 5))
        app.buttons["Import details"].tap()
        let summary = app.staticTexts["snapArtworkSummary"]
        XCTAssertTrue(summary.waitForExistence(timeout: 5))
        XCTAssertEqual(summary.label.replacingOccurrences(of: ",", with: ""), "2911 embedded assets rendered; 0 unavailable embedded assets; 1 buttons reference absent assets.")
        app.buttons["Done"].tap()
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Saved on this device"].waitForExistence(timeout: 20))
        app.terminate()
        app.launchArguments = ["--ui-testing", "--library-id", libraryID]
        app.launch()
        XCTAssertTrue(title.waitForExistence(timeout: 30))
        XCTAssertEqual(title.label, "Home Page")
        app.tapBoardControl("toggleEditing")
        XCTAssertEqual(app.buttons["snapImportWarning"].label, "1 unavailable image")
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "Recovered TD Snap library artwork"
        shot.lifetime = .keepAlways
        add(shot)
        app.tapBoardControl("toggleEditing")
        app.buttons["allPages"].tap()
        let search = app.searchFields.firstMatch
        search.tap()
        search.typeText("Food & Drink\n")
        app.buttons["snapPage_392b8b8b-ec1e-4b27-a9aa-dadf8aa82207"].tap()
        XCTAssertTrue(app.navigationBars["All 307 pages"].waitForNonExistence(timeout: 10))
        let importedHome = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'snapButton_' AND label == 'Home'")
        ).firstMatch
        XCTAssertTrue(importedHome.isHittable)
        retainArtwork("White Home card after saved-board reopening")
        importedHome.tap()
        expectation(for: NSPredicate(format: "label == 'Home Page'"), evaluatedWith: title)
        waitForExpectations(timeout: 10)
        // A fresh import after relaunch must use the remembered library without a library argument.
        app.terminate()
        app.launchArguments = ["--ui-testing", "--library-id", libraryID,
                               "--import-test-document", input]
        app.launch()
        XCTAssertTrue(title.waitForExistence(timeout: 40))
        app.tapBoardControl("toggleEditing")
        XCTAssertEqual(app.buttons["snapImportWarning"].label, "1 unavailable image")
    }

}
