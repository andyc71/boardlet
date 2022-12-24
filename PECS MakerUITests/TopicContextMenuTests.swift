//
//  TopicContextMenuTests.swift
//  TopicContextMenuTests
//
//  Created by Andy on 21/12/2022.
//

import XCTest

///Tests the context menu associated with a topic.
class TopicContextMenuTests: PECSTestsBase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    func testTopicContextMenuEdit() {
        
        //Navigate to the topic screen
        navigateToTopicScreen()
        
        displayTopicContextMenuAndChooseEdit(topicIndex: 0)
        
        //Go back to the titles sreeen menu and repeat. This is important
        //because sometimes the context menu only works the first time if
        //we're not managing SwiftUI state properly.
        tapBackButton()

        displayTopicContextMenuAndChooseEdit(topicIndex: 0)
    }
    
    
    func testTopicContextMenuRename() {
        
        //Navigate to the topic screen
        navigateToTopicScreen()
        
        displayTopicContextMenuAndChooseRename(topicIndex: 0)

        //Repeat to make sure the menu button works more than once.
        displayTopicContextMenuAndChooseRename(topicIndex: 0)
    }
    
    func testTopicContextMenuDuplicate() {
        
        //Navigate to the topic screen
        navigateToTopicScreen()
        
        displayTopicContextMenuAndChooseDuplicate(topicIndex: 0, expectedCountAfterOperation: 2)

        //Repeat to make sure the menu button works more than once.
        displayTopicContextMenuAndChooseDuplicate(topicIndex: 0, expectedCountAfterOperation: 3)
    }
    
    func testTopicContextMenuDelete() {
        
        //Navigate to the topic screen
        navigateToTopicScreen()
        
        displayTopicContextMenuAndChooseDelete(topicIndex: 0, expectedCountAfterOperation: 0)
    }
    


    
    func navigateToTopicScreen() {
        //Nothing to do at present because the base class handles it
        //at the start of the test. Might be useful in future if we
        //decide to move the topic screen elsewhere.
        tapBackButton()
        
    }
    
    func displayTopicContextMenuAndChooseEdit(topicIndex: Int) {
        //Get the name of the topic name we're going to work with
        //let topicName = defaultTopicName
        
        //Display the context menu and choose edit.
        displayTopicContextMenuAndSelectOption(topicIndex: 0, menuOption: AccessibilityIdentifiers.TopicContextMenu.editButton)
        
        //Check that we're now on the edit page for the selected topic
        app.selectStaticText(AccessibilityIdentifiers.PageLayoutTitleView.titleField)
    }
    
    func displayTopicContextMenuAndChooseRename(topicIndex: Int) {
        //Get the name of the topic name we're going to work with
        //let topicName = defaultTopicName
        
        //Display the context menu and choose rename.
        displayTopicContextMenuAndSelectOption(topicIndex: 0, menuOption: AccessibilityIdentifiers.TopicContextMenu.renameButton)

        //Fill in the topic popup with a random name
        let topicName = completeEditPopupWithRandomText(prefix: "Topic number ")
        
        //Make sure we now have a topic with the new name
        app.selectButton(topicName)
        
    }
    
    func displayTopicContextMenuAndChooseDuplicate(topicIndex: Int, expectedCountAfterOperation: Int) {
        //Get the name of the topic name we're going to work with
        //let topicName = defaultTopicName
        
        //Display the context menu and choose duplicate.
        displayTopicContextMenuAndSelectOption(topicIndex: 0, menuOption: AccessibilityIdentifiers.TopicContextMenu.duplicateButton)
        
        checkTopicCount(expectedCountAfterOperation)
    }
    
    func displayTopicContextMenuAndChooseDelete(topicIndex: Int, expectedCountAfterOperation: Int) {
        //Get the name of the topic name we're going to work with
        //let topicName = defaultTopicName
        
        //Display the context menu and choose duplicate.
        displayTopicContextMenuAndSelectOption(topicIndex: 0, menuOption: AccessibilityIdentifiers.TopicContextMenu.deleteButton)
        
        //Tap Yes in the delete topic prompt.
        respondYesToAlert()

        checkTopicCount(expectedCountAfterOperation)
    }
    
    func displayTopicContextMenuAndSelectOption(topicIndex: Int, menuOption: String) {
        
        //Get the topic cell
        guard let topicCell = app.selectButton(AccessibilityIdentifiers.TopicSelectionView.topicButton(for: topicIndex)) else {
            return
        }
            
        //Long press the cell to display the context menu
        topicCell.press(forDuration: 2)
        
        //Get the menu button and press
        app.tapButton(id: menuOption)
    }
    
}
