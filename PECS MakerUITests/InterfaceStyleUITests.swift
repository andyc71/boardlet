import XCTest

@MainActor
final class InterfaceStyleUITests: PECSTestsBase {
    override func setLaunchArguments() {
        super.setLaunchArguments()
        app.launchArguments.append(LaunchArguments.autoFill)
    }

    func testDefaultSwitchPersistenceAndSharedBoard() {
        let first = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.image(for: 0)]
        XCTAssertTrue(first.waitForExistence(timeout: 15), "An unset preference must open the new editor")
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.MainMenu.previewAndPrintButton].exists)
        first.tap()
        let title = app.textFields[AccessibilityIdentifiers.PhotoZoomView.titleField]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()
        title.clearText()
        title.typeText("Shared card")
        app.tapButton(id: AccessibilityIdentifiers.PhotoZoomView.saveButton)

        openConfiguration()
        app.buttons["Classic"].tap()
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.MainMenu.selectLayoutButton].waitForExistence(timeout: 10))
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "PECS_TEST_INTERFACE")
        app.launch()
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.MainMenu.selectLayoutButton].waitForExistence(timeout: 15), "Classic must persist after relaunch")
        app.tapButton(id: isSplitView ? AccessibilityIdentifiers.MainMenu.selectPhotoButton : AccessibilityIdentifiers.MainMenu.changeSelectionsButton)
        XCTAssertTrue(first.waitForExistence(timeout: 10))
        XCTAssertTrue(first.label.contains("Shared card"), "Changing interface must preserve edits")
        if !isSplitView { tapBackButton() }
        openConfiguration()
        app.buttons["New (default)"].tap()
        XCTAssertTrue(first.waitForExistence(timeout: 10))
        XCTAssertTrue(first.label.contains("Shared card"))
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoSelectionView.layoutButton].exists)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.MainMenu.previewAndPrintButton].exists)
        app.terminate()
        app.launch()
        XCTAssertTrue(first.waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.MainMenu.previewAndPrintButton].exists)
    }

    private func openConfiguration() {
        app.tapButton(id: AccessibilityIdentifiers.TopicTitleView.menuButton)
        app.tapButton(id: AccessibilityIdentifiers.MainMenu.settingsButton)
        XCTAssertTrue(app.buttons["Classic"].waitForExistence(timeout: 5), app.debugDescription)
    }
}
