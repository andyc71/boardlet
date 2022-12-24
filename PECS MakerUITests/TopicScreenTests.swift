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
        
        //Get the name of the current topic from the main menu.
        let topicName1 = getTopicNameFromMainMenu()
        
        //Navigate to the topic screen
        navigateToTopicScreen()
        
        //Verify we just have 1 topic (as created by the base class setup).
        checkTopicCount(1)
        
        //Verify that the topic on the list has the same title as
        //what we got from the topic's main menu.
        let topicCell = app.selectButton(AccessibilityIdentifiers.TopicSelectionView.topicButton(for: 0))
        XCTAssertEqual(topicCell?.label, topicName1)
        
        //Create a new topic
        createTopic()
        
        //Get the name of the new topic
        let topicName2 = getTopicNameFromMainMenu()

        //Go back to the topics screen.
        navigateToTopicScreen()

        //Verify that the topic on the list has the same title as
        //what we got from the topic's main menu.
        let topicCell2 = app.selectButton(AccessibilityIdentifiers.TopicSelectionView.topicButton(for: 1))
        XCTAssertEqual(topicCell2?.label, topicName2)

        
        //Verify we now have 2 topics.
        checkTopicCount(2)
        
        //Display the new topic
        selectTopic(index: 1)
        
        let currentTopicName2 = getTopicNameFromMainMenu()
        XCTAssertEqual(topicName2, currentTopicName2)
        
    }
    
    func getTopicNameFromMainMenu() -> String?  {
        guard let titleField = app.selectStaticText(AccessibilityIdentifiers.TopicTitleView.titleField) else {
            return nil
        }
        return titleField.label
    }
    
    

    
    func testTopicDeletion() {
        
        //Navigate to the topic screen
        navigateToTopicScreen()
        
        //Put the screen into edit mode so we have
        //the delete buttons visible.
        app.tapButton(id: AccessibilityIdentifiers.TopicSelectionView.editButton)
        
        //Tap the delete button on the first (and only) topic
        app.tapButton(id: AccessibilityIdentifiers.TopicSelectionView.topicDeleteButton(for: 0))
        
        respondYesToAlert()

        //Verify that we now have zero topics
        checkTopicCount(0)
    }
        
    func navigateToTopicScreen() {
        //At present the base class creates a new topic and sends us there. So this
        //function just needs to tap the back button.
        //Might be more useful in future if we
        //decide to move the topic screen elsewhere.
        tapBackButton()
        
    }
    

    
}
