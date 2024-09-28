//
//  PhotoSelectionTests.swift
//  PhotoSelectionTests
//
//  Created by Andy on 22/12/2022.
//

import XCTest

class PhotoSelectionScreenTests: PECSTestsBase {

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
            if isIOS16 && isIPad {
                app.forceTapButton(id: A12SSUI.PhotoCell.selectButton(for: itemToDelete))
            }
            else {
                app.tapButton(id: A12SSUI.PhotoCell.selectButton(for: itemToDelete))
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
            //Make sure nothing is already selected.
            //Select all
            app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.selectAllButton)
            //Deselect all
            app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.deselectAllButton)
        }

        //Iterate through each item
        for itemToDelete in itemsToDelete {
            //For some reason the items aren't are hittable but not tappable on iPad (IOS16).
            if isIOS16 && isIPad {
                app.forceTapButton(id: A12SSUI.PhotoCell.deleteButton(for: itemToDelete))
            }
            else {
                app.tapButton(id: A12SSUI.PhotoCell.deleteButton(for: itemToDelete))
            }
                        
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
        XCUIDevice.shared.iosVersion >= 16.0 && XCUIDevice.shared.iosVersion < 16.0
    }
    
    private var isIPad: Bool {
        XCUIDevice.isiPad
    }
    
    func duplicatePhotoUsingPhotoSelectionScreen(itemToDuplicate: Int, expectedCount: Int) {
        
        guard navigateToPhotoSelectionScreen() else { return }

        //Tap the first item to select it
        //For some reason the items aren't are hittable but not tappable on iPad (IOS16).
        if isIOS16 && isIPad {
            app.forceTapButton(id: A12SSUI.PhotoCell.selectButton(for: itemToDuplicate))
        }
        else {
            app.tapButton(id: A12SSUI.PhotoCell.selectButton(for: itemToDuplicate))
        }

        //Tap the duplicate button
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

        //Tap each item to select it
        for itemsToCopy in itemsToCopy {
            //For some reason the items aren't are hittable but not tappable on iPad (IOS16).
            app.forceTapButton(id: A12SSUI.PhotoCell.selectButton(for: itemsToCopy))
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
        var imageId0 = A12SSUI.PhotoCell.image(for: 0)
        var imageId1 = A12SSUI.PhotoCell.image(for: 1)
        var imageId2 = A12SSUI.PhotoCell.image(for: 2)
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
        guard var imageId0 = app.selectButton(item0Title) else { return }
        guard var imageId1 = app.selectButton(item1Title) else { return }
        guard var imageId2 = app.selectButton(item2Title) else { return }
        
        // Check that the first image is now in the third position
        //Everything else has moved back one place.
        let image0PositionNew = imageId0.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).screenPoint
        let image1PositionNew = imageId1.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).screenPoint
        let image2PositionNew = imageId2.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).screenPoint
        
        XCTAssertEqual(image0PositionNew, image2ScreenPoint)
        XCTAssertEqual(image1PositionNew, image0ScreenPoint)
        XCTAssertEqual(image2PositionNew, image1ScreenPoint)
         
    }
    
    enum RenameMethod { case contextMenu, tapLabel }
    
    @MainActor func testPhotoRename_usingContextMenu() {
        testPhotoRename(method: .contextMenu)
    }
    
    @MainActor func testPhotoRename_byTappingLabel() {
        testPhotoRename(method: .tapLabel)
    }
    
    @MainActor func testPhotoRename(method renameMethod: RenameMethod) {
        
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
        
        //Tap the title to rename it.
        switch renameMethod {
        case .tapLabel:
            label.tap()
        case .contextMenu:
            displayPhotoContextMenuAndChooseRename(photoIndex: 0)
        }
        
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
        label.tap()
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
        app.tapButton(id: A12SSUI.PhotoCell.selectButton(for: 0))
    
        //Make sure it's selected.
        guard let photo = app.selectButton(A12SSUI.PhotoCell.image(for: 0)) else { return }
        XCTAssertTrue(photo.isSelected)
        
        //Tap the title to rename it.
        guard let label = app.selectStaticText(A12SSUI.PhotoCell.title(for: 0)) else { return }
        label.tap()
        
        //Fill in the topic popup with a random name. As long as this doesn't fail we
        //are OK (i.e. the popup appeared successfully.
        _ = completeEditPopupWithRandomText(prefix: "Photo number ", initialValue: nil)
    }
    
}

