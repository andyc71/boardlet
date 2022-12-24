//
//  PhotoSelectionTests.swift
//  PhotoSelectionTests
//
//  Created by Andy on 22/12/2022.
//

import XCTest

class PhotoSelectionScreenTests: PECSTestsBase {
    
    ///Check deletion of a photo
    func testPhotoDeletion() throws {

        //Select some photos
        let photoCount = 5
        selectPhotosFromMainMenu(count: photoCount, recheckSelections: false)

        //Delete the last 2 photos and verify the new count.
        let photosToDelete: [Int] = [3, 4]
        let expectedCount = photoCount - photosToDelete.count
        deletePhotosUsingPhotoSelectionScreen(itemsToDelete: photosToDelete, expectedCount: expectedCount)

        //Go into the photo screen and check one
        //photo has been remvoed there as well.
        checkPhotoCount(expectedCount)
        
    }
    
    
    ///Check duplication of a photo
    func testPhotoDuplication() throws {

        //Select some photos
        let originalPhotoCount = 3
        selectPhotosFromMainMenu(count: originalPhotoCount, recheckSelections: false)
        
        //Duplicate one of the photos and verify the new count.
        duplicatePhotoUsingPhotoSelectionScreen(itemToDuplicate: 0, expectedCount: originalPhotoCount + 1)

        //The count on the OOTB photos screen should not have changed
        checkPhotoCount(originalPhotoCount)
        
        //Delete one of the photos and verify the new count.
        deletePhotosUsingPhotoSelectionScreen(itemsToDelete: [0], expectedCount: originalPhotoCount)
        
        //The count on the OOTB photos screen will still be the same because
        //we only deleted the duplicate
        checkPhotoCount(originalPhotoCount)

        //Delete another one of the photos and verify the new count.
        deletePhotosUsingPhotoSelectionScreen(itemsToDelete: [0], expectedCount: originalPhotoCount - 1)
        
        //The count on the OOTB photos screen will now have reduced.
        //we only deleted the duplicate
        checkPhotoCount(originalPhotoCount - 1)
    }
    
    ///Check coping of a photo from current topic to another topic
    func testPhotoCopy() throws {
        
        //Setup has created one topic. Now we need to create another
        //so we have a destination for the copied photo.
        tapBackButton()
        createTopic()
        
        //Since we don't know whether the new topic is index 0 or 1, we
        //go back the the home screen and select index 0
        tapBackButton()
        selectTopic(index: 0)
        
        //Select some photos
        let originalPhotoCount = 5
        selectPhotosFromMainMenu(count: originalPhotoCount, recheckSelections: false)
        
        //Copy two of the photos and verify the count doesn't change.
        let photosToCopy = [0, 1]
        copyPhotosUsingPhotoSelectionScreen(itemsToCopy: photosToCopy, expectedCount: originalPhotoCount)

        //The count on the OOTB photos screen should not have changed
        checkPhotoCount(originalPhotoCount)

        //Navigate to the second topic and check it's photo count.
        tapBackButton()
        selectTopic(index: 1)
        checkPhotoCount(photosToCopy.count)
    }
    
    func deletePhotosUsingPhotoSelectionScreen(itemsToDelete: [Int], expectedCount: Int) {
        
        //Go to photo selection screen.
        app.tapButton(id: AccessibilityIdentifiers.MainMenu.changeSelectionsButton)

        //Tap each item to select it
        for itemToDelete in itemsToDelete {
            app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.selectButton(for: itemToDelete))
        }
        
        //Tap the delete button
        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.deleteButton)
        
        //Answer yes to the confirmation
        respondYesToAlert()

        //Verify the expected count after the deletion
        checkPhotoCountUsingPhotoSelectionScreen(expectedCount: expectedCount)
        
        //Return to the main screen
        tapBackButton()

    }
    
    func duplicatePhotoUsingPhotoSelectionScreen(itemToDuplicate: Int, expectedCount: Int) {
        
        //Go to photo selection screen.
        app.tapButton(id: AccessibilityIdentifiers.MainMenu.changeSelectionsButton)

        //Tap the first item to select it
        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.selectButton(for: itemToDuplicate))

        //Tap the duplicate button
        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.duplicateButton)
        
        //Verify the expected count after the duplication
        checkPhotoCountUsingPhotoSelectionScreen(expectedCount: expectedCount)

        //Return to the main screen
        //app.buttons[AccessibilityIdentifiers.TitlesScreen.doneButton].tap()
        tapBackButton()


    }
    
    func copyPhotosUsingPhotoSelectionScreen(itemsToCopy: [Int], expectedCount: Int) {
        
        //Go to photo selection screen.
        app.tapButton(id: AccessibilityIdentifiers.MainMenu.changeSelectionsButton)

        //Tap each item to select it
        for itemsToCopy in itemsToCopy {
            app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.selectButton(for: itemsToCopy))
        }
        
        //Tap the copy button
        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.copyButton)
        
        //Select the destination topic. It will be index 1 (even though index 0 is now
        //hidden because the index goes off the topic list rather than the available list.
        app.tapButton(id: AccessibilityIdentifiers.TopicSelectionView.topicButton(for: 1))
        
        //Verify the expected count after the deletion
        checkPhotoCountUsingPhotoSelectionScreen(expectedCount: expectedCount)
        
        //Return to the main screen
        tapBackButton()
    }
    
    func checkPhotoCountUsingPhotoSelectionScreen(expectedCount: Int) {
        
        //Verify that the expected number of items exist.
        for i in 0..<expectedCount {
            app.checkElementExistence(.button, id: AccessibilityIdentifiers.PhotoSelectionView.image(for: i))
        }
        
        //Make sure there are no extra items
        app.checkElementNonExistence(.button, id: AccessibilityIdentifiers.PhotoSelectionView.image(for: expectedCount))
    }

    
}
