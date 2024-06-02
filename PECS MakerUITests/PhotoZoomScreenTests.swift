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
    @MainActor func testPhotoZoom() throws {

        let photoCount = 2
        selectPhotosFromPicker(count: photoCount, recheckSelections: false)

        //Zoom the first photo by tapping it.
        app.tapButton(id: A12SSUI.PhotoCell.image(for: 0))
        
        //Unzoom the photo using the close button.
        app.tapButton(id: A12.PhotoZoomView.closeButton)
        
        //Verify we are back on the select photos screen.
        guard appScreenIsVisible(.changeSelections) else { return }
        
    }
    
    ///Check we can crop a photo
    @MainActor func testPhotoCrop() throws {

        let photoCount = 2
        selectPhotosFromPicker(count: photoCount, recheckSelections: false)
        
        //Zoom the first photo by tapping it.
        app.tapButton(id: A12SSUI.PhotoCell.image(for: 0))
        
        //Make sure we only have Crop and Close buttons.
        let closeButton = app.selectButton(A12.PhotoZoomView.closeButton)
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
    
    @MainActor func selectPhotosFromPicker(count: Int, recheckSelections: Bool) {
        
        //guard appScreenIsVisible(.selectPhotos)
        
        selectPhotos(startScreen: .mainMenu, itemsToSelect: count, firstItem: 0, expectedCount: count, recheckSelections: recheckSelections)
        
    }
    
    

    
}
