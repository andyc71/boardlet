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
        selectEditorLayout(PageLayout(width: 3, height: 4), orientation: .portrait)

        openConfiguration()
        app.buttons["Classic"].tap()
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.MainMenu.selectLayoutButton].waitForExistence(timeout: 10))
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "PECS_TEST_INTERFACE")
        app.launch()
        let classicLayout = app.buttons[AccessibilityIdentifiers.MainMenu.selectLayoutButton]
        XCTAssertTrue(classicLayout.waitForExistence(timeout: 15), "Classic must persist after relaunch")
        XCTAssertTrue((classicLayout.value as? String ?? "").contains("3 × 4"),
                      "Changing interface must preserve the board layout")
        app.tapButton(id: isSplitView ? AccessibilityIdentifiers.MainMenu.selectPhotoButton : AccessibilityIdentifiers.MainMenu.changeSelectionsButton)
        XCTAssertTrue(first.waitForExistence(timeout: 10))
        if !isSplitView { tapBackButton() }
        openConfiguration()
        app.buttons["New (default)"].tap()
        XCTAssertTrue(first.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoSelectionView.layoutButton].exists)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.MainMenu.previewAndPrintButton].exists)
        app.terminate()
        app.launch()
        XCTAssertTrue(first.waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.MainMenu.previewAndPrintButton].exists)
    }

    func testNewEditorPrintOpensClassicPreview() {
        let printButton = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.printButton]
        XCTAssertTrue(printButton.waitForExistence(timeout: 15))
        printButton.tap()

        let preview = app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier BEGINSWITH 'PreviewScreen.previewImage.'"
        )).firstMatch
        XCTAssertTrue(preview.waitForExistence(timeout: 20), app.debugDescription)
        app.tapButton(id: AccessibilityIdentifiers.PreviewScreen.formattingButton)
        XCTAssertTrue(app.switches[AccessibilityIdentifiers.FormattingView.BoardSection.Font.bold]
            .waitForExistence(timeout: 5))
        app.tapButton(id: AccessibilityIdentifiers.FormattingView.doneButton)
        XCTAssertTrue(preview.waitForExistence(timeout: 10))
        app.tapButton(id: AccessibilityIdentifiers.PreviewScreen.saveAndPrintButton)
        XCTAssertTrue(app.cells["Print"].waitForExistence(timeout: 15), app.debugDescription)
    }

    private func openConfiguration() {
        let menu = app.buttons[AccessibilityIdentifiers.TopicTitleView.menuButton]
        if menu.exists {
            menu.tap()
        } else {
            let overflow = app.navigationBars.buttons.matching(NSPredicate(
                format: "label == 'More' OR label == 'Más' OR label == 'More Actions'"
            )).firstMatch
            XCTAssertTrue(overflow.waitForExistence(timeout: 5), app.debugDescription)
            overflow.tap()
        }
        let settings = app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier == %@ OR label == 'Settings' OR label == 'Configuration'",
            AccessibilityIdentifiers.MainMenu.settingsButton
        )).firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 5), app.debugDescription)
        settings.tap()
        XCTAssertTrue(app.buttons["Classic"].waitForExistence(timeout: 5), app.debugDescription)
    }
}
