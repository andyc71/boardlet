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

        //Select some photos. Because we have no photos selected, we expect to be taken straight to the picker.
        let photoCount = 5
        selectPhotosFromPicker(count: photoCount, recheckSelections: false)

        //Delete the last 2 photos and verify the new count.
        let photosToDelete: [Int] = [3, 4]
        let expectedCount = photoCount - photosToDelete.count
        deletePhotosUsingPhotoSelectionScreen(itemsToDelete: photosToDelete, expectedCount: expectedCount)

        //Go into the photo screen and check one
        //photo has been remvoed there as well.
        //checkPhotoCountUsingPicker(expectedCount, startScreen: .mainMenu)
        
    }
    
    func selectPhotosFromPicker(count: Int, recheckSelections: Bool) {
        
        //guard appScreenIsVisible(.selectPhotos)
        
        selectPhotos(startScreen: .mainMenu, itemsToSelect: count, firstItem: 0, expectedCount: count, recheckSelections: recheckSelections)
        
    }
    
    
    ///Check duplication of a photo
    func testPhotoDuplication() throws {

        //Select some photos
        let originalPhotoCount = 3
        selectPhotosFromPicker(count: originalPhotoCount, recheckSelections: false)
        
        //Duplicate one of the photos and verify the new count.
        duplicatePhotoUsingPhotoSelectionScreen(itemToDuplicate: 0, expectedCount: originalPhotoCount + 1)

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
    func testPhotoCopy() throws {
        
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
        
    func navigateToLayoutScreen() -> Bool {
        guard appScreenIsVisible(.mainMenu) else { return false }
        app.tapButton(id: AccessibilityIdentifiers.MainMenu.selectLayoutButton)
        return true
    }

    
    func deletePhotosUsingPhotoSelectionScreen(itemsToDelete: [Int], expectedCount: Int) {
        
        guard navigateToPhotoSelectionScreen() else { return }
        
        if isSplitView {
            //Make sure nothing is already selected.
            //Select all
            app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.selectAllButton)
            //Deselect all
            app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.deselectAllButton)
        }
            
        //Tap each item to select it
        for itemToDelete in itemsToDelete {
            //For some reason the items aren't are hittable but not tappable on iPad (IOS16).
            app.forceTapButton(id: AccessibilityIdentifiers.PhotoSelectionView.selectButton(for: itemToDelete))
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
    
    func duplicatePhotoUsingPhotoSelectionScreen(itemToDuplicate: Int, expectedCount: Int) {
        
        guard navigateToPhotoSelectionScreen() else { return }

        //Tap the first item to select it
        //For some reason the items aren't are hittable but not tappable on iPad (IOS16).
        app.forceTapButton(id: AccessibilityIdentifiers.PhotoSelectionView.selectButton(for: itemToDuplicate))

        //Tap the duplicate button
        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.duplicateButton)
        
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

        //Tap each item to select it
        for itemsToCopy in itemsToCopy {
            //For some reason the items aren't are hittable but not tappable on iPad (IOS16).
            app.forceTapButton(id: AccessibilityIdentifiers.PhotoSelectionView.selectButton(for: itemsToCopy))
        }
        
        //Tap the copy button
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
