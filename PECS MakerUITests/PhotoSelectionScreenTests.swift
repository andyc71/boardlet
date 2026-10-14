//
//  PhotoSelectionTests.swift
//  PhotoSelectionTests
//
//  Created by Andy on 22/12/2022.
//

import XCTest

class PhotoSelectionScreenTests: PECSTestsBase {

    @MainActor func testBoardDetailsCoverUsesPageAspectRatio() {
        let boardTitle = app.buttons[AccessibilityIdentifiers.TopicTitleView.titleField]
        XCTAssertTrue(boardTitle.waitForExistence(timeout: 10))
        boardTitle.tap()

        XCTAssertTrue(app.navigationBars["Board Details"].waitForExistence(timeout: 10))
        let cover = app.descendants(matching: .any)[AccessibilityIdentifiers.TitlesScreen.image(for: 0)]
        XCTAssertTrue(cover.waitForExistence(timeout: 10))
        XCTAssertEqual(cover.frame.width / cover.frame.height, 210.0 / 297.0, accuracy: 0.02)
        XCTAssertTrue(app.textFields[AccessibilityIdentifiers.PhotoZoomView.titleField].exists)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoZoomView.replaceButton].exists)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoZoomView.saveButton].exists)
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
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.PreviewScreen.previousPage].exists)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.PreviewScreen.nextPage].exists)
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
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.TopicTitleView.renameButton].exists)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.TopicTitleView.changeTopicImageButton].exists)

        if !isSplitView {
            app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
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

    @MainActor func testSelectedPhotosFitsThreeByFiveOnPortraitIPhone() {
        selectBoardScreenLayout(PageLayout(width: 3, height: 5))
        assertSelectedPhotosPageFits(columns: 3, rows: 5)
    }

    @MainActor func testSelectedPhotosFitsTwoByFiveOnLandscapeIPhone() {
        selectBoardScreenLayout(PageLayout(width: 2, height: 5))
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = requiredOrientation }

        let landscape = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            self.app.frame.width > self.app.frame.height
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [landscape], timeout: 10), .completed)
        assertSelectedPhotosPageFits(columns: 2, rows: 5)
    }

    @MainActor private func assertSelectedPhotosPageFits(columns: Int, rows: Int) {
        let scroll = app.scrollViews[AccessibilityIdentifiers.PhotoSelectionView.collectionView]
        let page = app.descendants(matching: .any)[AccessibilityIdentifiers.PhotoSelectionView.page(for: 0)]
        XCTAssertTrue(scroll.waitForExistence(timeout: 10))
        XCTAssertTrue(page.waitForExistence(timeout: 10))
        XCTAssertGreaterThanOrEqual(page.frame.minY, scroll.frame.minY - 2)
        XCTAssertLessThanOrEqual(page.frame.maxY, scroll.frame.maxY + 2)
        XCTAssertGreaterThanOrEqual(page.frame.minX, scroll.frame.minX - 2)
        XCTAssertLessThanOrEqual(page.frame.maxX, scroll.frame.maxX + 2)
        XCTAssertTrue((page.value as? String)?.contains("\(columns) × \(rows)") == true)
        XCTAssertEqual(page.frame.width / page.frame.height, 210.0 / 297.0, accuracy: 0.02)
    }

    @MainActor private func selectBoardScreenLayout(_ layout: PageLayout) {
        let ids = AccessibilityIdentifiers.LayoutScreen.self
        let closeSelection = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.closeSelectionButton]
        if closeSelection.exists { closeSelection.tap() }
        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.layoutButton)
        app.tapButton(id: ids.pageSizeButton(for: .a4))
        app.tapButton(id: ids.orientationButton(for: .portrait))
        let layoutButton = app.buttons[ids.layoutButton(for: layout)]
        let layoutScroll = app.scrollViews.containing(.button,
            identifier: ids.orientationButton(for: .portrait)).firstMatch
        XCTAssertTrue(layoutScroll.waitForExistence(timeout: 10))
        for _ in 0..<30 {
            if layoutButton.exists && layoutButton.frame.maxY <= layoutScroll.frame.maxY - 8 {
                break
            }
            layoutScroll.swipeUp()
        }
        XCTAssertTrue(layoutButton.exists)
        XCTAssertLessThanOrEqual(layoutButton.frame.maxY, layoutScroll.frame.maxY - 8)
        layoutButton.tap()
        XCTAssertTrue(layoutButton.isSelected)
        tapBackButton()
        XCTAssertTrue(app.scrollViews[AccessibilityIdentifiers.PhotoSelectionView.collectionView]
            .waitForExistence(timeout: 10))
        let closeSelectionAfterLayout = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.closeSelectionButton]
        if closeSelectionAfterLayout.exists { closeSelectionAfterLayout.tap() }
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

    @MainActor func testSelectedPhotosFitsFiveColumnsOnIPhone() {
        selectBoardScreenLayout(PageLayout(width: 5, height: 5))

        assertSelectedPhotosPageFits(columns: 5, rows: 5)
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
        selectLayout(pageSize: .a4, orientation: .portrait,
                     layout: PageLayout(width: 2, height: 2))
        selectPhotosFromPicker(count: 3, recheckSelections: false)
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
        selectLayout(pageSize: .a4, orientation: .portrait,
                     layout: PageLayout(width: 2, height: 2))
        selectPhotosFromPicker(count: 2, recheckSelections: false)
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
        selectLayout(pageSize: .a4, orientation: .portrait,
                     layout: PageLayout(width: 2, height: 2))
        selectPhotosFromPicker(count: 1, recheckSelections: false)
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

    @MainActor func testBrowsingAndSelectionModes() {
        selectPhotosFromPicker(count: 2, recheckSelections: false)
        guard navigateToPhotoSelectionScreen() else { return }

        let ids = AccessibilityIdentifiers.PhotoSelectionView.self
        let firstPhoto = app.buttons.matching(identifier: A12SSUI.PhotoCell.image(for: 0)).firstMatch
        let secondPhoto = app.buttons.matching(identifier: A12SSUI.PhotoCell.image(for: 1)).firstMatch
        XCTAssertTrue(firstPhoto.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons[ids.deleteButton].exists)
        XCTAssertFalse(app.buttons[A12SSUI.PhotoCell.deleteButton(for: 0)].exists)
        XCTAssertFalse(app.buttons[ids.selectedBadge(for: 0)].exists)
        XCTAssertTrue(app.navigationBars.staticTexts[isSpanish ? "Fotos" : "Photos"].exists)
        XCTAssertFalse(app.staticTexts[ids.photoCountLabel].exists)
        XCTAssertFalse(app.staticTexts[ids.selectedPhotoCountLabel].exists)
        XCTAssertEqual(app.buttons[ids.selectModeButton].label, isSpanish ? "Seleccionar" : "Select")
        XCTAssertFalse(app.buttons[ids.menuButton].exists)
        XCTAssertTrue(app.buttons[ids.shareButton].exists)
        XCTAssertTrue(app.buttons[ids.layoutButton].exists)
        XCTAssertTrue(app.buttons[ids.printButton].exists)
        app.buttons[AccessibilityIdentifiers.TopicTitleView.menuButton].tap()
        XCTAssertTrue(app.buttons[isSpanish ? "Añadir elementos" : "Add items"].exists)
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        firstPhoto.tap()
        XCTAssertTrue(app.buttons["editBoardPhoto"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoZoomView.deleteButton].exists)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.PhotoZoomView.closeButton].exists)
        tapBackButton()

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
                             app.buttons[AccessibilityIdentifiers.TopicTitleView.titleField].frame.minX)
        XCTAssertFalse(app.buttons[ids.selectedBadge(for: 0)].exists)
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
        XCTAssertTrue(app.buttons[ids.selectedBadge(for: 0)].exists)
        XCTAssertEqual(app.staticTexts[ids.selectionCountLabel].label,
                       isSpanish ? "1 seleccionado" : "1 selected")
        secondPhoto.tap()
        XCTAssertTrue(secondPhoto.isSelected)
        XCTAssertEqual(app.staticTexts[ids.selectionCountLabel].label,
                       isSpanish ? "2 seleccionados" : "2 selected")
        firstPhoto.tap()
        XCTAssertFalse(firstPhoto.isSelected)
        XCTAssertFalse(app.buttons[ids.selectedBadge(for: 0)].exists)
        app.tapButton(id: ids.closeSelectionButton)
        XCTAssertFalse(app.buttons[ids.deleteButton].exists)
        XCTAssertFalse(app.buttons[ids.menuButton].exists)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.TopicTitleView.menuButton].exists)
        XCTAssertTrue(app.buttons[ids.shareButton].exists)

        enterSelectionMode()
        XCTAssertFalse(firstPhoto.isSelected)
        app.tapButton(id: ids.closeSelectionButton)
        XCTAssertTrue(app.buttons[ids.selectModeButton].exists)
        XCTAssertFalse(app.buttons[ids.menuButton].exists)
    }

    @MainActor func testBottomToolbarOpensLayoutAndPrint() {
        selectPhotosFromPicker(count: 1, recheckSelections: false)
        guard navigateToPhotoSelectionScreen() else { return }

        let ids = AccessibilityIdentifiers.PhotoSelectionView.self
        app.tapButton(id: ids.layoutButton)
        XCTAssertTrue(app.staticTexts[AccessibilityIdentifiers.LayoutScreen.layoutHeading]
            .waitForExistence(timeout: 10))
        app.tapButton(id: AccessibilityIdentifiers.LayoutScreen.seeAllButton)
        let singleRowHeading = app.staticTexts[isSpanish ? "Una sola fila" : "Single Row"]
        XCTAssertTrue(singleRowHeading.waitForExistence(timeout: 10), app.debugDescription)
        singleRowHeading.tap()
        XCTAssertTrue(singleRowHeading.exists, "The full layout screen must remain presented")
        tapBackButton()
        XCTAssertTrue(app.staticTexts[AccessibilityIdentifiers.LayoutScreen.layoutHeading]
            .waitForExistence(timeout: 5))
        app.tapButton(id: "BoardEditor.cancelLayout")

        app.tapButton(id: ids.printButton)
        let systemPrintLabels = isSpanish ? ["Imprimir", "Print"] : ["Print"]
        let systemPrintButton = app.navigationBars.buttons
            .matching(NSPredicate(format: "label IN %@", systemPrintLabels)).firstMatch
        XCTAssertTrue(systemPrintButton.waitForExistence(timeout: 10), app.debugDescription)
        let cancelLabels = isSpanish ? ["Cancelar", "Cancel"] : ["Cancel"]
        let cancelButton = app.navigationBars.buttons
            .matching(NSPredicate(format: "label IN %@", cancelLabels)).firstMatch
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5), app.debugDescription)
        cancelButton.tap()
        XCTAssertTrue(app.buttons[ids.layoutButton].waitForExistence(timeout: 5))

        XCTAssertEqual(app.buttons[ids.useBoardButton].exists, easyPECSAppType == .plus)
        if easyPECSAppType == .plus {
            app.tapButton(id: ids.useBoardButton)
            let designBoard = app.buttons[AccessibilityIdentifiers.TopicTitleView.pecsMakerButton]
            XCTAssertTrue(designBoard.waitForExistence(timeout: 10))
            designBoard.tap()
            XCTAssertTrue(app.buttons[ids.selectModeButton].waitForExistence(timeout: 10))
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
        
        selectPhotos(startScreen: .mainMenu, itemsToSelect: count, firstItem: 0, expectedCount: count, recheckSelections: recheckSelections)
        
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
        app.selectButton(AccessibilityIdentifiers.MainMenu.selectPhotoButton)
        
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
            app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.selectModeButton)
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
        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.menuButton)
        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.duplicateButton)
        
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
        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.menuButton)
        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.copyButton)
        
        //Select the destination topic. It will be index 1 (even though index 0 is now
        //hidden because the index goes off the topic list rather than the available list.
        app.tapButton(id: AccessibilityIdentifiers.TopicSelectionView.topicButton(for: 1))
        
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
        
        //Go into the titles screen and add some titles
        //to the photos.
        completeTitles(count: count)
        let item0Title = makePhotoTitle(for: 0)
        let item1Title = makePhotoTitle(for: 1)
        let item2Title = makePhotoTitle(for: 2)
        
        //Go into the photo selection and get the first 3 images
        guard navigateToPhotoSelectionScreen() else { return }
        guard let image0 = app.selectButton(item0Title) else { return }
        guard let image1 = app.selectButton(item1Title) else { return }
        guard let image2 = app.selectButton(item2Title) else { return }

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
        guard let imageId0 = app.selectButton(item0Title) else { return }
        guard let imageId1 = app.selectButton(item1Title) else { return }
        guard let imageId2 = app.selectButton(item2Title) else { return }
        
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
        testPhotoRename()
    }
    
    @MainActor func testTappingCardTitleOpensZoomedPhoto() {
        selectPhotosFromMainMenu(count: 1, recheckSelections: false)
        guard navigateToPhotoSelectionScreen() else { return }

        let title = app.staticTexts[AccessibilityIdentifiers.PhotoSelectionView.title(for: 0)]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        title.tap()
        XCTAssertTrue(app.textFields[AccessibilityIdentifiers.PhotoZoomView.titleField]
            .waitForExistence(timeout: 10))
    }
    
    @MainActor func testPhotoRename() {
        
        //Select photos with the picker.
        let count = 3
        selectPhotosFromMainMenu(count: count, recheckSelections: false)
        
        //Now go into the photo selection and rename the items.
        guard navigateToPhotoSelectionScreen() else { return }

        //Get the existing title of the first item.
        guard let label = app.selectStaticText(A12SSUI.PhotoCell.title(for: 0)) else { return }
        var existingLabel = label.label
        
        //Label should be untitled
        if isSpanish {
            XCTAssertEqual(existingLabel, "[Sin Título]")
        }
        else {
            XCTAssertEqual(existingLabel, "[Untitled]")
        }
        
        displayPhotoContextMenuAndChooseRename(photoIndex: 0)
        
        //Fill in the topic popup with a random name.
        let newTitle = completeEditPopupWithRandomText(prefix: "Photo number ", initialValue: nil)
        
        //Check that the new name has appeared on the photos screen.
        guard let label = app.selectStaticText(A12SSUI.PhotoCell.title(for: 0)) else { return }
        let newLabel = label.label
        XCTAssertEqual(newLabel, newTitle)
        
        //Go out of the screen and back in to check that it's saved.
        returnToMainMenu()
        guard navigateToLayoutScreen() else { return }
        returnToMainMenu()
        guard navigateToPhotoSelectionScreen() else { return }
        
        guard let label = app.selectStaticText(A12SSUI.PhotoCell.title(for: 0)) else { return }
        existingLabel = label.label

        XCTAssertEqual(existingLabel, newLabel)
        
        //Go back into the edit popup, and this time make sure that it is
        //pre-ppopulated with the right title.
        displayPhotoContextMenuAndChooseRename(photoIndex: 0)
        checkEditPopupText(prefix: "Photo number ", expectedValue: existingLabel)
    }
    
    func displayPhotoContextMenuAndChooseRename(photoIndex: Int) {
        
        //Display the context menu and choose rename.
        displayPhotoContextMenuAndSelectOption(photoIndex: 0, accessibilityID: AccessibilityIdentifiers.PhotoContextMenu.renameButton, menuText: "Change Text")

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
        guard let label = app.selectStaticText(A12SSUI.PhotoCell.title(for: 0)) else { return }
        label.tap()
        XCTAssertFalse(photo.isSelected)
    }
    
}

/// In-memory fixture cards use the existing autofill launch option. No Photos
/// database setup or picker seeding is involved in these editor checks.
final class BoardPageEditorUITests: PECSTestsBase {
    override func setLaunchArguments() {
        super.setLaunchArguments()
        app.launchArguments.append(LaunchArguments.autoFill)
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
        for orientation in [PageOrientation.landscape, .portrait] {
            app.tapButton(id: AccessibilityIdentifiers.LayoutScreen.orientationButton(for: orientation))
            app.tapButton(id: AccessibilityIdentifiers.LayoutScreen.seeAllButton)
            XCTAssertTrue(app.staticTexts["Recommended"].waitForExistence(timeout: 5))
            let layoutsBar = app.navigationBars["Layouts"]
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

        let systemPrintLabels = isSpanish ? ["Imprimir", "Print"] : ["Print"]
        let systemPrintButton = app.navigationBars.buttons
            .matching(NSPredicate(format: "label IN %@", systemPrintLabels)).firstMatch
        XCTAssertTrue(systemPrintButton.waitForExistence(timeout: 15), app.debugDescription)
    }

    @MainActor func testLaterBlankCardCanBeCancelledAndSavedInPlace() {
        selectEditorLayout(PageLayout(width: 3, height: 4), orientation: .portrait)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoSelectionView.image(for: 0)].waitForExistence(timeout: 15))
        app.tapButton(id: AccessibilityIdentifiers.PreviewScreen.nextPage)
        let blank = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.emptyCard(for: 23)]
        XCTAssertTrue(blank.waitForExistence(timeout: 10))
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
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoSelectionView.emptyCard(for: 15)].exists)
        inserted.tap()
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertEqual(title.value as? String, "Last slot")
        app.tapButton(id: AccessibilityIdentifiers.PhotoZoomView.cancelButton)
    }

    @MainActor func testReadablePageFitsAndDensePageLocksTheFittedAxis() {
        let ids = AccessibilityIdentifiers.PhotoSelectionView.self
        let first = app.buttons[ids.image(for: 0)]
        XCTAssertTrue(first.waitForExistence(timeout: 15))
        app.tapButton(id: ids.layoutButton)
        app.tapButton(id: AccessibilityIdentifiers.LayoutScreen.orientationButton(for: .landscape))
        selectLayoutChoice(PageLayout(width: 3, height: 2))
        app.tapButton(id: "BoardEditor.closeLayout")
        let scroll = app.scrollViews[ids.collectionView]
        XCTAssertTrue(scroll.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["BoardEditor.more.right"].exists)
        XCTAssertFalse(app.buttons["BoardEditor.more.bottom"].exists)
        let original = first.frame
        scroll.swipeLeft()
        scroll.swipeUp()
        XCTAssertEqual(first.frame.minX, original.minX, accuracy: 1)
        XCTAssertEqual(first.frame.minY, original.minY, accuracy: 1)
        XCTAssertGreaterThanOrEqual(first.frame.width, 94)
        XCTAssertGreaterThanOrEqual(first.frame.height, 94)
        let fitted = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        fitted.name = "Readable landscape collage fits whole page with padding"
        fitted.lifetime = .keepAlways
        add(fitted)

        app.tapButton(id: ids.layoutButton)
        selectLayoutChoice(PageLayout(width: 5, height: 4))
        app.tapButton(id: "BoardEditor.closeLayout")
        XCTAssertTrue(app.buttons["BoardEditor.more.right"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["BoardEditor.more.bottom"].exists)
        let initialY = first.frame.minY
        scroll.swipeUp()
        XCTAssertEqual(first.frame.minY, initialY, accuracy: 1)
        app.buttons["BoardEditor.more.right"].tap()
        if app.buttons["BoardEditor.more.right"].exists { app.buttons["BoardEditor.more.right"].tap() }
        let lastColumn = app.buttons[ids.image(for: 4)]
        XCTAssertTrue(lastColumn.isHittable)
        XCTAssertEqual(lastColumn.frame.maxX, scroll.frame.maxX, accuracy: 2,
                       "Horizontal overflow ends at the edge without trailing padding")
        XCTAssertTrue(app.buttons["BoardEditor.more.left"].waitForExistence(timeout: 5))

        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = requiredOrientation }
        XCTAssertTrue(app.buttons["BoardEditor.more.bottom"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["BoardEditor.more.right"].exists)
        XCTAssertFalse(app.buttons["BoardEditor.more.left"].exists)
        let initialX = first.frame.minX
        scroll.swipeLeft()
        XCTAssertEqual(first.frame.minX, initialX, accuracy: 1)
        let beforeVerticalScroll = first.frame.minY
        app.buttons["BoardEditor.more.bottom"].tap()
        XCTAssertLessThan(first.frame.minY, beforeVerticalScroll - 20)
        let beforePinchWidth = first.frame.width
        scroll.pinch(withScale: 1.2, velocity: 0.5)
        XCTAssertLessThan(first.frame.minY, beforeVerticalScroll,
                          "Committing a pinch must preserve the scrolled position")
        XCTAssertGreaterThan(first.frame.width, beforePinchWidth * 1.05)
        let landscape = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        landscape.name = "Dense collage scrolls vertically in landscape"
        landscape.lifetime = .keepAlways
        add(landscape)
    }

    @MainActor func testRepeatedPanAndZoomRemainsResponsive() {
        let ids = AccessibilityIdentifiers.PhotoSelectionView.self
        let first = app.buttons[ids.image(for: 0)]
        XCTAssertTrue(first.waitForExistence(timeout: 15))
        app.tapButton(id: ids.layoutButton)
        app.tapButton(id: AccessibilityIdentifiers.LayoutScreen.orientationButton(for: .landscape))
        selectLayoutChoice(PageLayout(width: 5, height: 4))
        app.tapButton(id: "BoardEditor.closeLayout")

        let canvas = app.scrollViews[ids.collectionView]
        XCTAssertTrue(canvas.waitForExistence(timeout: 10))
        for _ in 0..<6 {
            canvas.pinch(withScale: 1.2, velocity: 0.5)
            canvas.swipeLeft()
            canvas.swipeUp()
            canvas.pinch(withScale: 1 / 1.2, velocity: -0.5)
            canvas.swipeRight()
            canvas.swipeDown()
        }

        XCTAssertTrue(first.waitForExistence(timeout: 5))
        let layoutButton = app.buttons[ids.layoutButton]
        XCTAssertTrue(layoutButton.waitForExistence(timeout: 5))
        layoutButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["BoardEditor.closeLayout"].waitForExistence(timeout: 5),
                      "The editor must accept input after repeated scroll-layout settlements")
    }

    @MainActor func testTitleMovesBelowToolbarOnlyInCompactHorizontalLayout() {
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoSelectionView.image(for: 0)]
            .waitForExistence(timeout: 15))
        let boardTitleID = AccessibilityIdentifiers.TopicTitleView.titleField
        XCTAssertFalse(app.navigationBars.buttons[boardTitleID].exists)
        XCTAssertTrue(app.buttons[boardTitleID].exists)

        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = requiredOrientation }
        let landscape = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            self.app.frame.width > self.app.frame.height
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [landscape], timeout: 10), .completed)

        XCTAssertTrue(app.navigationBars.buttons[boardTitleID].exists)
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

        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.selectModeButton)
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

        app.tapButton(id: AccessibilityIdentifiers.PreviewScreen.nextPage)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoSelectionView.image(for: 12)].waitForExistence(timeout: 10))
        app.tapButton(id: AccessibilityIdentifiers.PreviewScreen.previousPage)
        XCTAssertTrue(first.waitForExistence(timeout: 10))

        let canvas = app.scrollViews[AccessibilityIdentifiers.PhotoSelectionView.collectionView]
        let widthBeforeZoom = first.frame.width
        canvas.pinch(withScale: 1.2, velocity: 0.5)
        XCTAssertGreaterThan(first.frame.width, widthBeforeZoom * 1.05)
        canvas.pinch(withScale: 1 / 1.2, velocity: -0.5)
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
        XCTAssertTrue(first.waitForExistence(timeout: 10))
        app.tapButton(id: "BoardEditor.pagePicker")
        app.buttons["Page 2 of 2"].tap()
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoSelectionView.image(for: 12)].waitForExistence(timeout: 5))
        app.tapButton(id: "BoardEditor.pagePicker")
        app.buttons["Page 1 of 2"].tap()
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        let printButton = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.printButton]
        XCTAssertTrue(printButton.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(printButton.frame.minX, app.frame.width * 0.7)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoSelectionView.layoutButton].isHittable)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoSelectionView.shareButton].isHittable)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.PreviewScreen.nextPage].exists)
        app.tapButton(id: AccessibilityIdentifiers.PreviewScreen.formattingButton)
        XCTAssertTrue(app.navigationBars["Formatting"].waitForExistence(timeout: 5))
        app.buttons[AccessibilityIdentifiersSSUI.PopupHeader.closeButton].tap()
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Page editor landscape"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        XCUIDevice.shared.orientation = requiredOrientation

        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.printButton)
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

        app.tapButton(id: ids.selectModeButton)
        first.tap()
        app.tapButton(id: ids.deleteButton)
        respondYesToAlert()

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
        XCTAssertFalse(app.staticTexts["BoardEditor.pageStatus"].exists)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.PreviewScreen.nextPage].exists)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.PreviewScreen.previousPage].exists)
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
        tapBackButton()
    }
}
