import XCTest

/// Classic-only journeys. Delete this directory and the Classic test-plan entries to retire them.
@MainActor
final class ClassicInterfaceUITests: PECSTestsBase {
    override func setLaunchArguments() {
        super.setLaunchArguments()
        app.launchEnvironment["PECS_TEST_INTERFACE"] = "classic"
        app.launchArguments.append(LaunchArguments.autoFill)
    }

    func testClassicPhotosLayoutFormattingAndExport() {
        let menu = AccessibilityIdentifiers.MainMenu.self
        XCTAssertTrue(app.buttons[menu.selectLayoutButton].waitForExistence(timeout: 15))
        app.tapButton(id: menu.selectLayoutButton)
        app.tapButton(id: AccessibilityIdentifiers.LayoutScreen.seeAllButton)
        XCTAssertTrue(app.staticTexts["Recommended"].waitForExistence(timeout: 5))
        // The detail column's back button returns from All Layouts to Layout.
        app.navigationBars["Layouts"].buttons.element(boundBy: 0).tap()
        app.tapButton(id: AccessibilityIdentifiers.LayoutScreen.orientationButton(for: .landscape))
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.LayoutScreen.seeAllButton].exists)
        if !isSplitView { tapBackButton() }

        app.tapButton(id: isSplitView ? menu.selectPhotoButton : menu.changeSelectionsButton)
        let photos = AccessibilityIdentifiers.PhotoSelectionView.self
        let first = app.buttons[photos.image(for: 0)]
        XCTAssertTrue(first.waitForExistence(timeout: 10), app.debugDescription)
        first.tap()
        let title = app.textFields[AccessibilityIdentifiers.PhotoZoomView.titleField]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()
        title.clearText()
        title.typeText("Classic card")
        app.tapButton(id: AccessibilityIdentifiers.PhotoZoomView.saveButton)
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        XCTAssertTrue(first.label.contains("Classic card"))
        app.tapButton(id: photos.selectModeButton)
        first.tap()
        XCTAssertTrue(app.buttons[photos.duplicateButton].isEnabled)
        app.tapButton(id: photos.duplicateButton)
        app.tapButton(id: photos.closeSelectionButton)
        if !isSplitView { tapBackButton() }

        app.tapButton(id: menu.previewAndPrintButton)
        let preview = app.images[AccessibilityIdentifiers.PreviewScreen.previewImage(for: 0)]
        XCTAssertTrue(preview.waitForExistence(timeout: 10))
        if isSplitView {
            let layoutButton = app.buttons[menu.selectLayoutButton]
            XCTAssertTrue(layoutButton.isHittable, "Classic keeps its menu visible alongside the preview")
            XCTAssertGreaterThan(preview.frame.minX, layoutButton.frame.maxX)
        }
        app.tapButton(id: AccessibilityIdentifiers.PreviewScreen.formattingButton)
        let bold = app.switches[AccessibilityIdentifiers.FormattingView.CardSection.Font.bold]
        XCTAssertTrue(bold.waitForExistence(timeout: 5))
        bold.tap()
        app.tapButton(id: AccessibilityIdentifiers.FormattingView.doneButton)
        XCTAssertTrue(preview.waitForExistence(timeout: 10))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Classic preview and persistent iPad menu"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.tapButton(id: AccessibilityIdentifiers.PreviewScreen.saveAndPrintButton)
        let printActivity = app.cells["Print"]
        XCTAssertTrue(printActivity.waitForExistence(timeout: 15), app.debugDescription)
        printActivity.tap()
        XCTAssertTrue(app.navigationBars.buttons["Print"].waitForExistence(timeout: 15), app.debugDescription)
    }

    func testClassicChoiceBoardAvailabilityAndReturn() {
        guard easyPECSAppType == .plus else {
            XCTAssertFalse(app.buttons[AccessibilityIdentifiers.TopicTitleView.choiceBoardButton].exists)
            return
        }
        app.tapButton(id: AccessibilityIdentifiers.TopicTitleView.choiceBoardButton)
        app.tapButton(id: AccessibilityIdentifiers.TopicTitleView.pecsMakerButton)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.MainMenu.selectLayoutButton].waitForExistence(timeout: 5))
    }
}
