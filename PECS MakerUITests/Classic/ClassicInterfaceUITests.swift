import XCTest
import UIKit

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

    func testRenamePresentsBoardDetailsSheet() {
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.TopicTitleView.changeTopicImageButton].exists)
        app.tapButton(id: AccessibilityIdentifiers.TopicTitleView.menuButton)
        app.tapButton(id: AccessibilityIdentifiers.TopicTitleView.renameButton)

        XCTAssertTrue(app.sheets.firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(app.navigationBars["Board Details"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoZoomView.replaceButton].exists)
        XCTAssertTrue(app.textFields[AccessibilityIdentifiers.PhotoZoomView.titleField].exists)
        app.tapButton(id: AccessibilityIdentifiers.PhotoZoomView.cancelButton)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.MainMenu.selectLayoutButton]
            .waitForExistence(timeout: 5))
    }

    func testClassicBoardsToolbarAndNavigation() {
        let topics = AccessibilityIdentifiers.TopicSelectionView.self
        let board = app.buttons[topics.topicButton(for: 0)]
        let mainMenuButton = app.buttons[AccessibilityIdentifiers.MainMenu.selectLayoutButton]

        if mainMenuButton.exists {
            let mainMenuBackButton = app.buttons[backButtonName]
            XCTAssertTrue(mainMenuBackButton.waitForExistence(timeout: 5), app.debugDescription)
            mainMenuBackButton.tap()
        }

        XCTAssertTrue(board.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(app.buttons[topics.menuButton].waitForExistence(timeout: 5),
                      "The Boards toolbar must include More")
        XCTAssertTrue(app.buttons[topics.selectButton].waitForExistence(timeout: 5),
                      "The Boards toolbar must include Select")
        XCTAssertFalse(mainMenuButton.exists, "The collapsed split view must be showing Boards")

        board.tap()

        XCTAssertTrue(mainMenuButton.waitForExistence(timeout: 10),
                      "Tapping a board must navigate to its Classic main menu")

        let photoButtonID = isSplitView
            ? AccessibilityIdentifiers.MainMenu.selectPhotoButton
            : AccessibilityIdentifiers.MainMenu.changeSelectionsButton
        XCTAssertTrue(app.buttons[photoButtonID].waitForExistence(timeout: 5),
                      "The compact Classic menu must show its photo preview card")
        app.tapButton(id: photoButtonID)

        let selectButton = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.selectModeButton]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertEqual(selectButton.label, "Select")

        let backButtons = app.navigationBars.buttons.matching(identifier: "chevron.left")
        XCTAssertEqual(backButtons.count, 1,
                       "The collapsed Classic photos screen must include exactly one Back button")
        let backButton = backButtons.element(boundBy: 0)
        backButton.tap()
        XCTAssertTrue(mainMenuButton.waitForExistence(timeout: 10),
                      "Back must return to the Classic main menu")
    }

    func testClassicMainMenuHidesPlaceholderThumbnails() throws {
        app.terminate()

        let topicsDirectory = tempDir.appendingPathComponent("topics", isDirectory: true)
        let topicDirectories = try FileManager.default.contentsOfDirectory(
            at: topicsDirectory,
            includingPropertiesForKeys: [.isDirectoryKey]
        )
        let indexURL = try XCTUnwrap(topicDirectories
            .map { $0.appendingPathComponent("index.json") }
            .first { FileManager.default.fileExists(atPath: $0.path) })

        var repository = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(contentsOf: indexURL)) as? [String: Any]
        )
        var photos = try XCTUnwrap(repository["photos"] as? [String: Any])
        var photoItems = try XCTUnwrap(photos["photoItems"] as? [[String: Any]])
        let realPhotoCount = photoItems.filter { ($0["isPlaceholder"] as? Bool) != true }.count
        XCTAssertGreaterThan(realPhotoCount, 1)

        let placeholderID = UUID().uuidString
        let placeholderFileName = "PhotoItem-\(placeholderID).png"
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        let placeholderImage = renderer.image { _ in }
        try XCTUnwrap(placeholderImage.pngData()).write(
            to: indexURL.deletingLastPathComponent().appendingPathComponent(placeholderFileName)
        )

        var placeholder = photoItems[0]
        placeholder["id"] = placeholderID
        placeholder["imageFileName"] = placeholderFileName
        placeholder["title"] = NSNull()
        placeholder["assetId"] = NSNull()
        placeholder["audioFileName"] = NSNull()
        placeholder["isPlaceholder"] = true
        photoItems.insert(placeholder, at: 1)
        photos["photoItems"] = photoItems
        repository["photos"] = photos
        try JSONSerialization.data(withJSONObject: repository).write(to: indexURL, options: .atomic)

        XCTAssertEqual(photoItems.count, realPhotoCount + 1)
        XCTAssertEqual(photoItems.filter { ($0["isPlaceholder"] as? Bool) == true }.count, 1)

        app.launch()

        let menu = AccessibilityIdentifiers.MainMenu.self
        XCTAssertTrue(app.buttons[menu.selectLayoutButton].waitForExistence(timeout: 15), app.debugDescription)
        XCTAssertTrue(app.buttons[menu.changeSelectionsButton].waitForExistence(timeout: 5))
        let status = app.staticTexts.matching(NSPredicate(
            format: "label CONTAINS[c] %@", "\(realPhotoCount) photos selected"
        )).firstMatch
        XCTAssertTrue(status.waitForExistence(timeout: 5), app.debugDescription)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Classic main menu without placeholder thumbnails"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}
