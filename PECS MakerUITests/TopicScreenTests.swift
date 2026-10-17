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

    func testModernBoardOpensFromTopicsInPortrait() {
        assertModernBoardOpensFromTopics()
    }

    func testModernStartupBoardReturnsToTopics() {
        guard appVersionSupportsTopics else { return }
        app.terminate()
        app.launch()

        let editor = app.buttons[AccessibilityIdentifiers.TopicTitleView.titleField]
        XCTAssertTrue(editor.waitForExistence(timeout: 10))
        XCTAssertTrue(editor.isHittable)
        let back = app.navigationBars.buttons[backButtonName]
        let board = app.buttons[AccessibilityIdentifiers.TopicSelectionView.topicButton(for: 0)]
        if back.exists {
            back.tap()
        } else if !board.isHittable {
            tapSidebarButton()
        }
        XCTAssertTrue(board.waitForExistence(timeout: 10), "Startup Back must reveal Topics")
        XCTAssertTrue(board.isHittable)
        board.tap()
        XCTAssertTrue(editor.waitForExistence(timeout: 10))
        XCTAssertTrue(editor.isHittable, "The selected board must reopen after returning to Topics")
    }

    func testModernBoardOpensFromTopicsInLandscape() {
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        assertModernBoardOpensFromTopics()
    }

    private func assertModernBoardOpensFromTopics() {
        guard appVersionSupportsTopics else { return }

        let board = app.buttons[AccessibilityIdentifiers.TopicSelectionView.topicButton(for: 0)]
        let boardEditor = app.buttons[AccessibilityIdentifiers.TopicTitleView.titleField]
        let back = app.navigationBars.buttons[backButtonName]
        XCTAssertTrue(boardEditor.waitForExistence(timeout: 10))
        let hasBack = back.exists
        if hasBack {
            back.tap()
        } else if !board.isHittable {
            tapSidebarButton()
        }
        XCTAssertTrue(board.waitForExistence(timeout: 10), app.debugDescription)
        if hasBack {
            XCTAssertFalse(boardEditor.isHittable, "The collapsed navigation must be showing Boards")
        } else {
            XCTAssertTrue(board.isHittable, "The split view must keep Boards visible")
        }

        board.tap()

        XCTAssertTrue(boardEditor.waitForExistence(timeout: 10),
                      "Tapping a board must reveal the new interface's board editor")
        XCTAssertTrue(boardEditor.isHittable)
        if hasBack {
            XCTAssertTrue(back.waitForExistence(timeout: 10), "The board editor needs a Back button")
            back.tap()
            XCTAssertTrue(board.waitForExistence(timeout: 10), "Back must reveal Boards")
            XCTAssertTrue(board.isHittable)
        } else if !board.isHittable {
            tapSidebarButton()
        }

        board.tap()
        XCTAssertTrue(boardEditor.waitForExistence(timeout: 10),
                      "Tapping the already selected board must reopen the editor")
        XCTAssertTrue(boardEditor.isHittable)
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
        navigateToTopicScreen()
        
        //Put the screen into selection mode, select the topic, then delete it
        //from the toolbar just as on the photo list screen.
        if XCUIDevice.shared.iosVersion >= 16 {
            app.tapButton(id: AccessibilityIdentifiers.TopicSelectionView.menuButton)
            app.tapButton(id: AccessibilityIdentifiers.TopicSelectionView.selectButton)
        }
        else {
            app.tapButton(id: "Select")
        }

        app.tapButton(id: AccessibilityIdentifiers.TopicSelectionView.topicButton(for: 0))
        app.tapButton(id: AccessibilityIdentifiers.TopicSelectionView.deleteSelectionButton)
        
        let deleteConfirmation = app.alerts.buttons[isSpanish ? "Eliminar" : "Delete"]
        XCTAssertTrue(deleteConfirmation.waitForExistence(timeout: 5))
        deleteConfirmation.tap()

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
        XCTAssertFalse(selectButton.exists)
        XCTAssertEqual(sidebarButtons.count, 1, app.debugDescription)
        XCTAssertLessThan(restoreButton.frame.maxX, moreButton.frame.minX)
        XCTAssertGreaterThan(moreButton.frame.midX, app.frame.midX)

        moreButton.tap()
        let renameButton = app.buttons[AccessibilityIdentifiers.TopicSelectionView.renameTopicButton]
        XCTAssertTrue(selectButton.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertFalse(renameButton.exists, app.debugDescription)
        selectButton.tap()
        app.tapButton(id: AccessibilityIdentifiers.TopicSelectionView.closeSelectionButton)

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

    func testTopicListMenuSelectsTopics() {
        guard appVersionSupportsTopics else { return }
        navigateToTopicScreen()

        app.tapButton(id: AccessibilityIdentifiers.TopicSelectionView.menuButton)
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.TopicSelectionView.renameTopicButton].exists)
        app.tapButton(id: AccessibilityIdentifiers.TopicSelectionView.selectButton)
        let doneButton = app.buttons[AccessibilityIdentifiers.TopicSelectionView.closeSelectionButton]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 5))
        XCTAssertEqual(doneButton.label, isSpanish ? "Listo" : "Done")
    }

    

    
}
