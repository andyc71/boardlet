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
        navigateToTopicScreenFromMainMenu()

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
        let topicName = displayTopicContextMenuAndSelectOption(topicIndex: 0, accessibilityID: AccessibilityIdentifiers.TopicContextMenu.editButton, menuText: "Edit")
        
        //Check that we're now on the edit page for the selected topic
        //app.selectStaticText(AccessibilityIdentifiers.TopicTitleView.titleField)
        checkTopicTitleOnMainMenu(topicName: topicName)
    }
    
    func displayTopicContextMenuAndChooseRename(topicIndex: Int) {
        //Get the name of the topic name we're going to work with
        //let topicName = defaultTopicName
        
        //Display the context menu and choose rename.
        displayTopicContextMenuAndSelectOption(topicIndex: 0, accessibilityID: AccessibilityIdentifiers.TopicContextMenu.renameButton, menuText: "Rename")

        //Fill in the topic popup with a random name
        let topicName = completeEditPopupWithRandomText(prefix: "Topic number ")
        
        //Make sure we now have a topic with the new name
        app.selectButton(topicName)
        
    }
    
    func displayTopicContextMenuAndChooseDuplicate(topicIndex: Int, expectedCountAfterOperation: Int) {
        //Get the name of the topic name we're going to work with
        //let topicName = defaultTopicName
        
        //Display the context menu and choose duplicate.
        displayTopicContextMenuAndSelectOption(topicIndex: 0, accessibilityID: AccessibilityIdentifiers.TopicContextMenu.duplicateButton, menuText: "Duplicate")
        
        checkTopicCount(expectedCountAfterOperation)
    }
    
    func displayTopicContextMenuAndChooseDelete(topicIndex: Int, expectedCountAfterOperation: Int) {
        //Get the name of the topic name we're going to work with
        //let topicName = defaultTopicName
        
        //Display the context menu and choose duplicate.
        displayTopicContextMenuAndSelectOption(topicIndex: 0, accessibilityID: AccessibilityIdentifiers.TopicContextMenu.deleteButton, menuText: "Delete")
        
        //Tap Yes in the delete topic prompt.
        respondYesToAlert()

        checkTopicCount(expectedCountAfterOperation)
    }
    
    @discardableResult
    func displayTopicContextMenuAndSelectOption(topicIndex: Int, accessibilityID: String, menuText: String) -> String {
        
        //Get the topic cell
        guard let topicCell = app.selectButton(AccessibilityIdentifiers.TopicSelectionView.topicButton(for: topicIndex)) else {
            return ""
        }
            
        //Long press the cell to display the context menu. Allowing force if needed because of IOS15.5 issue
        //where the topic is sometimes not hittable. Also worthwhile checking where the ContextMenu is
        //attached to the the view because we might be tapping on some padding around the control instead of
        //the control itself.
        topicCell.press(forDuration: 2, canForce: true)
        
        let label = topicCell.label
        
        //Get the menu button and press
        if XCUIDevice.shared.iosVersion >= 16.0 {
            app.tapButton(id: accessibilityID)
        }
        else {
            //Prior to IOS 16 we dnot have an accessibility idenfitier so we have to
            //use the menu text.
            //We have to be more specific than app.buttons because the chances of finding
            //more than one item are too high. The alternative would be to find all of them
            //and check which one is hittable.
            let button = app.cells.buttons[menuText]
            XCTAssertTrue(button.waitForExistence(timeout: 2), "Could not find button named \(menuText)")
            button.tap()
        }
        
        return label
    }
    
}
