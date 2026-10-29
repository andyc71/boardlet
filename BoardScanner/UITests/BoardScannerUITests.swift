import XCTest

final class BoardScannerUITests: XCTestCase {
    @MainActor
    func testScanReviewEditSaveAndRestore() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--fresh-start"]
        app.launch()
        app.buttons["sampleBoard"].tap()
        let first = app.buttons["card_0_0"]
        XCTAssertTrue(first.waitForExistence(timeout: 45))
        XCTAssertEqual(first.label, "Water")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Recreated choice board"
        attachment.lifetime = .keepAlways
        add(attachment)
        app.tapBoardControl("toggleEditing")
        first.tap()
        let label = app.textFields["cardLabel"].exists ? app.textFields["cardLabel"] : app.textViews["cardLabel"]
        XCTAssertTrue(label.waitForExistence(timeout: 5))
        app.buttons["Clear label"].tap()
        label.tap()
        label.typeText("Drink")
        app.buttons["saveCard"].tap()
        XCTAssertTrue(first.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Card updated · Saved"].waitForExistence(timeout: 10))
        XCTAssertEqual(first.label, "Drink")
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Saved on this device"].waitForExistence(timeout: 10))
        app.buttons["Detection"].tap()
        XCTAssertTrue(app.images["detectionPreview"].waitForExistence(timeout: 5))
        app.terminate()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        XCTAssertTrue(app.buttons["card_0_0"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons["card_0_0"].label, "Drink")
    }
}
