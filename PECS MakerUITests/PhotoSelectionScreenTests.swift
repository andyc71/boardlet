//
//  PhotoSelectionTests.swift
//  PhotoSelectionTests
//
//  Created by Andy on 22/12/2022.
//

import XCTest

class PhotoSelectionScreenTests: PECSTestsBase {

    @MainActor func testBoardTitleOpensDetailsAndSavesFromSheet() {
        let boardTitle = app.buttons[AccessibilityIdentifiers.TopicTitleView.titleField]
        XCTAssertTrue(boardTitle.waitForExistence(timeout: 10))
        boardTitle.tap()

        XCTAssertTrue(app.navigationBars[isSpanish ? "Renombrar tema" : "Rename Topic"].waitForExistence(timeout: 10))
        let titleField = app.textFields[AccessibilityIdentifiers.PhotoZoomView.titleField]
        XCTAssertTrue(titleField.exists)
        titleField.tap()
        titleField.clearText()
        titleField.typeText("Renamed board")
        app.tapButton(id: AccessibilityIdentifiers.PhotoZoomView.saveButton)

        XCTAssertTrue(boardTitle.waitForExistence(timeout: 10))
        XCTAssertTrue(boardTitle.label.contains("Renamed board"))
        XCTAssertFalse(app.navigationBars[isSpanish ? "Renombrar tema" : "Rename Topic"].exists)
    }

    @MainActor func testBoardDetailsCoverUsesPageAspectRatio() {
        let boardTitle = app.buttons[AccessibilityIdentifiers.TopicTitleView.titleField]
        XCTAssertTrue(boardTitle.waitForExistence(timeout: 10))
        boardTitle.tap()

        XCTAssertTrue(app.navigationBars[isSpanish ? "Renombrar tema" : "Rename Topic"].waitForExistence(timeout: 10))
        let cover = app.descendants(matching: .any)[AccessibilityIdentifiers.TitlesScreen.image(for: 0)]
        XCTAssertTrue(cover.waitForExistence(timeout: 10))
        // SwiftUI exposes the padded Form row as the image's accessibility
        // frame. Measure the visible neutral-gray cover border in its screenshot.
        let screenshot = cover.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Board cover aspect ratio"
        attachment.lifetime = .keepAlways
        add(attachment)
        guard let bounds = coverBorderBounds(in: screenshot.image) else {
            XCTFail("The cover must render a visible border")
            return
        }
        XCTAssertGreaterThan(bounds.height, screenshot.image.size.height * 0.5)
        XCTAssertEqual(bounds.width / bounds.height, 210.0 / 297.0, accuracy: 0.02)
        XCTAssertTrue(app.textFields[AccessibilityIdentifiers.PhotoZoomView.titleField].exists)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoZoomView.replaceButton].exists)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoZoomView.saveButton].exists)
    }

    private func coverBorderBounds(in image: UIImage) -> CGRect? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width, height = cgImage.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let rendered = pixels.withUnsafeMutableBytes { storage -> Bool in
            guard let context = CGContext(data: storage.baseAddress, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard rendered else { return nil }
        var minX = width, minY = height, maxX = -1, maxY = -1
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let rgb = [Int(pixels[offset]), Int(pixels[offset + 1]), Int(pixels[offset + 2])]
                let low = rgb.min()!, high = rgb.max()!
                // Exclude white page/grid lines and the tinted Form background.
                if low >= 60 && high <= 195 && high - low <= 20 {
                    minX = min(minX, x); maxX = max(maxX, x)
                    minY = min(minY, y); maxY = max(maxY, y)
                }
            }
        }
        guard maxX > minX, maxY > minY else { return nil }
        return CGRect(x: CGFloat(minX) / image.scale, y: CGFloat(minY) / image.scale,
                      width: CGFloat(maxX - minX + 1) / image.scale,
                      height: CGFloat(maxY - minY + 1) / image.scale)
    }

    @MainActor func testBoardAndTopicsMenusAfterMainMenuRemoval() {
        XCTAssertTrue(app.scrollViews[AccessibilityIdentifiers.PhotoSelectionView.collectionView]
            .waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts[AccessibilityIdentifiers.NoPhotosView.tipView]
            .waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.NoPhotosView.addPhotosButton].exists)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.MainMenu.symbolSearchButton].exists)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.NoPhotosView.takePhotoButton].exists)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.PhotoSelectionView.selectModeButton].exists)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.PreviewScreen.pagePicker].exists)
        XCTAssertFalse(app.buttons["BoardEditor.more.left"].exists)
        XCTAssertFalse(app.buttons["BoardEditor.more.right"].exists)
        XCTAssertFalse(app.buttons["BoardEditor.more.top"].exists)
        XCTAssertFalse(app.buttons["BoardEditor.more.bottom"].exists)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.PhotoSelectionView.layoutButton].exists)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.PreviewScreen.formattingButton].exists)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.PhotoSelectionView.shareButton].exists)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.PhotoSelectionView.printButton].exists)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.MainMenu.selectPhotoButton].exists)
        let boardMenu = app.buttons[AccessibilityIdentifiers.TopicTitleView.menuButton]
        XCTAssertTrue(boardMenu.waitForExistence(timeout: 10))
        boardMenu.tap()
        XCTAssertTrue(app.buttons[isSpanish ? "Agregar Fotos" : "Add Photos"].exists)
        app.buttons.matching(NSPredicate(format: "label == %@ AND identifier != %@",
            isSpanish ? "Agregar Fotos" : "Add Photos", AccessibilityIdentifiers.NoPhotosView.addPhotosButton)).firstMatch.tap()
        XCTAssertTrue(app.buttons[isSpanish ? "Símbolo" : "Symbol"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.collectionViews.firstMatch.buttons[AccessibilityIdentifiers.TopicTitleView.renameButton].exists)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.TopicTitleView.changeTopicImageButton].exists)

        if !isSplitView {
            app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.95)).tap()
            let closeEditing = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.closeSelectionButton]
            if closeEditing.exists { closeEditing.tap() }
            tapBackButton()
        }

        let topicsMenu = app.buttons[AccessibilityIdentifiers.TopicSelectionView.menuButton]
        XCTAssertTrue(topicsMenu.waitForExistence(timeout: 10))
        topicsMenu.tap()
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.MainMenu.settingsButton].exists)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.MainMenu.moreAppsButton].exists)
    }

    @MainActor func testChoiceBoardFitsThreeByFiveOnPortraitIPhone() throws {
        try XCTSkipUnless(easyPECSAppType == .plus, "Choice Board is Plus-only")
        selectBoardScreenLayout(PageLayout(width: 3, height: 5))
        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.useBoardButton)
        assertChoiceBoardFits(columns: 3, rows: 5)
    }

    @MainActor func testSelectedPhotosUsesThreeByFiveGridOnPortraitIPhone() {
        selectBoardScreenLayout(PageLayout(width: 3, height: 5))
        assertSelectedPhotosGrid(columns: 3, rows: 5)
    }

    @MainActor func testSelectedPhotosUsesTwoByFiveGridOnLandscapeIPhone() {
        selectBoardScreenLayout(PageLayout(width: 2, height: 5))
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = requiredOrientation }

        let landscape = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            self.app.frame.width > self.app.frame.height
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [landscape], timeout: 10), .completed)
        assertSelectedPhotosGrid(columns: 2, rows: 5)
    }

    @MainActor private func assertSelectedPhotosGrid(columns: Int, rows: Int) {
        let scroll = app.scrollViews[AccessibilityIdentifiers.PhotoSelectionView.collectionView]
        let page = app.descendants(matching: .any)[AccessibilityIdentifiers.PhotoSelectionView.page(for: 0)]
        XCTAssertTrue(scroll.waitForExistence(timeout: 10))
        XCTAssertTrue(page.waitForExistence(timeout: 10))
        XCTAssertTrue((page.value as? String)?.contains("\(columns) × \(rows)") == true)
    }

    @MainActor private func selectBoardScreenLayout(_ layout: PageLayout) {
        selectPhotosFromPicker(count: 1, recheckSelections: false)
        let ids = AccessibilityIdentifiers.LayoutScreen.self
        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.layoutButton)
        selectPaperMedium()
        app.tapButton(id: ids.pageSizeButton(for: .a4))
        // Ten columns need landscape A4 to meet the 25 mm minimum card width.
        app.tapButton(id: ids.orientationButton(for: layout.width > 8 ? .landscape : .portrait))
        app.tapButton(id: ids.layoutButton(for: layout))
        XCTAssertTrue(app.buttons.matching(identifier: ids.layoutButton(for: layout)).firstMatch.isSelected)
        app.tapButton(id: "BoardEditor.closeLayout")
        XCTAssertTrue(app.scrollViews[AccessibilityIdentifiers.PhotoSelectionView.collectionView]
            .waitForExistence(timeout: 10))
    }

    @MainActor func testChoiceBoardFitsTwoByFiveOnLandscapeIPhone() throws {
        try XCTSkipUnless(easyPECSAppType == .plus, "Choice Board is Plus-only")
        selectBoardScreenLayout(PageLayout(width: 2, height: 5))
        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.useBoardButton)
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = requiredOrientation }

        let landscape = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            self.app.frame.width > self.app.frame.height
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [landscape], timeout: 10), .completed)
        assertChoiceBoardFits(columns: 2, rows: 5)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Landscape choice board with hierarchy navigation"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    @MainActor func testChoiceBoardScrollsVerticallyForDenseLandscapeLayout() throws {
        try XCTSkipUnless(easyPECSAppType == .plus, "Choice Board is Plus-only")
        selectBoardScreenLayout(PageLayout(width: 6, height: 10))
        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.useBoardButton)
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = requiredOrientation }

        let landscape = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            self.app.frame.width > self.app.frame.height
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [landscape], timeout: 10), .completed)

        assertPageScrollsVertically(scrollID: AccessibilityIdentifiers.ChoiceBoard.boardScrollView,
                                    pageID: AccessibilityIdentifiers.ChoiceBoard.page(for: 0))
    }

    @MainActor func testSelectedPhotosScrollsVerticallyForDenseLandscapeLayout() {
        selectBoardScreenLayout(PageLayout(width: 6, height: 10))
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = requiredOrientation }

        let landscape = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            self.app.frame.width > self.app.frame.height
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [landscape], timeout: 10), .completed)

        assertPageScrollsVertically(scrollID: AccessibilityIdentifiers.PhotoSelectionView.collectionView,
                                    pageID: AccessibilityIdentifiers.PhotoSelectionView.page(for: 0))
    }

    @MainActor func testChoiceBoardScrollsHorizontallyForWideLayout() throws {
        try XCTSkipUnless(easyPECSAppType == .plus, "Choice Board is Plus-only")
        selectBoardScreenLayout(PageLayout(width: 10, height: 5))
        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.useBoardButton)
        assertPageScrollsHorizontally(scrollID: AccessibilityIdentifiers.ChoiceBoard.boardScrollView,
                                      pageID: AccessibilityIdentifiers.ChoiceBoard.page(for: 0))
    }

    @MainActor func testSelectedPhotosScrollsHorizontallyForWideLayout() {
        selectBoardScreenLayout(PageLayout(width: 10, height: 5))
        assertPageScrollsHorizontally(scrollID: AccessibilityIdentifiers.PhotoSelectionView.collectionView,
                                      pageID: AccessibilityIdentifiers.PhotoSelectionView.page(for: 0))
    }

    @MainActor func testChoiceBoardFitsFiveColumnsOnIPhone() throws {
        try XCTSkipUnless(easyPECSAppType == .plus, "Choice Board is Plus-only")
        selectBoardScreenLayout(PageLayout(width: 5, height: 5))
        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.useBoardButton)

        assertChoiceBoardFits(columns: 5, rows: 5)
    }

    @MainActor func testSelectedPhotosUsesFiveColumnGridOnIPhone() {
        selectBoardScreenLayout(PageLayout(width: 5, height: 5))

        assertSelectedPhotosGrid(columns: 5, rows: 5)
    }

    @MainActor private func assertChoiceBoardFits(columns: Int, rows: Int) {
        let scroll = app.scrollViews[AccessibilityIdentifiers.ChoiceBoard.boardScrollView]
        let page = app.descendants(matching: .any)[AccessibilityIdentifiers.ChoiceBoard.page(for: 0)]

        XCTAssertTrue(scroll.waitForExistence(timeout: 10))
        XCTAssertTrue(page.waitForExistence(timeout: 10))
        XCTAssertGreaterThanOrEqual(page.frame.minY, scroll.frame.minY - 2)
        XCTAssertLessThanOrEqual(page.frame.maxY, scroll.frame.maxY + 2)
        XCTAssertGreaterThanOrEqual(page.frame.minX, scroll.frame.minX - 2)
        XCTAssertLessThanOrEqual(page.frame.maxX, scroll.frame.maxX + 2)

        XCTAssertTrue((page.value as? String)?.contains("\(columns) × \(rows)") == true)
        XCTAssertEqual(page.frame.width / page.frame.height, 210.0 / 297.0, accuracy: 0.02)
        XCTAssertFalse(app.descendants(matching: .any)[AccessibilityIdentifiers.ChoiceBoard.emptyCard(for: 0)].exists)
    }

    @MainActor private func assertPageScrollsVertically(scrollID: String, pageID: String) {
        let scroll = app.scrollViews[scrollID]
        let page = app.descendants(matching: .any)[pageID]
        XCTAssertTrue(scroll.waitForExistence(timeout: 10))
        XCTAssertTrue(page.waitForExistence(timeout: 10))
        XCTAssertLessThanOrEqual(page.frame.width, scroll.frame.width + 2)
        XCTAssertGreaterThan(page.frame.height, scroll.frame.height + 2)
        let initialY = page.frame.minY
        scroll.swipeUp()
        XCTAssertLessThan(page.frame.minY, initialY - 20)
    }

    @MainActor private func assertPageScrollsHorizontally(scrollID: String, pageID: String) {
        let scroll = app.scrollViews[scrollID]
        let page = app.descendants(matching: .any)[pageID]
        XCTAssertTrue(scroll.waitForExistence(timeout: 10))
        XCTAssertTrue(page.waitForExistence(timeout: 10))
        XCTAssertLessThanOrEqual(page.frame.height, scroll.frame.height + 2)
        XCTAssertGreaterThan(page.frame.width, scroll.frame.width + 2)
        let initialX = page.frame.minX
        scroll.swipeLeft()
        XCTAssertLessThan(page.frame.minX, initialX - 5)
    }

    @MainActor func testChoiceBoardFollowsChosenLayout() throws {
        try XCTSkipUnless(easyPECSAppType == .plus, "Choice Board is Plus-only")
        selectPhotosFromPicker(count: 3, recheckSelections: false)
        selectLayout(pageSize: .a4, orientation: .portrait,
                     layout: PageLayout(width: 2, height: 2))
        guard navigateToPhotoSelectionScreen() else { return }

        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.useBoardButton)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.TopicTitleView.pecsMakerButton]
            .waitForExistence(timeout: 10))

        let firstPhoto = app.buttons[A12SSUI.PhotoCell.image(for: 0)]
        let secondPhoto = app.buttons[A12SSUI.PhotoCell.image(for: 1)]
        let thirdPhoto = app.buttons[A12SSUI.PhotoCell.image(for: 2)]
        let emptyCell = app.descendants(matching: .any)[AccessibilityIdentifiers.ChoiceBoard.emptyCard(for: 3)]

        XCTAssertTrue(firstPhoto.waitForExistence(timeout: 10))
        XCTAssertTrue(secondPhoto.exists)
        XCTAssertTrue(thirdPhoto.exists)
        XCTAssertFalse(emptyCell.exists)
        XCTAssertEqual(firstPhoto.frame.minY, secondPhoto.frame.minY, accuracy: 2)
        XCTAssertGreaterThan(thirdPhoto.frame.minY, firstPhoto.frame.minY)
        XCTAssertFalse(app.descendants(matching: .any)[AccessibilityIdentifiers.ChoiceBoard.emptyCard(for: 4)].exists)
    }

    @MainActor func testSelectedPhotosFollowChosenLayoutWithEmptyCards() {
        selectPhotosFromPicker(count: 2, recheckSelections: false)
        selectLayout(pageSize: .a4, orientation: .portrait,
                     layout: PageLayout(width: 2, height: 2))
        guard navigateToPhotoSelectionScreen() else { return }

        let firstPhoto = app.buttons[A12SSUI.PhotoCell.image(for: 0)]
        let secondPhoto = app.buttons[A12SSUI.PhotoCell.image(for: 1)]
        let firstEmpty = app.descendants(matching: .any)[AccessibilityIdentifiers.PhotoSelectionView.emptyCard(for: 2)]
        let secondEmpty = app.descendants(matching: .any)[AccessibilityIdentifiers.PhotoSelectionView.emptyCard(for: 3)]

        XCTAssertTrue(firstPhoto.waitForExistence(timeout: 10))
        XCTAssertTrue(secondPhoto.exists)
        XCTAssertTrue(firstEmpty.exists)
        XCTAssertTrue(secondEmpty.exists)
        XCTAssertEqual(firstPhoto.frame.minY, secondPhoto.frame.minY, accuracy: 2)
        XCTAssertEqual(firstEmpty.frame.minY, secondEmpty.frame.minY, accuracy: 2)
        XCTAssertGreaterThan(firstEmpty.frame.minY, firstPhoto.frame.minY)
        XCTAssertFalse(app.descendants(matching: .any)[AccessibilityIdentifiers.PhotoSelectionView.emptyCard(for: 4)].exists)
    }

    @MainActor func testBlankCardsOpenZoomedPhotoWithAddButtonAndTitle() {
        selectPhotosFromPicker(count: 1, recheckSelections: false)
        selectLayout(pageSize: .a4, orientation: .portrait,
                     layout: PageLayout(width: 2, height: 2))
        guard navigateToPhotoSelectionScreen() else { return }

        let selectedPhotosBlank = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.emptyCard(for: 1)]
        XCTAssertTrue(selectedPhotosBlank.waitForExistence(timeout: 10))
        selectedPhotosBlank.tap()
        XCTAssertTrue(app.textFields[AccessibilityIdentifiers.PhotoZoomView.titleField]
            .waitForExistence(timeout: 10))
        let addPhotoButton = app.buttons[AccessibilityIdentifiers.PhotoZoomView.replaceButton]
        XCTAssertEqual(addPhotoButton.label, isSpanish ? "Agregar foto" : "Add Photo")
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.PhotoZoomView.deleteButton].exists)
        addPhotoButton.tap()
        let photoLibrary = app.buttons["Photo Library"]
        XCTAssertTrue(photoLibrary.waitForExistence(timeout: 5))
        photoLibrary.tap()
        let picker = SystemPhotoPickerDriver(app: app)
        picker.assertOpen()
        picker.cancel()
        picker.assertDismissed()
    }

    @MainActor func testTitleOnlyCardEditorShowsCardActionsWithoutPhotoActions() {
        selectPhotosFromPicker(count: 1, recheckSelections: false)
        selectLayout(pageSize: .a4, orientation: .portrait,
                     layout: PageLayout(width: 2, height: 2))
        guard navigateToPhotoSelectionScreen() else { return }

        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.emptyCard(for: 1))
        let title = app.textFields[AccessibilityIdentifiers.PhotoZoomView.titleField]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()
        title.typeText("No photo")
        app.tapButton(id: AccessibilityIdentifiers.PhotoZoomView.saveButton)

        let card = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.image(for: 1)]
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        card.tap()

        let actions = AccessibilityIdentifiers.PhotoZoomView.self
        XCTAssertEqual(app.buttons[actions.replaceButton].label,
                       isSpanish ? "Agregar foto" : "Add Photo")
        XCTAssertFalse(app.buttons[actions.cropButton].exists)
        XCTAssertFalse(app.buttons[actions.editPhotoButton].exists)
        XCTAssertFalse(app.buttons[actions.useAsBoardCoverButton].exists)
        XCTAssertTrue(app.buttons[actions.duplicateCardButton].exists)
        let deleteCard = app.buttons[actions.deleteButton]
        XCTAssertEqual(deleteCard.label, isSpanish ? "Eliminar tarjeta" : "Delete Card")
        deleteCard.tap()
        XCTAssertTrue(app.alerts.firstMatch.staticTexts[
            isSpanish ? "¿Eliminar tarjeta de tu tablero?" : "Delete card from your board?"
        ].exists)
        app.alerts.firstMatch.buttons[isSpanish ? "Cancelar" : "Cancel"].tap()
    }

    @MainActor func selectPhotosFromPicker(count: Int, recheckSelections: Bool) {
        selectPhotos(startScreen: .changeSelections, itemsToSelect: count, firstItem: 0,
                     expectedCount: count, recheckSelections: recheckSelections)
    }
}

/// Paper-board editing regressions, independent of the persisted layout medium.
class PaperPhotoSelectionScreenTests: PECSTestsBase {
    override func setLaunchArguments() {
        super.setLaunchArguments()
        app.launchArguments += ["-pageLayout.medium", "paper"]
    }

    @MainActor func testBrowsingAndSelectionModes() {
        selectPhotosFromPicker(count: 2, recheckSelections: false)
        guard navigateToPhotoSelectionScreen() else { return }

        let ids = AccessibilityIdentifiers.PhotoSelectionView.self
        let firstPhoto = app.buttons.matching(identifier: A12SSUI.PhotoCell.image(for: 0)).firstMatch
        let secondPhoto = app.buttons.matching(identifier: A12SSUI.PhotoCell.image(for: 1)).firstMatch
        XCTAssertTrue(firstPhoto.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons[ids.deleteButton].exists)
        XCTAssertFalse(app.buttons[A12SSUI.PhotoCell.deleteButton(for: 0)].exists)
        XCTAssertTrue(app.navigationBars.buttons[AccessibilityIdentifiers.TopicTitleView.titleField].exists)
        XCTAssertFalse(app.staticTexts[ids.photoCountLabel].exists)
        XCTAssertFalse(app.staticTexts[ids.selectedPhotoCountLabel].exists)
        let selectInNavigationBar = app.navigationBars.buttons[ids.selectModeButton].exists
        if selectInNavigationBar {
            XCTAssertEqual(app.buttons[ids.selectModeButton].label, isSpanish ? "Seleccionar" : "Select")
        }
        XCTAssertFalse(app.buttons[ids.menuButton].exists)
        XCTAssertTrue(app.buttons[ids.shareButton].exists)
        XCTAssertTrue(app.buttons[ids.layoutButton].exists)
        XCTAssertTrue(app.buttons[ids.printButton].exists)
        app.buttons[AccessibilityIdentifiers.TopicTitleView.menuButton].tap()
        if !selectInNavigationBar {
            XCTAssertEqual(app.buttons[ids.selectModeButton].label, isSpanish ? "Seleccionar" : "Select")
        }
        XCTAssertTrue(app.buttons[isSpanish ? "Agregar Fotos" : "Add Photos"].exists)
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.95)).tap()

        firstPhoto.tap()
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoZoomView.editPhotoButton].waitForExistence(timeout: 10))
        // Plus has an additional photo action, so Delete Card can begin below
        // the form's visible rows on a compact phone.
        for _ in 0..<5 where !app.buttons[AccessibilityIdentifiers.PhotoZoomView.deleteButton].exists {
            app.swipeUp()
        }
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoZoomView.deleteButton].exists)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoZoomView.cancelButton].exists)
        app.tapButton(id: AccessibilityIdentifiers.PhotoZoomView.cancelButton)

        let boardTitle = app.buttons[AccessibilityIdentifiers.TopicTitleView.titleField].label
        enterSelectionMode()
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.TopicTitleView.menuButton].exists)
        XCTAssertFalse(app.buttons[ids.menuButton].exists)
        XCTAssertEqual(app.buttons[ids.closeSelectionButton].label, isSpanish ? "Listo" : "Done")
        XCTAssertFalse(app.buttons[ids.shareButton].exists)
        XCTAssertFalse(app.buttons[ids.layoutButton].exists)
        XCTAssertFalse(app.buttons[ids.printButton].exists)
        XCTAssertFalse(app.navigationBars.buttons["BackButton"].exists)
        XCTAssertTrue(app.buttons[ids.selectAllButton].exists)
        XCTAssertLessThan(app.buttons[ids.selectAllButton].frame.minX,
                          app.buttons[ids.closeSelectionButton].frame.minX)
        XCTAssertEqual(app.staticTexts[ids.selectionCountLabel].label,
                       isSpanish ? "0 seleccionados" : "0 selected")
        XCTAssertGreaterThan(app.staticTexts[ids.selectionCountLabel].frame.minX,
                             app.navigationBars.staticTexts[boardTitle].frame.minX)
        XCTAssertFalse(app.buttons[ids.deleteButton].isEnabled)
        app.tapButton(id: ids.selectAllButton)
        XCTAssertTrue(firstPhoto.isSelected)
        XCTAssertTrue(secondPhoto.isSelected)
        XCTAssertTrue(app.buttons[ids.deselectAllButton].exists)
        XCTAssertLessThan(app.buttons[ids.deselectAllButton].frame.minX,
                          app.buttons[ids.closeSelectionButton].frame.minX)
        app.tapButton(id: ids.deselectAllButton)
        XCTAssertFalse(firstPhoto.isSelected)
        XCTAssertFalse(secondPhoto.isSelected)
        XCTAssertTrue(app.buttons[ids.closeSelectionButton].exists)
        firstPhoto.tap()
        XCTAssertTrue(firstPhoto.isSelected)
        XCTAssertEqual(app.staticTexts[ids.selectionCountLabel].label,
                       isSpanish ? "1 seleccionado" : "1 selected")
        secondPhoto.tap()
        XCTAssertTrue(secondPhoto.isSelected)
        XCTAssertEqual(app.staticTexts[ids.selectionCountLabel].label,
                       isSpanish ? "2 seleccionados" : "2 selected")
        firstPhoto.tap()
        XCTAssertFalse(firstPhoto.isSelected)
        app.tapButton(id: ids.closeSelectionButton)
        XCTAssertFalse(app.buttons[ids.deleteButton].exists)
        XCTAssertFalse(app.buttons[ids.menuButton].exists)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.TopicTitleView.menuButton].exists)
        XCTAssertTrue(app.buttons[ids.shareButton].exists)

        enterSelectionMode()
        XCTAssertFalse(firstPhoto.isSelected)
        app.tapButton(id: ids.closeSelectionButton)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.TopicTitleView.menuButton].exists)
        XCTAssertFalse(app.buttons[ids.menuButton].exists)
    }

    @MainActor func testBottomToolbarOpensLayoutAndPrint() {
        selectPhotosFromPicker(count: 1, recheckSelections: false)
        guard navigateToPhotoSelectionScreen() else { return }

        let ids = AccessibilityIdentifiers.PhotoSelectionView.self
        app.tapButton(id: ids.layoutButton)
        selectPaperMedium()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: AccessibilityIdentifiers.LayoutScreen.layoutHeading).firstMatch
            .waitForExistence(timeout: 10))
        app.tapButton(id: AccessibilityIdentifiers.LayoutScreen.seeAllButton)
        let singleRowHeading = app.staticTexts[isSpanish ? "Una sola fila" : "Single Row"]
        XCTAssertTrue(singleRowHeading.waitForExistence(timeout: 10), app.debugDescription)
        singleRowHeading.tap()
        XCTAssertTrue(singleRowHeading.exists, "The full layout screen must remain presented")
        tapBackButton()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: AccessibilityIdentifiers.LayoutScreen.layoutHeading).firstMatch
            .waitForExistence(timeout: 5))
        app.tapButton(id: "BoardEditor.cancelLayout")

        app.tapButton(id: ids.printButton)
        app.tapButton(id: AccessibilityIdentifiers.PreviewScreen.saveAndPrintButton)
        let printActivity = app.cells.matching(NSPredicate(format: "label == 'Print' OR label == 'Imprimir'")).firstMatch
        XCTAssertTrue(printActivity.waitForExistence(timeout: 10), app.debugDescription)
        printActivity.tap()
        let systemPrintLabels = isSpanish ? ["Imprimir", "Print"] : ["Print"]
        let systemPrintButton = app.navigationBars.buttons
            .matching(NSPredicate(format: "label IN %@", systemPrintLabels)).firstMatch
        XCTAssertTrue(systemPrintButton.waitForExistence(timeout: 10), app.debugDescription)
        let cancelLabels = isSpanish ? ["Cancelar", "Cancel"] : ["Cancel"]
        let cancelButton = app.navigationBars.buttons
            .matching(NSPredicate(format: "label IN %@", cancelLabels)).firstMatch
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5), app.debugDescription)
        cancelButton.tap()
        tapBackButton()
        XCTAssertTrue(app.buttons[ids.layoutButton].waitForExistence(timeout: 5))

        XCTAssertEqual(app.buttons[ids.useBoardButton].exists, easyPECSAppType == .plus)
        if easyPECSAppType == .plus {
            app.tapButton(id: ids.useBoardButton)
            let designBoard = app.buttons[AccessibilityIdentifiers.TopicTitleView.pecsMakerButton]
            XCTAssertTrue(designBoard.waitForExistence(timeout: 10))
            designBoard.tap()
            XCTAssertTrue(app.buttons[AccessibilityIdentifiers.TopicTitleView.menuButton]
                .waitForExistence(timeout: 10))
            XCTAssertTrue(app.buttons[ids.useBoardButton].exists)
        }
    }

    @MainActor func testShareOpensOnFirstTap() {
        selectPhotosFromPicker(count: 1, recheckSelections: false)
        guard navigateToPhotoSelectionScreen() else { return }

        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.shareButton)

        let sharingUIService = XCUIApplication(bundleIdentifier: "com.apple.SharingUIService")
        let saveLabels = isSpanish ? ["Guardar en Archivos", "Save to Files"] : ["Save to Files"]
        let savePredicate = NSPredicate(format: "label IN %@ OR identifier IN %@", saveLabels, saveLabels)
        let remoteSaveCell = sharingUIService.cells.matching(savePredicate).firstMatch
        let localSaveCell = app.cells.matching(savePredicate).firstMatch
        XCTAssertTrue(remoteSaveCell.waitForExistence(timeout: 10) ||
                      localSaveCell.waitForExistence(timeout: 10))
    }

    @MainActor func testPhotosDeletion_UsingToolbar() throws {
        try testPhotosDeletion(method: .toolbar)
    }

    @MainActor func testPhotosDeletion_UsingContextMenu() throws {
        try testPhotosDeletion(method: .contextMenu)
    }

    enum DeleteMethod { case contextMenu, toolbar}
    
    ///Check deletion of a photo
    @MainActor func testPhotosDeletion(method: DeleteMethod) throws {

        //Select some photos. Because we have no photos selected, we expect to be taken straight to the picker.
        let photoCount = 5
        selectPhotosFromPicker(count: photoCount, recheckSelections: false)

        //Delete the last 2 photos and verify the new count.
        //Need to delete the items backwards.
        let photosToDelete: [Int] = [4, 3]
        let expectedCount = photoCount - photosToDelete.count
        switch method {
        case .contextMenu:
            deletePhotosUsingPhotoSelectionScreenContextMenu(itemsToDelete: photosToDelete, expectedCount: expectedCount)
        case .toolbar:
            deletePhotosUsingPhotoSelectionScreen(itemsToDelete: photosToDelete, expectedCount: expectedCount)
        }

        //Go into the photo screen and check one
        //photo has been remvoed there as well.
        //checkPhotoCountUsingPicker(expectedCount, startScreen: .mainMenu)
        
    }
    
    @MainActor func selectPhotosFromPicker(count: Int, recheckSelections: Bool) {
        
        //guard appScreenIsVisible(.selectPhotos)
        
        selectPhotos(startScreen: .changeSelections, itemsToSelect: count, firstItem: 0, expectedCount: count, recheckSelections: recheckSelections)
        
    }
    
    @MainActor func testPhotoDuplication_UsingToolbar() throws {
        try testPhotoDuplication(method: .toolbar)
    }

    @MainActor func testPhotoDuplication_UsingContextMenu() throws {
        try testPhotoDuplication(method: .contextMenu)
    }

    enum DuplicationMethod { case contextMenu, toolbar }
    
    ///Check duplication of a photo
    @MainActor func testPhotoDuplication(method: DuplicationMethod) throws {

        //Select some photos
        let originalPhotoCount = 3
        selectPhotosFromPicker(count: originalPhotoCount, recheckSelections: false)
        
        //Duplicate one of the photos and verify the new count.
        switch method {
        case .contextMenu:
            duplicatePhotoUsingPhotoSelectionScreenContextMenu(itemToDuplicate: 0, expectedCount: originalPhotoCount + 1)
        case .toolbar:
            duplicatePhotoUsingPhotoSelectionScreen(itemToDuplicate: 0, expectedCount: originalPhotoCount + 1)
        }

        //The count on the OOTB photos screen should not have changed
        //checkPhotoCountUsingPicker(originalPhotoCount, startScreen: .mainMenu)
        
        //Exit the screen and go back in to ensure that any left over selections are cleared.
        //We could just do select all / unselect all, but this has the added benefit of making
        //sure that the photo list remains unchanged as we navigate between screens.
        returnToMainMenu()
        guard navigateToLayoutScreen() else { return }
        
        returnToMainMenu()
        guard navigateToPhotoSelectionScreen() else { return }
        
        //Delete one of the photos and verify the new count.
        deletePhotosUsingPhotoSelectionScreen(itemsToDelete: [0], expectedCount: originalPhotoCount)
        
        //The count on the OOTB photos screen will still be the same because
        //we only deleted the duplicate
        //checkPhotoCountUsingPicker(originalPhotoCount, startScreen: .mainMenu)

        //Delete another one of the photos and verify the new count.
        deletePhotosUsingPhotoSelectionScreen(itemsToDelete: [0], expectedCount: originalPhotoCount - 1)
        
        //The count on the OOTB photos screen will now have reduced.
        //we only deleted the duplicate
        //checkPhotoCountUsingPhotoSelectionScreen(originalPhotoCount - 1)
    }
    
    ///Check coping of a photo from current topic to another topic
    ///This test is only applicable to Easy PECS+ and Easy PECS Pro.
    @MainActor func testPhotoCopy() throws {
        
        guard appVersionSupportsTopics else { return }
        
        //Setup has created one topic. Now we need to create another
        //so we have a destination for the copied photo.
        returnToTopicScreen(from: .mainMenu)
        createTopic()
        
        //Wait for the new topic screen to appear (check any UI item for that screen).
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.TopicTitleView.titleField].waitForExistence(timeout: 5))
        
        //Since we don't know whether the new topic is index 0 or 1, we
        //go back the the home screen and select index 0
        returnToTopicScreen(from: .mainMenu)
        selectTopic(index: 0)
        
        //Select some photos
        let originalPhotoCount = 5
        selectPhotosFromPicker(count: originalPhotoCount, recheckSelections: false)
        
        //Copy two of the photos and verify the count doesn't change.
        let photosToCopy = [0, 1]
        copyPhotosUsingPhotoSelectionScreen(itemsToCopy: photosToCopy, expectedCount: originalPhotoCount)

        //The count on the OOTB photos screen should not have changed
        //checkPhotoCountUsingPicker(originalPhotoCount, startScreen: .mainMenu)

        //Navigate to the second topic and check it's photo count.
        returnToTopicScreen(from: .changeSelections)
        selectTopic(index: 1)
        
        guard navigateToPhotoSelectionScreen() else { return }
        checkPhotoCountUsingPhotoSelectionScreen(photosToCopy.count)
    }
            
    private func enterSelectionMode() {
        let close = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.closeSelectionButton]
        if !close.exists {
            tapBoardSelectAction()
        }
        XCTAssertTrue(close.exists)
    }

    private func clearPhotoSelections() {
        let ids = AccessibilityIdentifiers.PhotoSelectionView.self
        if app.buttons[ids.closeSelectionButton].exists {
            app.tapButton(id: ids.closeSelectionButton)
        }
    }

    func deletePhotosUsingPhotoSelectionScreen(itemsToDelete: [Int], expectedCount: Int) {
        
        guard navigateToPhotoSelectionScreen() else { return }
        
        if isSplitView {
            clearPhotoSelections()
        }
            
        enterSelectionMode()
        //Tap each item to select it
        for itemToDelete in itemsToDelete {
            //For some reason the items aren't are hittable but not tappable on iPad (IOS16).
            if isIOS16 && isIPad {
                app.forceTapButton(id: A12SSUI.PhotoCell.image(for: itemToDelete))
            }
            else {
                app.tapButton(id: A12SSUI.PhotoCell.image(for: itemToDelete))
            }
        }
        
        //Tap the delete button
        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.deleteButton)
        
        //Answer yes to the confirmation
        respondYesToAlert()

        //Verify the expected count after the deletion
        checkPhotoCountUsingPhotoSelectionScreen(expectedCount)
        //checkPhotoCountUsingPicker(expectedCount, startScreen: .selectPhotos)
        
        //Return to the main screen
        //tapBackButton()
        //returnToMainMenu()

    }
    
    func deletePhotosUsingPhotoSelectionScreenContextMenu(itemsToDelete: [Int], expectedCount: Int) {
        
        guard navigateToPhotoSelectionScreen() else { return }
        
        if isSplitView {
            clearPhotoSelections()
        }

        //Iterate through each item using its context menu.
        for itemToDelete in itemsToDelete {
            app.buttons[A12SSUI.PhotoCell.image(for: itemToDelete)].press(forDuration: 1)
            app.tapButton(id: AccessibilityIdentifiers.PhotoContextMenu.deleteButton)
                        
            //Answer yes to the confirmation
            respondYesToAlert()
        }

        //Verify the expected count after the deletion
        checkPhotoCountUsingPhotoSelectionScreen(expectedCount)
        //checkPhotoCountUsingPicker(expectedCount, startScreen: .selectPhotos)
        
        //Return to the main screen
        //tapBackButton()
        //returnToMainMenu()

    }
    
    var isIOS16: Bool {
        XCUIDevice.shared.iosVersion >= 16.0 && XCUIDevice.shared.iosVersion < 17.0
    }
    
    private var isIPad: Bool {
        XCUIDevice.isiPad
    }
    
    func duplicatePhotoUsingPhotoSelectionScreen(itemToDuplicate: Int, expectedCount: Int) {
        
        guard navigateToPhotoSelectionScreen() else { return }

        enterSelectionMode()
        //Tap the first item to select it
        //For some reason the items aren't are hittable but not tappable on iPad (IOS16).
        if isIOS16 && isIPad {
            app.forceTapButton(id: A12SSUI.PhotoCell.image(for: itemToDuplicate))
        }
        else {
            app.tapButton(id: A12SSUI.PhotoCell.image(for: itemToDuplicate))
        }

        //Tap the duplicate button
        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.duplicateButton)
        let confirmation = app.alerts[isSpanish ? "Duplicar Fotos Seleccionadas" : "Duplicate Selected Photos"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        confirmation.buttons[isSpanish ? "Duplicar" : "Duplicate"].tap()
        let success = app.alerts[isSpanish ? "Fotos Duplicadas" : "Photos Duplicated"]
        XCTAssertTrue(success.waitForExistence(timeout: 10))
        success.buttons[isSpanish ? "Cerrar" : "Close"].tap()
        
        //Verify the expected count after the duplication
        checkPhotoCountUsingPhotoSelectionScreen(expectedCount)

        //Return to the main screen
        //app.buttons[AccessibilityIdentifiers.TitlesScreen.doneButton].tap()
        //tapBackButton()
        //returnToMainMenu()
    }
    
    func duplicatePhotoUsingPhotoSelectionScreenContextMenu(itemToDuplicate: Int, expectedCount: Int) {
        
        guard navigateToPhotoSelectionScreen() else { return }

        displayPhotoContextMenuAndChooseDuplicate(photoIndex: 0)

        //Verify the expected count after the duplication
        checkPhotoCountUsingPhotoSelectionScreen(expectedCount)

        //Return to the main screen
        //app.buttons[AccessibilityIdentifiers.TitlesScreen.doneButton].tap()
        //tapBackButton()
        //returnToMainMenu()
    }
    
    func copyPhotosUsingPhotoSelectionScreen(itemsToCopy: [Int], expectedCount: Int) {
        
        //Go to photo selection screen.
        guard navigateToPhotoSelectionScreen() else { return }

        enterSelectionMode()
        //Tap each item to select it
        for itemsToCopy in itemsToCopy {
            //For some reason the items aren't are hittable but not tappable on iPad (IOS16).
            app.forceTapButton(id: A12SSUI.PhotoCell.image(for: itemsToCopy))
        }
        
        //Tap the copy button
        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.copyButton)
        
        //Select the destination topic. It will be index 1 (even though index 0 is now
        //hidden because the index goes off the topic list rather than the available list.
        app.tapButton(id: AccessibilityIdentifiers.TopicSelectionView.topicButton(for: 1))
        let copied = app.alerts[isSpanish ? "Foto(s) Copiadas" : "Photo(s) Copied"]
        XCTAssertTrue(copied.waitForExistence(timeout: 10))
        copied.buttons[isSpanish ? "Cerrar" : "Close"].tap()
        
        //Verify the expected count after the deletion
        checkPhotoCountUsingPhotoSelectionScreen(expectedCount)
        
        //Return to the main screen
        //tapBackButton()
        //returnToMainMenu()
    }
    
    @MainActor func testPhotoReordering() {
        
        //Select photos with the picker.
        let count = 3
        selectPhotosFromMainMenu(count: count, recheckSelections: false)
        
        // Give each card a unique title through the current card editor.
        for index in 0..<count {
            app.tapButton(id: A12SSUI.PhotoCell.image(for: index))
            let title = app.textFields[AccessibilityIdentifiers.PhotoZoomView.titleField]
            XCTAssertTrue(title.waitForExistence(timeout: 5))
            title.tap()
            title.clearText()
            title.typeText(makePhotoTitle(for: index))
            app.tapButton(id: AccessibilityIdentifiers.PhotoZoomView.saveButton)
        }
        let item0Title = makePhotoTitle(for: 0)
        let item1Title = makePhotoTitle(for: 1)
        let item2Title = makePhotoTitle(for: 2)
        
        //Go into the photo selection and get the first 3 images
        guard navigateToPhotoSelectionScreen() else { return }
        let image0 = app.buttons.matching(NSPredicate(format: "label ENDSWITH %@", item0Title)).firstMatch
        XCTAssertTrue(image0.waitForExistence(timeout: 5))
        let image1 = app.buttons.matching(NSPredicate(format: "label ENDSWITH %@", item1Title)).firstMatch
        XCTAssertTrue(image1.waitForExistence(timeout: 5))
        let image2 = app.buttons.matching(NSPredicate(format: "label ENDSWITH %@", item2Title)).firstMatch
        XCTAssertTrue(image2.waitForExistence(timeout: 5))

        //Get the starting position of the 3 images.
        let image0Position = image0.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let image1Position = image1.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let image2Position = image2.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        
        //Translate the position to screen points at this momenent in time
        //(i.e. before we drag image0Position because that will cause it
        //to change.
        let image0ScreenPoint = image0Position.screenPoint
        let image1ScreenPoint = image1Position.screenPoint
        let image2ScreenPoint = image2Position.screenPoint

        // Drag the first image to the third position. The result is that the first image
        //goes to the end, and everything else goes back one place
        //(i.e.image2 becomes 1, and image1 beccomes 0.
        image0Position.press(forDuration: 0.5, thenDragTo: image2Position)
        
        //Re-get item 0 and item 2 using their titles. We can't use the accessibility identifier
        //because it changes based on the index of the item within the grid.
        let imageId0 = app.buttons.matching(NSPredicate(format: "label ENDSWITH %@", item0Title)).firstMatch
        XCTAssertTrue(imageId0.waitForExistence(timeout: 5))
        let imageId1 = app.buttons.matching(NSPredicate(format: "label ENDSWITH %@", item1Title)).firstMatch
        XCTAssertTrue(imageId1.waitForExistence(timeout: 5))
        let imageId2 = app.buttons.matching(NSPredicate(format: "label ENDSWITH %@", item2Title)).firstMatch
        XCTAssertTrue(imageId2.waitForExistence(timeout: 5))
        
        // Check that the first image is now in the third position
        //Everything else has moved back one place.
        let image0PositionNew = imageId0.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).screenPoint
        let image1PositionNew = imageId1.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).screenPoint
        let image2PositionNew = imageId2.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).screenPoint
        
        let coordinateAccuracy: CGFloat = 0.5
        XCTAssertEqual(image0PositionNew.x, image2ScreenPoint.x, accuracy: coordinateAccuracy)
        XCTAssertEqual(image0PositionNew.y, image2ScreenPoint.y, accuracy: coordinateAccuracy)
        XCTAssertEqual(image1PositionNew.x, image0ScreenPoint.x, accuracy: coordinateAccuracy)
        XCTAssertEqual(image1PositionNew.y, image0ScreenPoint.y, accuracy: coordinateAccuracy)
        XCTAssertEqual(image2PositionNew.x, image1ScreenPoint.x, accuracy: coordinateAccuracy)
        XCTAssertEqual(image2PositionNew.y, image1ScreenPoint.y, accuracy: coordinateAccuracy)
         
    }
    
    @MainActor func testPhotoRename_usingContextMenu() {
        renamePhotoAndVerifyPersistence(inspectContextMenu: true)
    }

    @MainActor func testTappingCardTitleOpensZoomedPhoto() {
        selectPhotosFromMainMenu(count: 1, recheckSelections: false)
        guard navigateToPhotoSelectionScreen() else { return }

        let card = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.image(for: 0)]
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9)).tap()
        XCTAssertTrue(app.textFields[AccessibilityIdentifiers.PhotoZoomView.titleField]
            .waitForExistence(timeout: 10))
    }
    
    @MainActor func testPhotoRename() {
        renamePhotoAndVerifyPersistence(inspectContextMenu: false)
    }

    @MainActor private func renamePhotoAndVerifyPersistence(inspectContextMenu: Bool) {
        selectPhotosFromMainMenu(count: 3, recheckSelections: false)
        guard navigateToPhotoSelectionScreen() else { return }
        let card = app.buttons[A12SSUI.PhotoCell.image(for: 0)]
        XCTAssertTrue(card.label.hasSuffix(isSpanish ? "[Sin Título]" : "[Untitled]"))
        if inspectContextMenu {
            card.press(forDuration: 1)
            XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoContextMenu.duplicateButton].waitForExistence(timeout: 5))
            XCTAssertFalse(app.buttons[AccessibilityIdentifiers.PhotoContextMenu.renameButton].exists)
            app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.95)).tap()
        }
        card.tap()
        let field = app.textFields[AccessibilityIdentifiers.PhotoZoomView.titleField]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        let existingTitle = field.value as? String ?? ""
        XCTAssertTrue(existingTitle.isEmpty || existingTitle == field.placeholderValue)
        field.tap()
        let newTitle = "Photo number \(UUID().uuidString)"
        field.typeText(newTitle)
        app.tapButton(id: AccessibilityIdentifiers.PhotoZoomView.saveButton)
        XCTAssertTrue(card.label.hasSuffix(newTitle))

        returnToMainMenu()
        guard navigateToLayoutScreen() else { return }
        returnToMainMenu()
        guard navigateToPhotoSelectionScreen() else { return }
        XCTAssertTrue(card.label.hasSuffix(newTitle))
        card.tap()
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        XCTAssertEqual(field.value as? String, newTitle)
        app.tapButton(id: AccessibilityIdentifiers.PhotoZoomView.cancelButton)
    }

    func displayPhotoContextMenuAndChooseDuplicate(photoIndex: Int) {
        displayPhotoContextMenuAndSelectOption(photoIndex: 0, accessibilityID: AccessibilityIdentifiers.PhotoContextMenu.duplicateButton, menuText: "Duplicate")
    }
    
    //This tests a specific bug whereby the popup doesn't appear if the
    //accessibilityTrait isSelected is conditionally added to the view.
    @MainActor func testPhotoRenameWhenSelected() {
        
        //Select photos with the picker.
        let count = 1
        selectPhotosFromMainMenu(count: count, recheckSelections: false)
        
        //Now go into the photo selection and rename the items.
        guard navigateToPhotoSelectionScreen() else { return }
        
        //Tap the photo to select it.
        enterSelectionMode()
        app.tapButton(id: A12SSUI.PhotoCell.image(for: 0))
    
        //Make sure it's selected.
        guard let photo = app.selectButton(A12SSUI.PhotoCell.image(for: 0)) else { return }
        XCTAssertTrue(photo.isSelected)
        
        // Tapping the title in selection mode selects the card.
        photo.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9)).tap()
        XCTAssertFalse(photo.isSelected)
    }
    
}

/// In-memory fixture cards use the existing autofill launch option. No Photos
/// database setup or picker seeding is involved in these editor checks.
final class BoardPageEditorUITests: PECSTestsBase {
    @MainActor func testHierarchyCreateNavigateSearchAndHome() throws {
        let organize = app.buttons["BoardHierarchy.organize"]
        XCTAssertTrue(organize.waitForExistence(timeout: 15))
        organize.tap()
        app.buttons["Create child board"].tap()
        let parent = app.buttons["BoardHierarchy.parent"]
        XCTAssertTrue(parent.waitForExistence(timeout: 10))
        parent.tap()
        let child = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "BoardHierarchy.child.")).firstMatch
        XCTAssertTrue(child.waitForExistence(timeout: 10))
        let identifier = child.identifier
        child.tap()
        XCTAssertTrue(parent.waitForExistence(timeout: 10))
        app.buttons["BoardHierarchy.search"].tap()
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap(); field.typeText("Apple\n")
        XCTAssertTrue(app.switches["This board and children"].exists)
        app.buttons["BoardSearch.done"].tap()
        parent.tap()
        XCTAssertTrue(app.buttons[identifier].waitForExistence(timeout: 5))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Hierarchy parent and child navigation"; screenshot.lifetime = .keepAlways; add(screenshot)
        app.buttons["BoardHierarchy.home"].tap()
        XCTAssertTrue(app.scrollViews["TopicSelectionView.gridScrollView"].waitForExistence(timeout: 5))
    }

    @MainActor func testHierarchySearchOpensCardWithoutEnteringEditor() throws {
        let search = app.buttons["BoardHierarchy.search"]
        XCTAssertTrue(search.waitForExistence(timeout: 15))
        search.tap()
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap(); field.typeText("Apple\n")
        let result = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "BoardSearch.result.")).firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 10))
        result.tap()
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        // Wait for the presented search sheet to finish dismissing before inspecting the board.
        let dismissed = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: app.buttons["BoardSearch.done"])
        XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 5), .completed, app.debugDescription)
        let card = app.buttons[A12SSUI.PhotoCell.image(for: 0)]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        XCTAssertTrue(card.isSelected, "Search must reveal/select the matching card without activating it")
    }

    override func setLaunchArguments() {
        super.setLaunchArguments()
        app.launchArguments.append(LaunchArguments.autoFill)
    }

    @MainActor func testPageLayoutSwitchesPaperAndScreenOptions() {
        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.layoutButton)
        selectPaperMedium()
        let medium = app.buttons["LayoutScreen.medium"]
        XCTAssertTrue(medium.waitForExistence(timeout: 10))
        medium.tap()
        app.buttons[isSpanish ? "Pantalla" : "Screen"].tap()
        let modes = app.segmentedControls["LayoutScreen.screenLayout"]
        XCTAssertTrue(modes.waitForExistence(timeout: 5))
        modes.buttons[isSpanish ? "Automático" : "Automatic"].tap()
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.LayoutScreen.seeAllButton].exists)
        XCTAssertFalse(app.descendants(matching: .any)["LayoutScreen.showTitles"].exists)
        XCTAssertFalse(app.staticTexts[AccessibilityIdentifiers.LayoutScreen.pageSizeHeading].exists)
        modes.buttons[isSpanish ? "Predefinido" : "Pre-Defined"].tap()
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.LayoutScreen.seeAllButton].waitForExistence(timeout: 5))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Screen recommended designs"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        medium.tap()
        app.buttons[isSpanish ? "Papel" : "Paper"].tap()
        XCTAssertTrue(app.staticTexts[AccessibilityIdentifiers.LayoutScreen.pageSizeHeading].waitForExistence(timeout: 5))
        XCTAssertFalse(modes.exists)
    }

    @MainActor func testBoardCardContextMenuHasActionsWithoutRename() {
        let card = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.image(for: 0)]
        XCTAssertTrue(card.waitForExistence(timeout: 15))
        card.press(forDuration: 1)

        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoContextMenu.editButton].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoContextMenu.duplicateButton].exists)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoContextMenu.deleteButton].exists)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.PhotoContextMenu.renameButton].exists)
    }

    @MainActor func testPredefinedScreenLayoutKeepsThreeColumnsAfterRotation() {
        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.layoutButton)
        selectPaperMedium()
        app.buttons["LayoutScreen.medium"].tap()
        app.buttons[isSpanish ? "Pantalla" : "Screen"].tap()
        let modes = app.segmentedControls["LayoutScreen.screenLayout"]
        XCTAssertTrue(modes.waitForExistence(timeout: 5))
        modes.buttons[isSpanish ? "Predefinido" : "Pre-Defined"].tap()
        selectLayoutChoice(PageLayout(width: 3, height: 4))
        app.tapButton(id: "BoardEditor.closeLayout")

        let ids = AccessibilityIdentifiers.PhotoSelectionView.self
        let first = app.buttons[ids.image(for: 0)]
        let fourth = app.buttons[ids.image(for: 3)]
        func assertThreeColumns() {
            let matchesGrid = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                first.exists && fourth.exists
                    && abs(first.frame.minX - fourth.frame.minX) < 2
                    && fourth.frame.minY > first.frame.maxY
            }, object: nil)
            XCTAssertEqual(XCTWaiter.wait(for: [matchesGrid], timeout: 10), .completed)
            let page = app.descendants(matching: .any)[ids.page(for: 0)].firstMatch
            XCTAssertTrue((page.value as? String)?.contains("3 × 4") == true)
        }
        assertThreeColumns()
        let initialSize = first.frame.size
        defer { XCUIDevice.shared.orientation = requiredOrientation }
        for orientation in [UIDeviceOrientation.landscapeLeft, .portrait, .landscapeLeft, .portrait] {
            XCUIDevice.shared.orientation = orientation
            let rotated = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                (self.app.frame.width > self.app.frame.height) == orientation.isLandscape
            }, object: nil)
            XCTAssertEqual(XCTWaiter.wait(for: [rotated], timeout: 10), .completed)
            assertThreeColumns()
            if orientation.isLandscape {
                XCTAssertLessThan(first.frame.width, initialSize.width)
                XCTAssertLessThan(first.frame.height, initialSize.height)
                XCTAssertGreaterThanOrEqual(first.frame.width, 63)
                XCTAssertGreaterThanOrEqual(first.frame.height, 63)
            } else {
                XCTAssertEqual(first.frame.width, initialSize.width, accuracy: 1)
                XCTAssertEqual(first.frame.height, initialSize.height, accuracy: 1)
            }
        }

    }

    @MainActor private func swipeBoardPage(forward: Bool) {
        let horizontalPages = app.scrollViews[AccessibilityIdentifiers.PhotoSelectionView.pageScroll]
        let pages = horizontalPages.exists
            ? horizontalPages
            : app.collectionViews[AccessibilityIdentifiers.PhotoSelectionView.pageTabs]
        XCTAssertTrue(pages.waitForExistence(timeout: 5))
        if forward {
            pages.swipeLeft()
        } else {
            pages.swipeRight()
        }
    }

    @MainActor func testBoardPagesSwipeLikeClassicPreview() {
        selectEditorLayout(PageLayout(width: 2, height: 2), orientation: .portrait)
        XCTAssertTrue(app.pageIndicators.firstMatch.waitForExistence(timeout: 10))
        let firstPageValue = app.pageIndicators.firstMatch.value as? String
        XCTAssertNotNil(firstPageValue)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoSelectionView.image(for: 0)].isHittable)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.PreviewScreen.pagePicker].exists)
        for index in [4, 8, 12] {
            swipeBoardPage(forward: true)
            XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoSelectionView.image(for: index)]
                .waitForExistence(timeout: 10))
        }
        for index in [8, 4, 0] {
            swipeBoardPage(forward: false)
            XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoSelectionView.image(for: index)]
                .waitForExistence(timeout: 10))
        }
        let firstPageCard = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.image(for: 0)]
        let pageIndicator = app.pageIndicators.firstMatch
        for _ in 0..<3 where pageIndicator.value as? String != firstPageValue {
            swipeBoardPage(forward: false)
        }
        XCTAssertEqual(pageIndicator.value as? String, firstPageValue,
                      "The portrait pager must select its first page before rotation")
        XCTAssertTrue(firstPageCard.isHittable)
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = requiredOrientation }
        let landscape = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            self.app.frame.width > self.app.frame.height
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [landscape], timeout: 10), .completed)
        let horizontalPages = app.scrollViews[AccessibilityIdentifiers.PhotoSelectionView.pageScroll]
        XCTAssertTrue(horizontalPages.waitForExistence(timeout: 5))
        XCTAssertFalse(app.pageIndicators.firstMatch.exists)
        XCTAssertFalse(app.collectionViews[AccessibilityIdentifiers.PhotoSelectionView.pageTabs].exists)
        let secondPageCard = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.image(for: 4)]
        XCTAssertTrue(firstPageCard.isHittable, app.debugDescription)
        XCTAssertTrue(secondPageCard.waitForExistence(timeout: 10))
        XCTAssertTrue(secondPageCard.isHittable)
        XCTAssertGreaterThan(secondPageCard.frame.minX, firstPageCard.frame.maxX)
        XCTAssertLessThan(secondPageCard.frame.maxX, horizontalPages.frame.maxX)
        let lastPageCard = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.image(for: 12)]
        for _ in 0..<3 {
            if lastPageCard.isHittable { break }
            swipeBoardPage(forward: true)
        }
        XCTAssertTrue(lastPageCard.isHittable)
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.pageIndicators.firstMatch.waitForExistence(timeout: 5))
    }

    @MainActor func testDeletingOnlyPhotoRemovesPageButKeepsFinalEmptyPage() {
        let ids = AccessibilityIdentifiers.PhotoSelectionView.self
        selectEditorLayout(PageLayout(width: 3, height: 4), orientation: .portrait)
        swipeBoardPage(forward: true)
        XCTAssertTrue(app.buttons[ids.image(for: 12)].waitForExistence(timeout: 10))

        // Filling a later slot creates invisible placeholders before this card.
        // They must not keep the page alive after its last real card is deleted.
        app.tapButton(id: ids.emptyCard(for: 23))
        let title = app.textFields[AccessibilityIdentifiers.PhotoZoomView.titleField]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()
        title.typeText("Last slot")
        app.tapButton(id: AccessibilityIdentifiers.PhotoZoomView.saveButton)
        XCTAssertTrue(app.buttons[ids.image(for: 23)].waitForExistence(timeout: 10))

        tapBoardSelectAction()
        for index in 12..<23 where app.buttons[ids.image(for: index)].exists {
            app.tapButton(id: ids.image(for: index))
        }
        app.tapButton(id: ids.deleteButton)
        app.alerts.firstMatch.buttons[isSpanish ? "Eliminar" : "Delete"].tap()
        app.tapButton(id: ids.closeSelectionButton)

        let onlyPhotoOnSecondPage = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "Last slot")
        ).firstMatch
        XCTAssertTrue(onlyPhotoOnSecondPage.waitForExistence(timeout: 10))
        onlyPhotoOnSecondPage.tap()
        for _ in 0..<5 where !app.buttons[AccessibilityIdentifiers.PhotoZoomView.deleteButton].exists {
            app.swipeUp()
        }
        app.tapButton(id: AccessibilityIdentifiers.PhotoZoomView.deleteButton)
        app.alerts.firstMatch.buttons[isSpanish ? "Eliminar tarjeta" : "Delete Card"].tap()

        let firstPage = app.descendants(matching: .any)[ids.page(for: 0)]
        let removedPage = app.descendants(matching: .any)[ids.page(for: 1)]
        XCTAssertTrue(firstPage.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertFalse(removedPage.exists)
        XCTAssertTrue(app.buttons[ids.image(for: 0)].isHittable)

        tapBoardSelectAction()
        app.tapButton(id: ids.selectAllButton)
        app.tapButton(id: ids.deleteButton)
        app.alerts.firstMatch.buttons[isSpanish ? "Eliminar" : "Delete"].tap()
        XCTAssertTrue(app.staticTexts[AccessibilityIdentifiers.NoPhotosView.tipView]
            .waitForExistence(timeout: 10))
        XCTAssertTrue(firstPage.exists)
        XCTAssertFalse(removedPage.exists)
    }

    @MainActor func testLandscapePagesShareVerticalScroll() {
        selectEditorLayout(PageLayout(width: 2, height: 5), orientation: .portrait)
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = requiredOrientation }

        let verticalScroll = app.scrollViews[AccessibilityIdentifiers.PhotoSelectionView.collectionView]
        let firstPage = app.descendants(matching: .any)[AccessibilityIdentifiers.PhotoSelectionView.page(for: 0)]
        let secondPage = app.descendants(matching: .any)[AccessibilityIdentifiers.PhotoSelectionView.page(for: 1)]
        XCTAssertTrue(verticalScroll.waitForExistence(timeout: 10))
        XCTAssertTrue(firstPage.waitForExistence(timeout: 10))
        XCTAssertTrue(secondPage.waitForExistence(timeout: 10))

        let firstY = firstPage.frame.minY
        let secondY = secondPage.frame.minY
        verticalScroll.swipeUp(velocity: .slow)
        let firstMovement = firstPage.frame.minY - firstY
        let secondMovement = secondPage.frame.minY - secondY
        // Some sizes fit without scrolling; when they scroll, both pages share the offset.
        XCTAssertEqual(firstMovement, secondMovement, accuracy: 2)
    }

    func testBackToTopicsAfterCancellingPhoto() throws {
        try assertBackToTopicsAfterClosingPhoto(using: AccessibilityIdentifiers.PhotoZoomView.cancelButton)
    }

    func testBackToTopicsAfterSavingPhoto() throws {
        try assertBackToTopicsAfterClosingPhoto(using: AccessibilityIdentifiers.PhotoZoomView.saveButton)
    }

    private func assertBackToTopicsAfterClosingPhoto(using closeButton: String) throws {
        try XCTSkipIf(XCUIDevice.isiPad, "This checks the phone's Back-to-Topics control")
        let photo = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.image(for: 0)]
        XCTAssertTrue(photo.waitForExistence(timeout: 15))
        photo.tap()
        app.tapButton(id: closeButton)
        XCTAssertTrue(photo.waitForExistence(timeout: 10))
        app.navigationBars.buttons[backButtonName].tap()
        let topic = app.buttons[AccessibilityIdentifiers.TopicSelectionView.topicButton(for: 0)]
        XCTAssertTrue(topic.waitForExistence(timeout: 10), "Back must reveal Topics after closing a photo")
        XCTAssertTrue(topic.isHittable)
        topic.tap()
        XCTAssertTrue(photo.waitForExistence(timeout: 10))
        XCTAssertTrue(photo.isHittable)
    }

    @MainActor func testAllLayoutChoicesSurviveOrientationChanges() {
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoSelectionView.image(for: 0)]
            .waitForExistence(timeout: 15))
        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.layoutButton)
        selectPaperMedium()
        for orientation in [PageOrientation.landscape, .portrait] {
            app.tapButton(id: AccessibilityIdentifiers.LayoutScreen.orientationButton(for: orientation))
            app.tapButton(id: AccessibilityIdentifiers.LayoutScreen.seeAllButton)
            let recommended = app.descendants(matching: .any)
                .matching(identifier: AccessibilityIdentifiers.LayoutScreen.layoutHeading).firstMatch
            XCTAssertTrue(recommended.waitForExistence(timeout: 5), app.debugDescription)
            XCTAssertTrue(recommended.label.contains(isSpanish ? "Recomend" : "Recommended"))
            let layoutsBar = app.navigationBars[isSpanish ? "Diseños" : "Layouts"]
            XCTAssertTrue(layoutsBar.waitForExistence(timeout: 5), app.debugDescription)
            layoutsBar.buttons.firstMatch.tap()
            XCTAssertTrue(app.buttons[AccessibilityIdentifiers.LayoutScreen.seeAllButton].waitForExistence(timeout: 5))
        }
        app.tapButton(id: "BoardEditor.closeLayout")
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoSelectionView.image(for: 0)]
            .waitForExistence(timeout: 5))
    }

    @MainActor func testPrintOpensSystemPrintScreen() {
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoSelectionView.image(for: 0)]
            .waitForExistence(timeout: 15))

        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.printButton)
        app.tapButton(id: AccessibilityIdentifiers.PreviewScreen.saveAndPrintButton)
        let printActivity = app.cells.matching(NSPredicate(format: "label == 'Print' OR label == 'Imprimir'")).firstMatch
        XCTAssertTrue(printActivity.waitForExistence(timeout: 10), app.debugDescription)
        printActivity.tap()

        let systemPrintLabels = isSpanish ? ["Imprimir", "Print"] : ["Print"]
        let systemPrintButton = app.navigationBars.buttons
            .matching(NSPredicate(format: "label IN %@", systemPrintLabels)).firstMatch
        XCTAssertTrue(systemPrintButton.waitForExistence(timeout: 15), app.debugDescription)
    }

    @MainActor func testLaterBlankCardCanBeCancelledAndSavedInPlace() {
        selectEditorLayout(PageLayout(width: 3, height: 4), orientation: .portrait)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoSelectionView.image(for: 0)].waitForExistence(timeout: 15))
        swipeBoardPage(forward: true)
        let blank = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.emptyCard(for: 23)]
        XCTAssertTrue(blank.waitForExistence(timeout: 10))
        let earlierEmptySlot = (0..<23).first {
            app.buttons[AccessibilityIdentifiers.PhotoSelectionView.emptyCard(for: $0)].exists
        }
        blank.tap()
        XCTAssertTrue(app.textFields[AccessibilityIdentifiers.PhotoZoomView.titleField].waitForExistence(timeout: 5))
        app.tapButton(id: AccessibilityIdentifiers.PhotoZoomView.cancelButton)
        XCTAssertTrue(blank.waitForExistence(timeout: 10))
        blank.tap()
        let title = app.textFields[AccessibilityIdentifiers.PhotoZoomView.titleField]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()
        title.typeText("Last slot")
        app.tapButton(id: AccessibilityIdentifiers.PhotoZoomView.saveButton)
        let inserted = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.image(for: 23)]
        XCTAssertTrue(inserted.waitForExistence(timeout: 10))
        XCTAssertTrue(inserted.label.contains("Last slot"))
        if let earlierEmptySlot {
            XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoSelectionView.emptyCard(for: earlierEmptySlot)].exists)
        }
        inserted.tap()
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertEqual(title.value as? String, "Last slot")
        app.tapButton(id: AccessibilityIdentifiers.PhotoZoomView.cancelButton)
    }

    @MainActor func testBoardEditorGridUsesSelectedRowsAndColumns() {
        let ids = AccessibilityIdentifiers.PhotoSelectionView.self
        let first = app.buttons[ids.image(for: 0)]
        XCTAssertTrue(first.waitForExistence(timeout: 15))
        app.tapButton(id: ids.layoutButton)
        selectPaperMedium()
        app.buttons["LayoutScreen.medium"].tap()
        app.buttons[isSpanish ? "Papel" : "Paper"].tap()
        app.tapButton(id: AccessibilityIdentifiers.LayoutScreen.orientationButton(for: .landscape))
        selectLayoutChoice(PageLayout(width: 3, height: 2))
        app.tapButton(id: "BoardEditor.closeLayout")
        let scroll = app.scrollViews[ids.collectionView]
        XCTAssertTrue(scroll.waitForExistence(timeout: 10))
        let fourth = app.buttons[ids.image(for: 3)]
        XCTAssertTrue(fourth.exists)
        XCTAssertEqual(first.frame.minX, fourth.frame.minX, accuracy: 2)
        XCTAssertGreaterThan(fourth.frame.minY, first.frame.minY)
        let fitted = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        fitted.name = "Board editor three column grid"
        fitted.lifetime = .keepAlways
        add(fitted)
        first.tap()
        XCTAssertTrue(app.textFields[AccessibilityIdentifiers.PhotoZoomView.titleField]
            .waitForExistence(timeout: 5))
        app.tapButton(id: AccessibilityIdentifiers.PhotoZoomView.cancelButton)
        XCTAssertTrue(first.waitForExistence(timeout: 5))

        app.tapButton(id: ids.layoutButton)
        selectPaperMedium()
        selectLayoutChoice(PageLayout(width: 5, height: 4))
        app.tapButton(id: "BoardEditor.closeLayout")
        let sixth = app.buttons[ids.image(for: 5)]
        XCTAssertTrue(sixth.exists)
        XCTAssertEqual(first.frame.minX, sixth.frame.minX, accuracy: 2)
        XCTAssertGreaterThan(sixth.frame.minY, first.frame.minY)
        XCTAssertGreaterThanOrEqual(first.frame.width, 50)
        XCTAssertGreaterThanOrEqual(first.frame.height, 34)

        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = requiredOrientation }
        XCTAssertTrue(scroll.waitForExistence(timeout: 10))
        XCTAssertGreaterThanOrEqual(first.frame.width, 50)
        XCTAssertGreaterThanOrEqual(first.frame.height, 34)
        let landscape = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        landscape.name = "Board editor dense grid in landscape"
        landscape.lifetime = .keepAlways
        add(landscape)
    }

    @MainActor func testRepeatedGridScrollingRemainsResponsive() {
        let ids = AccessibilityIdentifiers.PhotoSelectionView.self
        let first = app.buttons[ids.image(for: 0)]
        XCTAssertTrue(first.waitForExistence(timeout: 15))
        app.tapButton(id: ids.layoutButton)
        selectPaperMedium()
        app.tapButton(id: AccessibilityIdentifiers.LayoutScreen.orientationButton(for: .landscape))
        selectLayoutChoice(PageLayout(width: 5, height: 4))
        app.tapButton(id: "BoardEditor.closeLayout")

        let grid = app.scrollViews[ids.collectionView]
        XCTAssertTrue(grid.waitForExistence(timeout: 10))
        for _ in 0..<6 {
            grid.swipeLeft()
            grid.swipeUp()
            grid.swipeRight()
            grid.swipeDown()
        }

        XCTAssertTrue(first.waitForExistence(timeout: 5))
        let layoutButton = app.buttons[ids.layoutButton]
        XCTAssertTrue(layoutButton.waitForExistence(timeout: 5))
        layoutButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["BoardEditor.closeLayout"].waitForExistence(timeout: 5),
                      "The editor must accept input after repeated scrolling")
    }

    @MainActor func testTitleStaysInNavigationBarAndCompactSelectUsesMoreMenu() throws {
        try XCTSkipIf(XCUIDevice.isiPad, "This checks the compact phone toolbar")
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoSelectionView.image(for: 0)]
            .waitForExistence(timeout: 15))
        let boardTitleID = AccessibilityIdentifiers.TopicTitleView.titleField
        let selectID = AccessibilityIdentifiers.PhotoSelectionView.selectModeButton
        let layoutButton = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.layoutButton]
        XCTAssertTrue(app.navigationBars.buttons[boardTitleID].exists)
        XCTAssertTrue(layoutButton.exists)
        XCTAssertGreaterThan(layoutButton.frame.midY, app.frame.midY)
        XCTAssertFalse(app.navigationBars.buttons[selectID].exists)
        tapBoardSelectAction()
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoSelectionView.closeSelectionButton].exists)
        XCTAssertTrue(app.navigationBars.staticTexts[AccessibilityIdentifiers.PhotoSelectionView.selectionCountLabel].exists)
        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.closeSelectionButton)

        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = requiredOrientation }
        let landscape = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            self.app.frame.width > self.app.frame.height
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [landscape], timeout: 10), .completed)

        XCTAssertTrue(app.navigationBars.buttons[boardTitleID].exists)
        let layoutAtTop = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            layoutButton.exists && layoutButton.frame.midY < self.app.frame.midY
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [layoutAtTop], timeout: 10), .completed)

        tapBoardSelectAction()
        let deleteButton = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.deleteButton]
        XCTAssertTrue(deleteButton.exists)
        XCTAssertLessThan(deleteButton.frame.midY, app.frame.midY)
    }

    @MainActor func testEditSelectReorderFormatPaginateAndExport() {
        selectEditorLayout(PageLayout(width: 3, height: 4), orientation: .portrait)
        let first = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.image(for: 0)]
        XCTAssertTrue(first.waitForExistence(timeout: 15), app.debugDescription)
        XCTAssertGreaterThanOrEqual(first.frame.width, 44)
        XCTAssertGreaterThanOrEqual(first.frame.height, 44)
        first.tap()
        let title = app.textFields[AccessibilityIdentifiers.PhotoZoomView.titleField]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        let preview = app.images[AccessibilityIdentifiers.TitlesScreen.image(for: 0)]
        XCTAssertLessThanOrEqual(preview.frame.height, 312) // Includes the Form row's vertical insets.
        title.tap()
        title.clearText()
        title.typeText("Edited page card")
        app.tapButton(id: AccessibilityIdentifiers.PhotoZoomView.saveButton)
        XCTAssertTrue(first.waitForExistence(timeout: 10))
        XCTAssertTrue(first.label.contains("Edited page card"))

        tapBoardSelectAction()
        first.tap()
        XCTAssertTrue(first.isSelected)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoSelectionView.deleteButton].isEnabled)
        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.closeSelectionButton)
        XCTAssertFalse(first.isSelected)

        let second = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.image(for: 1)]
        first.press(forDuration: 1, thenDragTo: second, withVelocity: .slow, thenHoldForDuration: 0.5)
        let dragImage = XCTAttachment(screenshot: app.screenshot())
        dragImage.name = "After reordering"
        dragImage.lifetime = .keepAlways
        add(dragImage)
        let reordered = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", "Edited page card"), object: second)
        XCTAssertEqual(XCTWaiter.wait(for: [reordered], timeout: 10), .completed)

        swipeBoardPage(forward: true)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoSelectionView.image(for: 12)].waitForExistence(timeout: 10))
        swipeBoardPage(forward: false)
        XCTAssertTrue(first.waitForExistence(timeout: 10))

        let grid = app.scrollViews[AccessibilityIdentifiers.PhotoSelectionView.collectionView].firstMatch
        XCTAssertTrue(grid.exists)
        XCTAssertGreaterThanOrEqual(first.frame.width, 50)
        app.tapButton(id: AccessibilityIdentifiers.PreviewScreen.formattingButton)
        XCTAssertTrue(app.navigationBars["Formatting"].waitForExistence(timeout: 5), app.debugDescription)
        app.buttons[AccessibilityIdentifiersSSUI.PopupHeader.closeButton].tap()
        XCTAssertTrue(first.waitForExistence(timeout: 10))

        let portrait = XCTAttachment(screenshot: app.screenshot())
        portrait.name = "Page editor portrait"
        portrait.lifetime = .keepAlways
        add(portrait)
        XCUIDevice.shared.orientation = .landscapeLeft
        let landscape = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            self.app.frame.width > self.app.frame.height
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [landscape], timeout: 10), .completed)
        grid.swipeDown()
        XCTAssertTrue(first.waitForExistence(timeout: 10))
        XCTAssertTrue(app.scrollViews[AccessibilityIdentifiers.PhotoSelectionView.pageScroll]
            .waitForExistence(timeout: 5))
        swipeBoardPage(forward: true)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoSelectionView.image(for: 12)].waitForExistence(timeout: 5))
        swipeBoardPage(forward: false)
        grid.swipeDown()
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        let printButton = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.printButton]
        XCTAssertTrue(printButton.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(printButton.frame.minX, app.frame.width * 0.7)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoSelectionView.layoutButton].isHittable)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoSelectionView.shareButton].isHittable)
        XCTAssertFalse(app.pageIndicators.firstMatch.exists)
        app.tapButton(id: AccessibilityIdentifiers.PreviewScreen.formattingButton)
        XCTAssertTrue(app.navigationBars["Formatting"].waitForExistence(timeout: 5))
        app.buttons[AccessibilityIdentifiersSSUI.PopupHeader.closeButton].tap()
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Page editor landscape"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        XCUIDevice.shared.orientation = requiredOrientation

        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.printButton)
        app.tapButton(id: AccessibilityIdentifiers.PreviewScreen.saveAndPrintButton)
        let printActivity = app.cells.matching(NSPredicate(format: "label == 'Print' OR label == 'Imprimir'")).firstMatch
        XCTAssertTrue(printActivity.waitForExistence(timeout: 10), app.debugDescription)
        printActivity.tap()
        let systemPrintLabels = isSpanish ? ["Imprimir", "Print"] : ["Print"]
        let systemPrintButton = app.navigationBars.buttons
            .matching(NSPredicate(format: "label IN %@", systemPrintLabels)).firstMatch
        XCTAssertTrue(systemPrintButton.waitForExistence(timeout: 15), app.debugDescription)
    }
}

final class BoardSinglePageUITests: PECSTestsBase {
    override func setLaunchArguments() {
        super.setLaunchArguments()
        app.launchArguments.append(LaunchArguments.autoFillSingle)
    }

    @MainActor func testDuplicatePhotosConfirmationAndResult() {
        let ids = AccessibilityIdentifiers.PhotoSelectionView.self
        let first = app.buttons[ids.image(for: 0)]
        XCTAssertTrue(first.waitForExistence(timeout: 15))
        tapBoardSelectAction()
        first.tap()
        let duplicate = app.buttons[ids.duplicateButton]
        XCTAssertTrue(duplicate.isEnabled)
        duplicate.tap()
        let confirmation = app.alerts[isSpanish ? "Duplicar Fotos Seleccionadas" : "Duplicate Selected Photos"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        XCTAssertTrue(confirmation.staticTexts[isSpanish ? "¿Duplicar la foto seleccionada?" : "Duplicate the selected photo?"].exists)
        confirmation.buttons[isSpanish ? "Cancelar" : "Cancel"].tap()
        XCTAssertFalse(app.buttons[ids.image(for: 1)].exists)

        func confirmDuplicateAndCheckResult(count: Int) {
            duplicate.tap()
            XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
            confirmation.buttons[isSpanish ? "Duplicar" : "Duplicate"].tap()
            let success = app.alerts[isSpanish ? "Fotos Duplicadas" : "Photos Duplicated"]
            XCTAssertTrue(success.waitForExistence(timeout: 10))
            let message = isSpanish
                ? (count == 1 ? "Se ha duplicado 1 foto." : "Se han duplicado \(count) fotos.")
                : (count == 1 ? "Duplicated 1 photo." : "Duplicated \(count) photos.")
            XCTAssertTrue(success.staticTexts[message].exists)
            success.buttons[isSpanish ? "Cerrar" : "Close"].tap()
        }

        confirmDuplicateAndCheckResult(count: 1)
        XCTAssertTrue(app.buttons[ids.image(for: 1)].waitForExistence(timeout: 5))
        app.buttons[ids.selectAllButton].tap()
        confirmDuplicateAndCheckResult(count: 2)
        XCTAssertTrue(app.buttons[ids.image(for: 3)].waitForExistence(timeout: 5))
    }

    @MainActor func testCardDismissalPreservesBoardPosition() {
        let card = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.image(for: 0)]
        XCTAssertTrue(card.waitForExistence(timeout: 15))
        selectEditorLayout(PageLayout(width: 3, height: 4), orientation: .portrait)

        for closeButton in [AccessibilityIdentifiers.PhotoZoomView.cancelButton,
                            AccessibilityIdentifiers.PhotoZoomView.saveButton] {
            let originalFrame = card.frame
            card.tap()
            XCTAssertTrue(app.textFields[AccessibilityIdentifiers.PhotoZoomView.titleField]
                .waitForExistence(timeout: 5))
            app.tapButton(id: closeButton)
            XCTAssertTrue(card.waitForExistence(timeout: 5))
            XCTAssertEqual(card.frame.minX, originalFrame.minX, accuracy: 1)
            XCTAssertEqual(card.frame.minY, originalFrame.minY, accuracy: 1)
            XCTAssertEqual(card.frame.width, originalFrame.width, accuracy: 1)
            XCTAssertEqual(card.frame.height, originalFrame.height, accuracy: 1)
        }
    }

    @MainActor func testDeletingAllPhotosExitsSelectionMode() {
        let ids = AccessibilityIdentifiers.PhotoSelectionView.self
        let first = app.buttons[ids.image(for: 0)]
        XCTAssertTrue(first.waitForExistence(timeout: 15))

        tapBoardSelectAction()
        first.tap()
        app.tapButton(id: ids.deleteButton)
        app.alerts.firstMatch.buttons[isSpanish ? "Eliminar" : "Delete"].tap()

        XCTAssertFalse(app.buttons[ids.selectModeButton].exists)
        XCTAssertFalse(app.buttons[ids.closeSelectionButton].exists)
        XCTAssertTrue(app.staticTexts[AccessibilityIdentifiers.NoPhotosView.tipView].exists)
        XCTAssertFalse(app.buttons[ids.layoutButton].exists)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.PreviewScreen.formattingButton].exists)
        XCTAssertFalse(app.buttons[ids.shareButton].exists)
        XCTAssertFalse(app.buttons[ids.printButton].exists)
    }

    @MainActor func testSinglePageControlsAndPhotoSize() {
        selectEditorLayout(PageLayout(width: 3, height: 4), orientation: .portrait)
        let first = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.image(for: 0)]
        XCTAssertTrue(first.waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.PreviewScreen.pagePicker].exists)
        let canvas = app.scrollViews[AccessibilityIdentifiers.PhotoSelectionView.collectionView]
        XCTAssertTrue(canvas.exists)
        let origin = first.frame.origin
        canvas.swipeUp()
        XCTAssertEqual(first.frame.minY, origin.y, accuracy: 1,
                       "A readable fitted board must not scroll")
        XCTAssertFalse(app.buttons["BoardEditor.more.right"].exists)
        let board = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        board.name = "Portrait board fits whole page"
        board.lifetime = .keepAlways
        add(board)
        first.tap()
        let title = app.textFields[AccessibilityIdentifiers.PhotoZoomView.titleField]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        let preview = app.images[AccessibilityIdentifiers.TitlesScreen.image(for: 0)]
        XCTAssertLessThanOrEqual(preview.frame.height, 312) // Includes the Form row's vertical insets.
        XCTAssertTrue(title.isHittable)
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Bounded photo editor portrait"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = requiredOrientation }
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertLessThanOrEqual(preview.frame.height, 312) // Includes the Form row's vertical insets.
        let landscape = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        landscape.name = "Bounded photo editor landscape"
        landscape.lifetime = .keepAlways
        add(landscape)
    }
}

// Shared current-layout helpers: tests choose their grid explicitly instead of relying on recommendations.
extension PECSTestsBase {
    func selectEditorLayout(_ layout: PageLayout, orientation: PageOrientation) {
        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.layoutButton)
        selectPaperMedium()
        app.tapButton(id: AccessibilityIdentifiers.LayoutScreen.orientationButton(for: orientation))
        selectLayoutChoice(layout)
        app.tapButton(id: "BoardEditor.closeLayout")
    }

    func selectLayoutChoice(_ layout: PageLayout) {
        let id = AccessibilityIdentifiers.LayoutScreen.layoutButton(for: layout)
        let choice = app.buttons.matching(identifier: id).firstMatch
        if choice.exists && choice.isHittable {
            choice.tap()
            return
        }
        app.tapButton(id: AccessibilityIdentifiers.LayoutScreen.seeAllButton)
        for _ in 0..<18 {
            if choice.exists && choice.isHittable { break }
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(choice.exists && choice.isHittable, "Required layout must be available: \(id)")
        choice.tap()
        XCTAssertTrue(app.buttons["BoardEditor.closeLayout"].waitForExistence(timeout: 5))
    }
}
