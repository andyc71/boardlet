//
//  TopicScreenTests.swift
//  TopicScreenTests
//
//  Created by Andy on 21/12/2022.
//

import XCTest

///Tests the topic selection screen.
class TopicScreenTests: PECSTestsBase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    func testTopicCreationAndSelection() {
        
        guard appVersionSupportsTopics else { return }
            
        //Get the name of the current topic from the main menu.
        //let topicName1 = getTopicNameFromMainMenu()
        
        //Navigate to the topic screen
        navigateToTopicScreenFromMainMenu()
        
        //Verify we just have 1 topic (as created by the base class setup).
        checkTopicCount(1)
        
        //Check that the topic shows as selected in the
        //Topic selection view.
        checkTopicIsSelected(index: 0, isSelected: true)

        //Get the name of the topic
        let buttonID = AccessibilityIdentifiers.TopicSelectionView.topicButton(for: 0)
        guard let topicCell = app.selectButton(buttonID) else {
            return
        }
        
        let topicName = topicCell.label
        
        //app.tapButton(id: buttonID)
        
        //Navigate to the main menu
        //app.swipeDown()
        //topicCell.
        //topicCell.press(forDuration: 2)
        //topicCell.forceTap()
        
        app.tapButton(id: buttonID)
    
        //Check that the topic title on the menu screen is the one we're supposed to have gone to
        checkTopicTitleOnMainMenu(topicName: topicName)
        
        navigateToTopicScreenFromMainMenu()
        
        //Check that the topic shows as selected in the
        //Topic selection view.
        checkTopicIsSelected(index: 0, isSelected: true)
        
        //Create a new topic
        createTopic()
        
        //Go back to the topics screen.
        navigateToTopicScreenFromMainMenu()
        
        //Verify we now have 2 topics.
        checkTopicCount(2)
        
        //Check that the second topic shows as selected in the
        //Topic selection view.
        checkTopicIsSelected(index: 0, isSelected: false)
        checkTopicIsSelected(index: 1, isSelected: true)

        //Get the name of the new topic cell.
        let id = AccessibilityIdentifiers.TopicSelectionView.topicButton(for: 1)
        guard let topicCell2 = app.selectButton(id) else {
            return
        }

        let topicName2 = topicCell2.label
        
        //Navigate to the main menu
        app.tapButton(id: id)
        //topicCell2.tap()
                
        //Check that the topic title on the menu screen is the one we're supposed to have gone to
        checkTopicTitleOnMainMenu(topicName: topicName2)
        
    }
    
    func checkTopicIsSelected(index: Int, isSelected: Bool) {
        
        //Topics are only selected in split view.
        if !isSplitView {
            return
        }
        
        //Get the ID  the new cell.
        let id = AccessibilityIdentifiers.TopicSelectionView.topicButton(for: index)
        guard let topicCell = app.selectButton(id) else {
            return
        }
        if isSelected {
            XCTAssertTrue(topicCell.isSelected, "Expected topic at index \(index) to be selected")
        }
        else {
            XCTAssertFalse(topicCell.isSelected, "Expected topic at index \(index) to be unselected")
        }

        
    }
    
    func getTopicNameFromMainMenu() -> String?  {
        guard let titleField = app.selectStaticText(AccessibilityIdentifiers.TopicTitleView.titleField) else {
            return nil
        }
        return titleField.label
    }
    
    

    
    func testTopicDeletion() {
        
        guard appVersionSupportsTopics else { return }

        //Navigate to the topic screen
        navigateToTopicScreenFromMainMenu()
        
        //Put the screen into edit mode so we have
        //the delete buttons visible.
        if XCUIDevice.shared.iosVersion >= 16 {
            app.tapButton(id: AccessibilityIdentifiers.TopicSelectionView.editButton)
        }
        else {
            app.tapButton(id: "Edit")
        }
        
        //Tap the delete button on the first (and only) topic
        //Doesn't work on IOS 14.5 because the delete button doesn't appear in the
        //Accesibility Inspector.
        if XCUIDevice.shared.iosVersion == 14.5 {
            XCTExpectFailure("Topic button has no accessibility identifier on IOS 14.5")
        }
        
        app.tapButton(id: AccessibilityIdentifiers.TopicSelectionView.topicDeleteButton(for: 0))
        
        respondYesToAlert()

        //Verify that we now have zero topics
        checkTopicCount(0)
    }
        
    func testTopicMaximizeButton() {
        
        guard appVersionSupportsTopics else { return }
        
        //Go to the topics screen.
        navigateToTopicScreenFromMainMenu()
        
        let maxButtonID = AccessibilityIdentifiers.TopicSelectionView.maximizeButton
        
        //Make sure there is a maximize button on iPad, and not
        //on iPhone.
        if isSplitView {
            app.tapButton(id: maxButtonID)
            
            //Now we're maximised the button shouldn't exist.
            app.selectButton(maxButtonID, assertType: .doesNotExist)
        }
        else {
            app.selectButton(maxButtonID, assertType: .doesNotExist)
        }
        
        
    }
    
    func testTopicRename() {
        
        guard appVersionSupportsTopics else { return }
        
        //We should be on the main menu for a topic
        //Display the More (...) menu in the toolbar. Not sure why it is an image.
        XCUIApplication().navigationBars.firstMatch.images["More"].tap()
        
        let renameButton = AccessibilityIdentifiers.TopicTitleView.renameButton
        app.tapButton(id: renameButton)
        
        //Fill in the topic popup with a random name
        let topicName = completeEditPopupWithRandomText(prefix: "Topic 99")
        
        //Check that the nav bar now has this title.
        //let navTitle = XCUIApplication().navigationBars.staticTexts[topicName]
        app.selectStaticText(topicName)
        
        returnToTopicScreen(from: .mainMenu)
        
        //Make sure we now have a topic with the new name
        app.selectButton(topicName)
        
    }

    

    
}
