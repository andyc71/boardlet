import XCTest
import UIKit

/// Classic-only journeys. Delete this directory and the Classic test-plan entries to retire them.
@MainActor
final class ClassicInterfaceUITests: PECSTestsBase {
    override func setLaunchArguments() {
        super.setLaunchArguments()
        // The rotation case measures the full page; other cases exercise split columns.
        // Neither should inherit presentation from a previous simulator session.
        let maximized = name.contains("testPageLayoutColumnsAndBoardTitlePersistence")
        app.launchArguments += ["-isTopicSelectionMaximized", maximized ? "YES" : "NO"]
        app.launchEnvironment["PECS_TEST_INTERFACE"] = "classic"
        app.launchArguments.append(LaunchArguments.autoFill)
    }

    func testPageLayoutColumnsAndBoardTitlePersistence() {
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = requiredOrientation }
        app.tapButton(id: AccessibilityIdentifiers.MainMenu.selectLayoutButton)
        selectPaperMedium()

        let showTitles = app.switches["LayoutScreen.showTitles"]
        for _ in 0..<4 where !showTitles.isHittable { app.swipeUp() }
        XCTAssertTrue(showTitles.waitForExistence(timeout: 5))
        let originalValue = showTitles.value as? String
        showTitles.tap()
        let changedValue = showTitles.value as? String
        XCTAssertNotEqual(originalValue, changedValue)

        XCUIDevice.shared.orientation = .landscapeLeft
        let ids = AccessibilityIdentifiers.LayoutScreen.self
        let pageSize = app.staticTexts[ids.pageSizeHeading]
        let designs = app.staticTexts[ids.layoutHeading]
        let columns = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            pageSize.exists && designs.exists && designs.frame.minX > pageSize.frame.maxX
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [columns], timeout: 10), .completed)
        XCTAssertEqual(showTitles.value as? String, changedValue)

        XCUIDevice.shared.orientation = .portrait
        let stacked = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            pageSize.exists && designs.exists && designs.frame.minX < pageSize.frame.maxX
                && designs.frame.minY > pageSize.frame.maxY
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [stacked], timeout: 10), .completed)
        tapBackButton()
        app.tapButton(id: AccessibilityIdentifiers.MainMenu.selectLayoutButton)
        selectPaperMedium()
        for _ in 0..<4 where !showTitles.isHittable { app.swipeUp() }
        XCTAssertEqual(showTitles.value as? String, changedValue)
        showTitles.tap()
    }

    func testClassicAddPhotosMenuShowsSharedSources() {
        let mainMenu = AccessibilityIdentifiers.MainMenu.self
        app.tapButton(id: isSplitView ? mainMenu.selectPhotoButton : mainMenu.changeSelectionsButton)
        let menu = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.menuButton]
        XCTAssertTrue(menu.waitForExistence(timeout: 10))
        menu.tap()

        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoSelectionView.addMorePhotosButton]
            .waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons[isSpanish ? "Símbolo" : "Symbol"].exists)
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
        app.tapButton(id: AccessibilityIdentifiers.PhotoZoomView.cancelButton)
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        app.tapButton(id: photos.selectModeButton)
        first.tap()
        XCTAssertTrue(app.buttons[photos.duplicateButton].isEnabled)
        app.tapButton(id: photos.duplicateButton)
        app.tapButton(id: photos.closeSelectionButton)
        if !isSplitView { tapBackButton() }

        let previewButton = app.buttons[menu.previewAndPrintButton]
        for _ in 0..<3 where !previewButton.isHittable {
            let back = app.navigationBars.buttons[backButtonName]
            if (app.navigationBars["Page Layout"].exists || app.navigationBars["Photos"].exists),
               back.exists {
                back.tap()
            }
        }
        let openedFromPortrait = !previewButton.isHittable && requiredOrientation.isLandscape
        if openedFromPortrait {
            XCUIDevice.shared.orientation = .portrait
            let portrait = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                self.app.frame.height > self.app.frame.width
            }, object: nil)
            XCTAssertEqual(XCTWaiter.wait(for: [portrait], timeout: 10), .completed)
        }
        XCTAssertTrue(previewButton.isHittable, app.debugDescription)
        previewButton.tap()
        if openedFromPortrait {
            XCUIDevice.shared.orientation = requiredOrientation
            let landscape = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                self.app.frame.width > self.app.frame.height
            }, object: nil)
            XCTAssertEqual(XCTWaiter.wait(for: [landscape], timeout: 10), .completed)
        }
        let preview = app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier BEGINSWITH 'PreviewScreen.previewImage.'"
        )).firstMatch
        XCTAssertTrue(preview.waitForExistence(timeout: 20), app.debugDescription)
        if isSplitView {
            let layoutButton = app.buttons[menu.selectLayoutButton]
            XCTAssertTrue(layoutButton.isHittable, "Classic keeps its menu visible alongside the preview")
            XCTAssertGreaterThan(preview.frame.minX, layoutButton.frame.maxX)
        }
        app.tapButton(id: AccessibilityIdentifiers.PreviewScreen.formattingButton)
        let bold = app.switches[AccessibilityIdentifiers.FormattingView.BoardSection.Font.bold]
        XCTAssertTrue(bold.waitForExistence(timeout: 5), app.debugDescription)
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
        XCTAssertTrue(printActivity.isHittable)
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
        let rename = app.buttons.matching(NSPredicate(
            format: "identifier == %@ OR label == 'Rename' OR label == 'Renombrar'",
            AccessibilityIdentifiers.TopicTitleView.renameButton
        )).firstMatch
        XCTAssertTrue(rename.waitForExistence(timeout: 5), app.debugDescription)
        rename.tap()

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
            if isSplitView {
                if !board.isHittable { tapSidebarButton() }
            } else {
                let mainMenuBackButton = app.buttons[backButtonName]
                XCTAssertTrue(mainMenuBackButton.waitForExistence(timeout: 5), app.debugDescription)
                mainMenuBackButton.tap()
            }
        }

        XCTAssertTrue(board.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(app.buttons[topics.menuButton].waitForExistence(timeout: 5),
                      "The Boards toolbar must include More")
        app.tapButton(id: topics.menuButton)
        XCTAssertTrue(app.buttons[topics.selectButton].waitForExistence(timeout: 5),
                      "The Boards More menu must include Select")
        app.tapButton(id: topics.selectButton)
        let done = app.buttons[topics.closeSelectionButton]
        if done.waitForExistence(timeout: 2) {
            done.tap()
        } else {
            // The narrow iPad sidebar can move Done into its native overflow menu.
            let overflow = app.navigationBars.buttons.matching(identifier: "OverflowBarButtonItem")
                .allElementsBoundByIndex.min { $0.frame.minX < $1.frame.minX }
            XCTAssertNotNil(overflow, app.debugDescription)
            overflow?.tap()
            let action = app.buttons.matching(NSPredicate(
                format: "identifier == %@ OR label IN %@", topics.closeSelectionButton, ["Done", "Listo"]
            )).firstMatch
            XCTAssertTrue(action.waitForExistence(timeout: 5), app.debugDescription)
            action.tap()
        }
        if !isSplitView {
            XCTAssertFalse(mainMenuButton.exists, "The collapsed split view must be showing Boards")
        }

        board.tap()

        XCTAssertTrue(mainMenuButton.waitForExistence(timeout: 10),
                      "Tapping a board must navigate to its Classic main menu")

        for identifier in ["BoardHierarchy.home", "BoardHierarchy.search", "BoardHierarchy.organize"] {
            XCTAssertFalse(app.buttons[identifier].exists,
                           "The Classic main menu must hide \(identifier)")
        }

        let photoButtonID = isSplitView
            ? AccessibilityIdentifiers.MainMenu.selectPhotoButton
            : AccessibilityIdentifiers.MainMenu.changeSelectionsButton
        XCTAssertTrue(app.buttons[photoButtonID].waitForExistence(timeout: 5),
                      "The compact Classic menu must show its photo preview card")
        app.tapButton(id: photoButtonID)

        let selectButton = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.selectModeButton]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertEqual(selectButton.label, "Select")

        if isSplitView {
            XCTAssertTrue(mainMenuButton.isHittable,
                          "The Classic menu must stay visible beside Photos")
        } else {
            let backButtons = app.navigationBars.buttons.matching(identifier: "chevron.left")
            XCTAssertEqual(backButtons.count, 1,
                           "The collapsed Classic photos screen must include exactly one Back button")
            let backButton = backButtons.element(boundBy: 0)
            backButton.tap()
            XCTAssertTrue(mainMenuButton.waitForExistence(timeout: 10),
                          "Back must return to the Classic main menu")
        }
    }

    func testClassicCompactHeightMenuAndDirectPhotoEditing() throws {
        try XCTSkipIf(UIDevice.current.userInterfaceIdiom == .pad,
                      "The compact-height menu is a phone layout.")
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = requiredOrientation }
        let menu = AccessibilityIdentifiers.MainMenu.self
        let photo = app.buttons.matching(NSPredicate(
            format: "identifier BEGINSWITH %@", "ClassicMainMenu.photo."
        )).firstMatch
        let layout = app.buttons[menu.selectLayoutButton]
        XCTAssertTrue(photo.waitForExistence(timeout: 15))
        let photoID = photo.identifier

        XCUIDevice.shared.orientation = .landscapeLeft
        let sideBySide = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            photo.exists && layout.exists && layout.frame.minX > photo.frame.maxX
                && abs(layout.frame.minY - photo.frame.minY) < 150
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [sideBySide], timeout: 10), .completed)
        photo.tap()
        XCTAssertTrue(app.textFields[AccessibilityIdentifiers.PhotoZoomView.titleField]
            .waitForExistence(timeout: 10))
        app.tapButton(id: AccessibilityIdentifiers.PhotoZoomView.cancelButton)
        XCTAssertTrue(app.buttons[photoID].waitForExistence(timeout: 10))
        XCTAssertTrue(layout.exists, "Closing the editor must return directly to Main Menu.")

        XCUIDevice.shared.orientation = .portrait
        let stacked = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            photo.exists && layout.exists && layout.frame.minY > photo.frame.maxY
                && layout.frame.minX < photo.frame.maxX
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [stacked], timeout: 10), .completed)
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
        XCTAssertTrue(app.buttons[isSplitView ? menu.selectPhotoButton : menu.changeSelectionsButton]
            .waitForExistence(timeout: 5))
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
