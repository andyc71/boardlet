//
//  PECS_MakerUITests.swift
//  PECS MakerUITests
//
//  Created by Andy on 24/09/2021.
//

import XCTest

class PhotoSelectionScreenUsingTitlesScreenTests: PECSTestsBase {
    
    ///Check deletion of a photo
    func testPhotoDeletion() throws {

        //Select some photos
        let photoCount = 3
        selectPhotosFromMainMenu(count: photoCount, recheckSelections: false)

        //Delete one of the photos and verify the new count.
        deletePhotoUsingTitlesScreen(itemToDelete: 0, photoCount: photoCount - 1)

        //Go into the photo screen and check one
        //photo has been remvoed there as well.
        guard navigateToPhotoSelectionScreen() else { return }
        checkPhotoCountUsingPhotoSelectionScreen(photoCount - 1)
        
    }
    
    
    ///Check deletion of a photo
    func testPhotoDuplication() throws {

        //Select some photos
        let originalPhotoCount = 3
        selectPhotosFromMainMenu(count: originalPhotoCount, recheckSelections: false)
        
        //Duplicate one of the photos and verify the new count.
        duplicatePhotoUsingTitlesScreen(itemToDuplicate: 0, photoCount: originalPhotoCount + 1)

        //The count on the OOTB photos screen should not have changed
        //checkPhotoCount(originalPhotoCount)
        
        //navigateToPhotoSelectionScreen()
        //Make sure we have one more photo
        guard navigateToPhotoSelectionScreen() else { return }
        checkPhotoCountUsingPhotoSelectionScreen(originalPhotoCount + 1)
        returnToMainMenu()
        
        //Delete one of the photos and verify the new count.
        deletePhotoUsingTitlesScreen(itemToDelete: 0, photoCount: originalPhotoCount)
        
        //The count on the OOTB photos screen will still be the same because
        //we only deleted the duplicate
        //checkPhotoCount(originalPhotoCount)
        
        guard navigateToPhotoSelectionScreen() else { return }
        checkPhotoCountUsingPhotoSelectionScreen(originalPhotoCount)
        returnToMainMenu()

        //Delete another one of the photos and verify the new count.
        deletePhotoUsingTitlesScreen(itemToDelete: 0, photoCount: originalPhotoCount - 1)
        
        //The count on the OOTB photos screen will now have reduced.
        //we only deleted the duplicate
        //checkPhotoCount(originalPhotoCount - 1)
        
        guard navigateToPhotoSelectionScreen() else { return }
        checkPhotoCountUsingPhotoSelectionScreen(originalPhotoCount - 1)

    }
    
    func deletePhotoUsingTitlesScreen(itemToDelete: Int, photoCount: Int) {
        
        //Go back in to titles screen.
        app.tapButton(id: AccessibilityIdentifiers.MainMenu.selectTitlesButton)

        //Press the delete button for the first item
        app.tapButton(id: AccessibilityIdentifiers.TitlesScreen.deleteButton(for: itemToDelete))

        //Verify there is one less item
        for i in 0..<photoCount {
            let textBox = app.textFields[AccessibilityIdentifiers.TitlesScreen.titleText(for: i)]
            XCTAssertTrue(textBox.waitForExistence(timeout: 2))
        }
    
        //Verify that the last item is gone.
        let textBoxId = AccessibilityIdentifiers.TitlesScreen.titleText(for: photoCount)
        let textBox = app.textFields[textBoxId]
        XCTAssertFalse(textBox.exists, "Text box with id \(textBoxId) should not exist")

        //Return to the main screen
        returnToMainMenu()
    

    }
    
    func duplicatePhotoUsingTitlesScreen(itemToDuplicate: Int, photoCount: Int) {
        
        //Go back in to titles screen.
        app.tapButton(id: AccessibilityIdentifiers.MainMenu.selectTitlesButton)

        //Press the duplicate button for the first item
        app.tapButton(id: AccessibilityIdentifiers.TitlesScreen.duplicateButton(for: itemToDuplicate))

        //Verify there is one more item
        for i in 0..<photoCount {
            let textBoxId = AccessibilityIdentifiers.TitlesScreen.titleText(for: i)
            let textBox = app.textFields[textBoxId]
            XCTAssertTrue(textBox.waitForExistence(timeout: 2), "Cannot find text box with id: \(textBoxId)")
        }
    
        //Return to the main screen
        returnToMainMenu()

    }
    
    func testPhotoReordering() {
        
        //Select photos with the picker.
        let count = 3
        selectPhotosFromMainMenu(count: count, recheckSelections: false)
        
        //Add some titles. We will need these to keep track of the items.
        completeTitles(count: count)
        
        let item0Title = makePhotoTitle(for: 0)
        let item1Title = makePhotoTitle(for: 1)
        let item2Title = makePhotoTitle(for: 2)
        
        //Now go into the photo selection and re-order the items.
        guard navigateToPhotoSelectionScreen() else { return }
        
        let id0 = AccessibilityIdentifiers.PhotoSelectionView.image(for: 0)
        let id1 = AccessibilityIdentifiers.PhotoSelectionView.image(for: 1)
        let id2 = AccessibilityIdentifiers.PhotoSelectionView.image(for: 2)
        guard let image0 = app.selectButton(id0) else { return }
        guard let image1 = app.selectButton(id1) else { return }
        guard let image2 = app.selectButton(id2) else { return }
        
        //XCTAssertEqual(image0.accessibilityLabel, item0Title)
        //XCTAssertEqual(image2.accessibilityLabel, item2Title)

        // Drag the first image to the third position. The result is that the first image
        //goes to the end, and everything else goes back one place
        //(i.e.image2 becomes 1, and image1 beccomes 0.
        let image0Position = image0.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let image1Position = image1.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let image2Position = image2.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        image0Position.press(forDuration: 0.5, thenDragTo: image2Position)

        //Re-get item 0 and item 2 using their titles. We can't use the accessibility identifier
        //because it changes based on the index of the item within the grid.
        guard let item0 = app.selectButton(item0Title) else { return }
        guard let item1 = app.selectButton(item1Title) else { return }
        guard let item2 = app.selectButton(item2Title) else { return }
        
        // Check that the first image is now in the third position
        //Everything else has moved back one place.
        let item0Position = item0.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let item1Position = item1.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let item2Position = item2.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        XCTAssertEqual(item0Position.screenPoint, image2Position.screenPoint)
        XCTAssertEqual(item1Position.screenPoint, image0Position.screenPoint)
        XCTAssertEqual(item2Position.screenPoint, image1Position.screenPoint)
         
    }
    

    
}
