import XCTest

final class BoardletUITests: XCTestCase {
    @MainActor func app(_ suffix: String = "") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launchEnvironment["BOARDLET_TEST_RUN"] = UUID().uuidString + suffix
        app.launch()
        return app
    }
    @MainActor func testCreateEditUsePrintAndReopen() async throws {
        let app = app()
        XCTAssertTrue(app.buttons["newBoard"].waitForExistence(timeout: 10)); app.buttons["newBoard"].tap()
        app.textFields["boardName"].tap(); app.textFields["boardName"].typeText("Native routine\n")
        app.buttons["template-Routine"].tap(); XCTAssertEqual(app.buttons["template-Routine"].value as? String, "Selected"); attach("New board template", app: app); app.buttons["createBoard"].tap()
        XCTAssertTrue(app.buttons["useBoard"].waitForExistence(timeout: 5))
        attach("Editor portrait", app: app)
        app.buttons["boardControls"].tap(); app.buttons["Board controls"].tap()
        XCTAssertTrue(app.buttons["closeBoardControls"].waitForExistence(timeout: 5)); attach("Board controls", app: app)
        app.buttons["closeBoardControls"].tap()
        app.buttons["useBoard"].tap()
        let card = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'speakCard-'")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 5)); card.tap()
        XCUIDevice.shared.orientation = .landscapeLeft
        try await waitForOrientation(app, landscape: true)
        XCTAssertTrue(app.buttons["exitUse"].waitForExistence(timeout: 5)); attach("Communication landscape", app: app)
        app.buttons["exitUse"].tap()
        XCUIDevice.shared.orientation = .portrait
        try await waitForOrientation(app, landscape: false)
        app.buttons["printBoard"].tap()
        XCTAssertTrue(app.buttons["Share PDF"].waitForExistence(timeout: 5)); attach("Native PDF preview", app: app)
        app.buttons["closePrint"].tap()
        app.terminate(); app.launch()
        XCTAssertTrue(app.buttons["board-Native routine"].waitForExistence(timeout: 10)); attach("Library restored", app: app)
    }
    @MainActor func testBlankAddAndBulkLabel() throws {
        let app = app()
        XCTAssertTrue(app.buttons["newBoard"].waitForExistence(timeout: 10)); app.buttons["newBoard"].tap(); app.buttons["createBoard"].tap()
        XCTAssertTrue(app.buttons["addCards"].waitForExistence(timeout: 5)); app.buttons["addCards"].tap()
        app.segmentedControls.buttons["Photos"].tap(); app.buttons["Choose photos"].tap()
        let pickerCancel = app.buttons.matching(NSPredicate(format: "label == 'Cancel' AND identifier != 'cancelAdd'")).firstMatch
        XCTAssertTrue(pickerCancel.waitForExistence(timeout: 5)); attach("Shared system photo picker", app: app)
        pickerCancel.tap()
        XCTAssertTrue(pickerCancel.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.segmentedControls.buttons["Text"].waitForExistence(timeout: 5))
        app.segmentedControls.buttons["Text"].tap(); app.buttons["Add a text card"].tap(); app.buttons["confirmAdd"].tap()
        let card = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'editCard-'")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 5)); card.tap()
        let field = app.descendants(matching: .any).matching(identifier: "cardLabel").firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5)); field.tap(); field.typeText(" · Necesito ayuda por favor")
        attach("Card details and keyboard", app: app)
    }
    @MainActor func testSpanishLargeTextAndKeyboard() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "-AppleLanguages", "(es)", "-AppleLocale", "es_ES", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launchEnvironment["BOARDLET_TEST_RUN"] = UUID().uuidString
        app.launch()
        XCTAssertTrue(app.buttons["newBoard"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.navigationBars["Tableros"].exists)
        attach("Spanish library large type", app: app)
        app.buttons["newBoard"].tap()
        app.textFields["boardName"].tap(); app.textFields["boardName"].typeText("Necesito ayuda para preparar el desayuno\n")
        app.buttons["createBoard"].tap()
        XCTAssertTrue(app.buttons["addCards"].waitForExistence(timeout: 5))
        attach("Spanish empty editor large type", app: app)
        app.buttons["addCards"].tap()
        app.segmentedControls.buttons["Texto"].tap(); app.buttons["Añadir tarjeta de texto"].tap(); app.buttons["confirmAdd"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'editCard-'")).firstMatch.waitForExistence(timeout: 5))
        attach("Spanish card large type", app: app)
        app.swipeUp(); attach("Spanish card actions large type", app: app)
    }
    @MainActor func waitForOrientation(_ app: XCUIApplication, landscape: Bool) async throws {
        let deadline = Date().addingTimeInterval(5)
        while (app.frame.width > app.frame.height) != landscape && Date() < deadline { try await Task.sleep(for: .milliseconds(100)) }
        XCTAssertEqual(app.frame.width > app.frame.height, landscape)
        // A matching frame can precede the end of UIKit's rotation animation.
        try await Task.sleep(for: .milliseconds(400))
    }
    @MainActor func attach(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
