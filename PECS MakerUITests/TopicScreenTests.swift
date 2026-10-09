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
        
        //Put the screen into selection mode, select the topic, then delete it
        //from the toolbar just as on the photo list screen.
        if XCUIDevice.shared.iosVersion >= 16 {
            app.tapButton(id: AccessibilityIdentifiers.TopicSelectionView.selectButton)
        }
        else {
            app.tapButton(id: "Select")
        }

        app.tapButton(id: AccessibilityIdentifiers.TopicSelectionView.topicButton(for: 0))
        app.tapButton(id: AccessibilityIdentifiers.TopicSelectionView.deleteSelectionButton)
        
        respondYesToAlert()

        //Verify that we now have zero topics
        checkTopicCount(0)
    }
        
    func testTopicMaximizeButton() {
        
        guard appVersionSupportsTopics else { return }
        
        //Go to the topics screen.
        navigateToTopicScreenFromMainMenu()
        if isSplitView && !isTopicViewVisible {
            // On iPadOS 18 the sidebar toggle can reveal the board menu first.
            let boardsBackButton = app.buttons["BackButton"].firstMatch
            if boardsBackButton.exists { boardsBackButton.tap() }
        }

        let maxButtonID = AccessibilityIdentifiers.TopicSelectionView.maximizeButton
        let restoreButtonID = AccessibilityIdentifiers.TopicSelectionView.restoreSplitViewButton
        
        //Make sure there is a maximize button on iPad, and not
        //on iPhone.
        if isSplitView {
            // Recover a persisted maximized state from an earlier test run.
            if app.buttons[restoreButtonID].exists {
                app.tapButton(id: restoreButtonID)
                navigateToTopicScreenFromMainMenu()
                if !isTopicViewVisible {
                    let boardsBackButton = app.buttons["BackButton"].firstMatch
                    if boardsBackButton.exists { boardsBackButton.tap() }
                }
            }
            app.tapButton(id: maxButtonID)
            
            // The full-screen topics screen offers a way back, even after relaunch.
            app.selectButton(maxButtonID, assertType: .doesNotExist)
            XCTAssertTrue(app.buttons[restoreButtonID].waitForExistence(timeout: 5))

            app.terminate()
            app.launch()
            XCTAssertTrue(app.buttons[restoreButtonID].waitForExistence(timeout: 5))

            app.tapButton(id: restoreButtonID)
            navigateToTopicScreenFromMainMenu()
            if !isTopicViewVisible {
                let boardsBackButton = app.buttons["BackButton"].firstMatch
                if boardsBackButton.exists { boardsBackButton.tap() }
            }
            XCTAssertTrue(app.buttons[maxButtonID].waitForExistence(timeout: 5))
            app.selectButton(restoreButtonID, assertType: .doesNotExist)
            checkTopicIsSelected(index: 0, isSelected: true)
        }
        else {
            app.selectButton(maxButtonID, assertType: .doesNotExist)
            app.selectButton(restoreButtonID, assertType: .doesNotExist)
        }
        
        
    }

    func testTopicSidebarToolbarOrderAndNewBoardPlacement() {
        guard appVersionSupportsTopics, isSplitView else { return }

        let restoreButton = app.buttons[AccessibilityIdentifiers.TopicSelectionView.restoreSplitViewButton]
        if restoreButton.waitForExistence(timeout: 2) {
            restoreButton.tap()
        }

        navigateToTopicScreenFromMainMenu()

        let sidebarButtons = app.navigationBars.buttons.matching(NSPredicate(
            format: "identifier == 'ToggleSidebar' OR label == 'Show Sidebar' OR label == 'Hide Sidebar' OR label == 'Mostrar barra lateral' OR label == 'Ocultar barra lateral'"
        ))
        let sidebarButton = sidebarButtons.firstMatch
        let zoomButton = app.buttons[AccessibilityIdentifiers.TopicSelectionView.maximizeButton]
        let moreButton = app.buttons[AccessibilityIdentifiers.TopicSelectionView.menuButton]
        let selectButton = app.buttons[AccessibilityIdentifiers.TopicSelectionView.selectButton]
        let newBoardButton = app.buttons[AccessibilityIdentifiers.TopicSelectionView.createDesignButton1]

        for button in [sidebarButton, zoomButton, newBoardButton] {
            XCTAssertTrue(button.waitForExistence(timeout: 5), app.debugDescription)
        }

        XCTAssertEqual(sidebarButtons.count, 1, app.debugDescription)
        XCTAssertLessThan(zoomButton.frame.maxX, sidebarButton.frame.minX)
        XCTAssertFalse(moreButton.exists)
        XCTAssertFalse(selectButton.exists)
        XCTAssertGreaterThan(newBoardButton.frame.midY, app.frame.height * 0.75)

        zoomButton.tap()

        XCTAssertTrue(restoreButton.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(moreButton.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(selectButton.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertEqual(sidebarButtons.count, 1, app.debugDescription)
        XCTAssertLessThan(restoreButton.frame.maxX, moreButton.frame.minX)
        XCTAssertLessThan(moreButton.frame.maxX, selectButton.frame.minX)
        XCTAssertGreaterThan(moreButton.frame.midX, app.frame.midX)

        restoreButton.tap()
        XCTAssertTrue(zoomButton.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertEqual(sidebarButtons.count, 1, app.debugDescription)
        XCTAssertFalse(moreButton.exists)
        XCTAssertFalse(selectButton.exists)
    }
    
    func testTopicRename() {
        
        guard appVersionSupportsTopics else { return }
        
        //We should be on the main menu for a topic
        //Display the More (...) menu in the toolbar. Not sure why it is an image.
        XCUIApplication().navigationBars.firstMatch.images[AccessibilityIdentifiers.TopicTitleView.menuButton].tap()
        
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
