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
    
    ///Check we can zoom a photo
    @MainActor func testPhotoZoom_ByTappingPhoto() throws {
        
        try testPhotoZoom(method: .tapPhoto)
    }

    ///Check we can zoom a photo
    @MainActor func testPhotoZoom_UsingContextMenu() throws {
        
        try testPhotoZoom(method: .contextMenu)
    }
    
    enum PhotoZoomMethod { case contextMenu, tapPhoto}
    
    ///Check we can zoom a photo
    @MainActor func testPhotoZoom(method: PhotoZoomMethod) throws {

        let photoCount = 2
        selectPhotosFromPicker(count: photoCount, recheckSelections: false)
        
        guard navigateToPhotoSelectionScreen() else { return }

        switch method {
            
        case.contextMenu:
            displayPhotoContextMenuAndChooseEdit(photoIndex: 0)
            
        case .tapPhoto:
            //Zoom the first photo by tapping it.
            app.tapButton(id: A12SSUI.PhotoCell.image(for: 0))
        }
        
        //Return to the photo grid with the navigation back button.
        tapBackButton()
        
        //Verify we are back on the select photos screen.
        guard appScreenIsVisible(.changeSelections) else { return }
        
    }
    
    func displayPhotoContextMenuAndChooseEdit(photoIndex: Int) {
        
        //Display the context menu and choose rename.
        displayPhotoContextMenuAndSelectOption(photoIndex: 0, accessibilityID: AccessibilityIdentifiers.PhotoContextMenu.editButton, menuText: "Edit")

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
        app.selectButton(A12.PhotoZoomView.saveButton, assertType: .doesNotExist)

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
