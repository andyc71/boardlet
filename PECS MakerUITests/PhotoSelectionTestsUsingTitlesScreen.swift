//
//  PhotoSelectionTestsUsingTitlesScreen.swift
//  PhotoSelectionTestsUsingTitlesScreen
//
//  Created by Andy on 22/12/2022.
//

import XCTest

class PhotoSelectionTestsUsingTitlesScreen: PECSTestsBase {
    
    ///Check deletion of a photo
    func testPhotoDeletion() throws {

        //Select some photos
        let photoCount = 3
        selectPhotosFromMainMenu(count: photoCount, recheckSelections: false)

        //Delete one of the photos and verify the new count.
        deletePhotoUsingTitlesScreen(itemToDelete: 0, photoCount: photoCount - 1)

        //Go into the photo screen and check one
        //photo has been remvoed there as well.
        checkPhotoCount(photoCount - 1)
        
    }
    
    
    ///Check deletion of a photo
    func testPhotoDuplication() throws {

        //Select some photos
        let originalPhotoCount = 3
        selectPhotosFromMainMenu(count: originalPhotoCount, recheckSelections: false)
        
        //Duplicate one of the photos and verify the new count.
        duplicatePhotoUsingTitlesScreen(itemToDuplicate: 0, photoCount: originalPhotoCount + 1)

        //The count on the OOTB photos screen should not have changed
        checkPhotoCount(originalPhotoCount)
        
        //Delete one of the photos and verify the new count.
        deletePhotoUsingTitlesScreen(itemToDelete: 0, photoCount: originalPhotoCount)
        
        //The count on the OOTB photos screen will still be the same because
        //we only deleted the duplicate
        checkPhotoCount(originalPhotoCount)

        //Delete another one of the photos and verify the new count.
        deletePhotoUsingTitlesScreen(itemToDelete: 0, photoCount: originalPhotoCount - 1)
        
        //The count on the OOTB photos screen will now have reduced.
        //we only deleted the duplicate
        checkPhotoCount(originalPhotoCount - 1)

        
    }
    
    func deletePhotoUsingTitlesScreen(itemToDelete: Int, photoCount: Int) {
        
        //Go back in to titles screen.
        app.buttons[AccessibilityIdentifiers.MainMenu.selectTitlesButton].tap()

        //Press the delete button for the first item
        let deleteButton = app.buttons[AccessibilityIdentifiers.TitlesScreen.deleteButton(for: itemToDelete)]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2))
        deleteButton.tap()

        //Verify there is one less item
        for i in 0..<photoCount {
            let identifier = AccessibilityIdentifiers.TitlesScreen.titleText(for: i)
            let textBox = app.textFields[identifier]
            XCTAssertTrue(textBox.waitForExistence(timeout: 2), "Did not find photo with identifier \(identifier)")
        }
    
        //Verify that the last item is gone.
        let textBoxId = AccessibilityIdentifiers.TitlesScreen.titleText(for: photoCount)
        let textBox = app.textFields[textBoxId]
        XCTAssertFalse(textBox.exists, "Text box with id \(textBoxId) should not exist")

        //Return to the main screen
        //app.buttons[AccessibilityIdentifiers.TitlesScreen.doneButton].tap()
        tapBackButton()

    }
    
    func duplicatePhotoUsingTitlesScreen(itemToDuplicate: Int, photoCount: Int) {
        
        //Go back in to titles screen.
        app.buttons[AccessibilityIdentifiers.MainMenu.selectTitlesButton].tap()

        //Press the duplicate button for the first item
        let duplicateButton = app.buttons[AccessibilityIdentifiers.TitlesScreen.duplicateButton(for: itemToDuplicate)]
        XCTAssertTrue(duplicateButton.waitForExistence(timeout: 2))
        duplicateButton.tap()

        //Verify there is one more item
        for i in 0..<photoCount {
            let textBoxId = AccessibilityIdentifiers.TitlesScreen.titleText(for: i)
            let textBox = app.textFields[textBoxId]
            XCTAssertTrue(textBox.waitForExistence(timeout: 2), "Cannot find text box with id: \(textBoxId)")
        }
    
        //Return to the main screen
        //app.buttons[AccessibilityIdentifiers.TitlesScreen.doneButton].tap()
        tapBackButton()


    }

    
}
