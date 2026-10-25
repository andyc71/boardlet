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
    
    func testEditingDestinationsCanBeReopenedAfterBack() {
        let destinations: [(String, MainMenuScreen)] = [
            (AccessibilityIdentifiers.MainMenu.selectTitlesButton, .titles),
            (AccessibilityIdentifiers.MainMenu.selectTitlesButton, .titles),
            (AccessibilityIdentifiers.MainMenu.selectLayoutButton, .layout),
            (AccessibilityIdentifiers.MainMenu.settingsButton, .settings),
            (AccessibilityIdentifiers.MainMenu.selectTitlesButton, .titles)
        ]
        for (button, screen) in destinations {
            if button == AccessibilityIdentifiers.MainMenu.settingsButton {
                app.tapButton(id: AccessibilityIdentifiers.TopicTitleView.menuButton)
            }
            app.tapButton(id: button)
            XCTAssertTrue(mainMenuScreenIsVisible(screen))
            let returnButton = button == AccessibilityIdentifiers.MainMenu.settingsButton
                ? AccessibilityIdentifiers.TopicTitleView.menuButton : button
            if !app.buttons[returnButton].isHittable {
                let compatibilityBack = app.buttons["BoardNavigation.backToMenu"]
                if compatibilityBack.exists {
                    compatibilityBack.tap()
                } else {
                    tapBackButton()
                }
                XCTAssertTrue(app.buttons[returnButton].isHittable)
            }
        }
    }

    func testRenameDraftAndPresentationSurviveRepeatedResizing() throws {
        try XCTSkipUnless(XCUIDevice.isiPad, "Uses iPad rotation to cross the former 1024-point boundary")
        defer { XCUIDevice.shared.orientation = requiredOrientation }
        let menu = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifiers.TopicTitleView.menuButton).firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 10))
        menu.tap()
        app.tapButton(id: AccessibilityIdentifiers.TopicTitleView.renameButton)
        // Keep the rename alert and its draft while the window changes size.
        let presentation = app.buttons[A12SSUI.Alert.saveButton].firstMatch
        XCTAssertTrue(presentation.waitForExistence(timeout: 5))
        let field = renameTextField
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText(" Resize draft")
        let draft = try XCTUnwrap(field.value as? String)
        for _ in 0..<3 {
            XCUIDevice.shared.orientation = .landscapeLeft
            XCTAssertGreaterThan(app.frame.width, 1024)
            XCTAssertTrue(presentation.exists)
            XCTAssertEqual(field.value as? String, draft)
            XCUIDevice.shared.orientation = .portrait
            XCTAssertLessThan(app.frame.width, 1024)
            XCTAssertTrue(presentation.exists)
            XCTAssertEqual(field.value as? String, draft)
        }
        app.buttons[A12SSUI.Alert.cancelButton].firstMatch.tap()
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
        
    func testTopicMaximizeButton() throws {
        try XCTSkipUnless(XCUIDevice.isiPad && appVersionSupportsTopics)
        defer { XCUIDevice.shared.orientation = requiredOrientation }
        XCUIDevice.shared.orientation = .landscapeLeft
        let maximize = app.buttons[AccessibilityIdentifiers.TopicSelectionView.maximizeButton]
        let grid = app.scrollViews["TopicSelectionView.grid"].firstMatch
        let board = app.buttons[AccessibilityIdentifiers.TopicSelectionView.topicButton(for: 0)].firstMatch
        for _ in 0..<2 {
            XCTAssertTrue(maximize.waitForExistence(timeout: 10))
            XCTAssertLessThan(grid.frame.width, app.frame.width * 0.5)
            maximize.tap()
            XCTAssertTrue(grid.waitForExistence(timeout: 5))
            XCTAssertGreaterThan(grid.frame.width, app.frame.width * 0.85,
                                 "The topics screen must fill the window, not leave empty split columns")
            XCTAssertFalse(maximize.isHittable)
            XCTAssertEqual(app.scrollViews.matching(identifier: "TopicSelectionView.grid")
                .allElementsBoundByIndex.filter { $0.isHittable }.count, 1,
                           "Only the maximized topics grid should be interactive")
            XCTAssertFalse(app.sheets.firstMatch.exists)
            let restore = app.buttons[AccessibilityIdentifiers.TopicSelectionView.restoreButton]
            XCTAssertTrue(restore.waitForExistence(timeout: 5))
            restore.tap()
            XCTAssertTrue(maximize.waitForExistence(timeout: 5))
            XCTAssertLessThan(grid.frame.width, app.frame.width * 0.5)
            XCTAssertTrue(app.buttons[AccessibilityIdentifiers.MainMenu.selectTitlesButton].exists)
            maximize.tap()
            XCTAssertTrue(restore.waitForExistence(timeout: 5))
            XCTAssertGreaterThan(grid.frame.width, app.frame.width * 0.85)
            XCTAssertTrue(board.exists)
            board.tap()
            XCTAssertTrue(maximize.waitForExistence(timeout: 5))
            XCTAssertTrue(app.buttons[AccessibilityIdentifiers.MainMenu.selectTitlesButton].exists)
            XCTAssertLessThan(grid.frame.width, app.frame.width * 0.5)
        }
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
