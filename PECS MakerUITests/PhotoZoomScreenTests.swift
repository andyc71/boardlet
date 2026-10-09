//
//  PhotoZoomScreenTests.swift
//  PhotoSelectionTests
//
//  Created by Andy on 2/6/2024.
//

import XCTest

///These tests cover the sceen you get in the photo browser when you zoom a photo and
///have the option to crop it.
class PhotoZoomScreenTests: PECSTestsBase {

    @MainActor func testPreviewCellOpensCardEditor() {
        let gridPrint = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.printButton]
        if gridPrint.exists {
            gridPrint.tap()
        } else {
            app.tapButton(id: AccessibilityIdentifiers.MainMenu.previewAndPrintButton)
        }

        let previewCell = app.buttons[AccessibilityIdentifiers.PreviewScreen.cell(for: 0)]
        XCTAssertTrue(previewCell.waitForExistence(timeout: 10))
        let pageScroll = app.descendants(matching: .any)[AccessibilityIdentifiers.PreviewScreen.pageScroll]
        XCTAssertTrue(pageScroll.waitForExistence(timeout: 5))
        XCTAssertEqual(pageScroll.frame.minX, app.windows.firstMatch.frame.minX, accuracy: 2)
        XCTAssertEqual(pageScroll.frame.maxX, app.windows.firstMatch.frame.maxX, accuracy: 2)
        XCTAssertTrue(previewCell.label.contains("card 1") || previewCell.label.contains("tarjeta 1"))
        previewCell.tap()

        let titleField = app.textFields[AccessibilityIdentifiers.PhotoZoomView.titleField]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        app.tapButton(id: AccessibilityIdentifiers.PhotoZoomView.cancelButton)
        XCTAssertTrue(previewCell.waitForExistence(timeout: 10))

        app.tapButton(id: AccessibilityIdentifiers.PreviewScreen.cardsButton)
        let listRow = app.buttons[AccessibilityIdentifiers.PreviewScreen.cardListRow(for: 0)]
        XCTAssertTrue(listRow.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(listRow.frame.height, 44)
        listRow.tap()
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
    }

    @MainActor func testChangeTitleFromZoomedPhoto() {
        let library = app.buttons[AccessibilityIdentifiers.MainMenu.selectPhotoButton]
        if !library.exists {
            app.tapButton(id: AccessibilityIdentifiers.TopicTitleView.menuButton)
        }
        XCTAssertTrue(library.waitForExistence(timeout: 5))
        library.tap()
        selectPhotosFromPicker(itemsToSelect: 1)

        app.tapButton(id: A12SSUI.PhotoCell.image(for: 0))
        let titleField = app.textFields[AccessibilityIdentifiers.PhotoZoomView.titleField]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        let title = "Photo title \(UUID().uuidString)"
        titleField.tap()
        titleField.clearText()
        titleField.typeText(title)

        app.tapButton(id: AccessibilityIdentifiers.PhotoZoomView.saveButton)
        XCTAssertEqual(app.staticTexts[A12SSUI.PhotoCell.title(for: 0)].label, title)

        app.tapButton(id: A12SSUI.PhotoCell.image(for: 0))
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.clearText()
        titleField.typeText("Discarded title")
        app.tapButton(id: AccessibilityIdentifiers.PhotoZoomView.cancelButton)
        XCTAssertEqual(app.staticTexts[A12SSUI.PhotoCell.title(for: 0)].label, title)
    }

    @MainActor func testReplacePhotoFromLibraryKeepsCardInPlace() {
        selectPhotosFromPicker(count: 2, recheckSelections: false)
        guard navigateToPhotoSelectionScreen() else { return }

        app.tapButton(id: A12SSUI.PhotoCell.image(for: 0))
        app.tapButton(id: AccessibilityIdentifiers.PhotoZoomView.replaceButton)
        app.tapButton(id: AccessibilityIdentifiers.PhotoZoomView.replaceFromLibraryButton)

        let picker = SystemPhotoPickerDriver(app: app)
        picker.assertOpen()
        picker.selectPhoto(matching: NSPredicate(
            format: "label CONTAINS %@ OR label CONTAINS %@ OR label CONTAINS %@ OR label CONTAINS %@",
            "February 03, 2020", "February 3, 2020",
            "03 February 2020", "Photo, 3 February 2020"))
        picker.confirmSingleSelectionIfNeeded()
        picker.assertDismissed()
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PhotoZoomView.replaceButton]
            .waitForExistence(timeout: 10))
        app.tapButton(id: AccessibilityIdentifiers.PhotoZoomView.saveButton)
        checkPhotoCountUsingPhotoSelectionScreen(2)
    }
    
    ///Check we can zoom a photo
    @MainActor func testPhotoZoom_ByTappingPhoto() throws {
        try testPhotoZoom()
    }

    @MainActor func testZoomedPhotoShowsAddButtonAndTitle() {
        selectPhotosFromPicker(count: 1, recheckSelections: false)
        guard navigateToPhotoSelectionScreen() else { return }

        app.tapButton(id: A12SSUI.PhotoCell.image(for: 0))
        let photoActions = AccessibilityIdentifiers.PhotoZoomView.self
        let replaceButton = app.buttons[photoActions.replaceButton]
        XCTAssertTrue(replaceButton.waitForExistence(timeout: 10))
        XCTAssertEqual(replaceButton.label, isSpanish ? "Reemplazar foto" : "Replace Photo")
        XCTAssertTrue(app.buttons[photoActions.deleteButton].exists)
        XCTAssertTrue(app.buttons[photoActions.duplicateCardButton].exists)
        XCTAssertTrue(app.buttons[photoActions.useAsBoardCoverButton].exists)
        XCTAssertTrue(app.textFields[AccessibilityIdentifiers.PhotoZoomView.titleField].exists)
        XCTAssertTrue(app.staticTexts[isSpanish ? "Título" : "Title"].exists)
        XCTAssertFalse(app.staticTexts[isSpanish ? "Foto" : "Photo"].exists)
        XCTAssertFalse(app.staticTexts[isSpanish ? "Acciones" : "Actions"].exists)
        XCTAssertTrue(app.buttons[photoActions.editPhotoButton].exists)
        XCTAssertEqual(app.buttons[photoActions.editPhotoButton].label,
                       isSpanish ? "Editar foto" : "Edit Photo")
        XCTAssertTrue(app.navigationBars[isSpanish ? "Editar tarjeta" : "Edit Card"].exists)
        XCTAssertTrue(app.buttons[photoActions.cancelButton].exists)
        XCTAssertTrue(app.buttons[photoActions.saveButton].exists)
    }

    @MainActor func testEditCardUsesTwoColumnsInLandscapeAndPreservesDraftTitle() {
        selectPhotosFromPicker(count: 1, recheckSelections: false)
        guard navigateToPhotoSelectionScreen() else { return }

        app.tapButton(id: A12SSUI.PhotoCell.image(for: 0))

        let photoActions = AccessibilityIdentifiers.PhotoZoomView.self
        let preview = app.descendants(matching: .any)[AccessibilityIdentifiers.TitlesScreen.image(for: 0)]
        let replaceButton = app.buttons[photoActions.replaceButton]
        let titleField = app.textFields[photoActions.titleField]
        let cropButton = app.buttons[photoActions.cropButton]
        let editPhotoButton = app.buttons[photoActions.editPhotoButton]
        let photoHeader = app.staticTexts[isSpanish ? "Foto" : "Photo"].firstMatch
        let titleHeader = app.staticTexts[isSpanish ? "Título" : "Title"].firstMatch
        let actionsHeader = app.staticTexts[isSpanish ? "Acciones" : "Actions"].firstMatch
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))

        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = requiredOrientation }

        let landscape = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            self.app.frame.width > self.app.frame.height &&
                preview.exists && replaceButton.isHittable && photoHeader.exists &&
                cropButton.exists && actionsHeader.exists
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [landscape], timeout: 10), .completed)

        XCTAssertLessThan(preview.frame.midX, app.frame.midX)
        XCTAssertLessThan(replaceButton.frame.midX, app.frame.midX)
        XCTAssertGreaterThan(titleField.frame.midX, app.frame.midX)
        XCTAssertGreaterThan(cropButton.frame.midX, app.frame.midX)
        XCTAssertEqual(photoHeader.frame.minY, titleHeader.frame.minY, accuracy: 12)
        XCTAssertEqual(preview.frame.minY, titleField.frame.minY, accuracy: 12)
        XCTAssertLessThanOrEqual(titleField.frame.minY - app.navigationBars.firstMatch.frame.maxY, 44)
        XCTAssertGreaterThan(actionsHeader.frame.minY, titleField.frame.maxY)
        XCTAssertLessThanOrEqual(actionsHeader.frame.minY - titleField.frame.maxY, 44)
        XCTAssertLessThanOrEqual(preview.frame.maxY, replaceButton.frame.minY + 2)
        XCTAssertLessThanOrEqual(replaceButton.frame.maxY, app.frame.maxY)
        XCTAssertGreaterThan(preview.frame.height, app.frame.height * 0.4)
        XCTAssertGreaterThan(titleField.frame.width, preview.frame.width)
        XCTAssertGreaterThanOrEqual(replaceButton.frame.height, 44)
        XCTAssertLessThanOrEqual(replaceButton.frame.height, 54)
        XCTAssertGreaterThanOrEqual(cropButton.frame.height, 44)
        XCTAssertGreaterThanOrEqual(editPhotoButton.frame.height, 44)
        XCTAssertTrue(app.buttons[photoActions.duplicateCardButton].exists)
        XCTAssertTrue(app.buttons[photoActions.useAsBoardCoverButton].exists)

        let draftTitle = "Unsaved landscape title"
        titleField.tap()
        titleField.clearText()
        titleField.typeText(draftTitle)

        XCUIDevice.shared.orientation = .portrait
        let portrait = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            self.app.frame.height > self.app.frame.width &&
                (titleField.value as? String) == draftTitle
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [portrait], timeout: 10), .completed)
    }
    
    ///Check we can zoom a photo
    @MainActor func testPhotoZoom() throws {

        let photoCount = 2
        selectPhotosFromPicker(count: photoCount, recheckSelections: false)
        
        guard navigateToPhotoSelectionScreen() else { return }

        //Zoom the first photo by tapping it.
        app.tapButton(id: A12SSUI.PhotoCell.image(for: 0))
        
        //Return to the photo grid with Cancel.
        app.tapButton(id: AccessibilityIdentifiers.PhotoZoomView.cancelButton)
        
        //Verify we are back on the select photos screen.
        guard appScreenIsVisible(.changeSelections) else { return }
        
    }
    
    ///Check we can crop a photo
    @MainActor func testPhotoCrop() throws {

        let photoCount = 2
        selectPhotosFromPicker(count: photoCount, recheckSelections: false)
        
        guard navigateToPhotoSelectionScreen() else { return }
        
        //Zoom the first photo by tapping it.
        app.tapButton(id: A12SSUI.PhotoCell.image(for: 0))
        
        //Make sure the photo actions are available before cropping.
        app.selectButton("editBoardPhoto")
        app.selectButton(A12.PhotoZoomView.deleteButton)
        let cropButton = app.selectButton(A12.PhotoZoomView.cropButton)
        app.selectButton(A12.PhotoZoomView.revertButton, assertType: .doesNotExist)
        app.selectButton(A12.PhotoZoomView.saveButton)

        //Crop the photo.
        cropButton?.tap()
        
        //Now we should have a revert button and a save button.
        let revertButton = app.selectButton(A12.PhotoZoomView.revertButton)
        let saveButton = app.selectButton(A12.PhotoZoomView.saveButton)

        //Tap revert.
        revertButton?.tap()
        
        //Crop again.
        cropButton?.tap()
        
        //Save an close
        saveButton?.tap()
        
        //Verify we are back on the select photos screen.
        guard appScreenIsVisible(.changeSelections) else { return }
        
    }

    @MainActor func testDeleteFromPhotoViewer() {
        selectPhotosFromPicker(count: 2, recheckSelections: false)
        guard navigateToPhotoSelectionScreen() else { return }

        app.tapButton(id: A12SSUI.PhotoCell.image(for: 0))
        app.tapButton(id: A12.PhotoZoomView.deleteButton)
        respondYesToAlert()

        checkPhotoCountUsingPhotoSelectionScreen(1)
    }

    @MainActor func testPhotoEditorControls() {
        selectPhotosFromPicker(count: 1, recheckSelections: false)
        guard navigateToPhotoSelectionScreen() else { return }

        app.tapButton(id: A12SSUI.PhotoCell.image(for: 0))
        app.tapButton(id: "editBoardPhoto")

        let cancelButton = app.buttons["photoEditorCancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["photoEditorDone"].exists)
        let editorScreenshot = XCTAttachment(screenshot: app.screenshot())
        editorScreenshot.name = "Photo editor controls"
        editorScreenshot.lifetime = .keepAlways
        add(editorScreenshot)

        // Open the adjustment control immediately to the left of Done.
        app.buttons["photoEditorDone"]
            .coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0.5))
            .withOffset(CGVector(dx: -28, dy: 0))
            .tap()
        XCTAssertTrue(app.staticTexts["Brightness"].waitForExistence(timeout: 5))
        let adjustmentScreenshot = XCTAttachment(screenshot: app.screenshot())
        adjustmentScreenshot.name = "Photo editor adjustments"
        adjustmentScreenshot.lifetime = .keepAlways
        add(adjustmentScreenshot)

        cancelButton.tap()

        XCTAssertTrue(app.buttons["editBoardPhoto"].waitForExistence(timeout: 10))
    }
    
    @MainActor func selectPhotosFromPicker(count: Int, recheckSelections: Bool) {
        
        //guard appScreenIsVisible(.selectPhotos)
        
        selectPhotos(startScreen: .mainMenu, itemsToSelect: count, firstItem: 0, expectedCount: count, recheckSelections: recheckSelections)
        
    }
    
    

    
}
