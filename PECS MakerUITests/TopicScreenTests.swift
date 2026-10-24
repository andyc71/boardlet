//
//  TopicScreenTests.swift
//  TopicScreenTests
//
//  Created by Andy on 21/12/2022.
//

import XCTest

///Tests the topic selection screen.
class TopicScreenTests: PECSTestsBase {
    func testInspireMeAsksForTitleThenOpensSuggestions() {
        navigateToTopicScreen()
        createTopic()
        openInspireMe()
        let title = app.textFields["BoardSuggestions.titleField"].firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        let confirm = app.buttons["BoardSuggestions.confirmTitle"].firstMatch
        XCTAssertFalse(confirm.isEnabled)
        title.tap()
        title.typeText("Fruit")
        XCTAssertTrue(confirm.isEnabled)
        confirm.tap()
        XCTAssertTrue(app.buttons["boardSuggestionsAdd"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["BoardSuggestions.yes"].exists)
    }

    func testInspireMeOpensDirectlyForNamedBoardAfterDecliningAutomaticOffer() {
        navigateToTopicScreen()
        createTopic()
        renameNewBoardForSuggestions()
        let no = app.buttons["BoardSuggestions.no"].firstMatch
        XCTAssertTrue(no.waitForExistence(timeout: 5))
        no.tap()
        openInspireMe()
        XCTAssertTrue(app.buttons["boardSuggestionsAdd"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.textFields["BoardSuggestions.titleField"].exists)
        XCTAssertFalse(app.buttons["BoardSuggestions.yes"].exists)
    }

    private func openInspireMe() {
        let menu = app.buttons[AccessibilityIdentifiers.TopicTitleView.menuButton].firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 5))
        menu.tap()
        let inspire = app.buttons["BoardSuggestions.inspireMe"].firstMatch
        XCTAssertTrue(inspire.waitForExistence(timeout: 5))
        inspire.tap()
    }

    func testNewBoardOffersSuggestionsAfterNaming() {
        navigateToTopicScreen()
        createTopic()
        renameNewBoardForSuggestions()
        let yes = app.buttons["BoardSuggestions.yes"].firstMatch
        XCTAssertTrue(yes.waitForExistence(timeout: 5))
        yes.tap()
        XCTAssertTrue(app.otherElements["boardSuggestionsList"].waitForExistence(timeout: 5)
                      || app.collectionViews["boardSuggestionsList"].exists
                      || app.tables["boardSuggestionsList"].exists, app.debugDescription)
        XCTAssertTrue(app.buttons["boardSuggestionsAdd"].exists)
    }

    func testDecliningSuggestionsDoesNotAskAgainWhenRenaming() {
        navigateToTopicScreen()
        createTopic()
        renameNewBoardForSuggestions()
        let no = app.buttons["BoardSuggestions.no"].firstMatch
        XCTAssertTrue(no.waitForExistence(timeout: 5))
        no.tap()
        let title = app.buttons[AccessibilityIdentifiers.TopicTitleView.titleField]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()
        let field = app.textFields[AccessibilityIdentifiers.PhotoZoomView.titleField]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(" more")
        app.buttons[AccessibilityIdentifiers.PhotoZoomView.saveButton].tap()
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["BoardSuggestions.yes"].exists)
    }

    private func renameNewBoardForSuggestions() {
        let title = app.buttons[AccessibilityIdentifiers.TopicTitleView.titleField]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()
        let field = app.textFields[AccessibilityIdentifiers.PhotoZoomView.titleField]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(" Fruit")
        app.buttons[AccessibilityIdentifiers.PhotoZoomView.saveButton].tap()
    }

    func testTopicLayoutSelectionPersists() {
        navigateToTopicScreen()
        let modes = app.segmentedControls["LayoutScreen.screenLayout"]
        func openLayout() {
            app.buttons[AccessibilityIdentifiers.TopicSelectionView.menuButton].tap()
            app.buttons["TopicSelectionView.layoutButton"].tap()
            XCTAssertTrue(modes.waitForExistence(timeout: 5))
        }
        openLayout()
        modes.buttons[isSpanish ? "Automático" : "Automatic"].tap()
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.LayoutScreen.seeAllButton].exists)
        XCTAssertFalse(app.descendants(matching: .any)["LayoutScreen.showTitles"].exists)
        XCTAssertFalse(app.staticTexts[AccessibilityIdentifiers.LayoutScreen.pageSizeHeading].exists)
        XCTAssertFalse(app.staticTexts[AccessibilityIdentifiers.LayoutScreen.orientationHeading].exists)
        modes.buttons[isSpanish ? "Predefinido" : "Pre-Defined"].tap()
        let choiceID = AccessibilityIdentifiers.LayoutScreen.layoutButton(for: PageLayout(width: 3, height: 4))
        let choice = app.buttons.matching(identifier: choiceID).firstMatch
        if !choice.exists || !choice.isHittable {
            app.buttons[AccessibilityIdentifiers.LayoutScreen.seeAllButton].tap()
            for _ in 0..<18 where !choice.exists || !choice.isHittable {
                app.scrollViews.firstMatch.swipeUp()
            }
        }
        XCTAssertTrue(choice.exists && choice.isHittable)
        choice.tap()
        XCTAssertTrue(choice.isSelected)
        app.buttons["TopicLayout.done"].tap()
        let card = app.buttons[AccessibilityIdentifiers.TopicSelectionView.topicButton(for: 0)]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        let portraitGrid = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let width = self.app.scrollViews["TopicSelectionView.gridScrollView"].frame.width
            return card.frame.width >= 64 - 1 && card.frame.width <= (width - 40 - 2 * 12) / 3 + 1
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [portraitGrid], timeout: 5), .completed)
        let initialSize = card.frame.size
        defer { XCUIDevice.shared.orientation = .portrait }
        for orientation in [UIDeviceOrientation.landscapeLeft, .portrait, .landscapeLeft, .portrait] {
            XCUIDevice.shared.orientation = orientation
            let rotated = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                (self.app.frame.width > self.app.frame.height) == orientation.isLandscape
            }, object: nil)
            XCTAssertEqual(XCTWaiter.wait(for: [rotated], timeout: 10), .completed)
            let sameSize = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                if orientation.isLandscape {
                    return card.frame.width < initialSize.width
                        && card.frame.height < initialSize.height
                        && card.frame.width >= 63 && card.frame.height >= 63
                }
                return abs(card.frame.width - initialSize.width) < 1
                    && abs(card.frame.height - initialSize.height) < 1
            }, object: nil)
            XCTAssertEqual(XCTWaiter.wait(for: [sameSize], timeout: 5), .completed,
                           "Fit down to the minimum in landscape and restore in portrait: \(initialSize), got \(card.frame.size)")
            if orientation == .portrait {
                let viewport = app.scrollViews["TopicSelectionView.gridScrollView"].frame
                XCTAssertGreaterThanOrEqual(card.frame.minX, viewport.minX)
                XCTAssertLessThanOrEqual(card.frame.minX + 3 * card.frame.width + 24, viewport.maxX)
            }
        }
        app.terminate()
        app.launch()
        navigateToTopicScreen()
        openLayout()
        XCTAssertTrue(app.buttons[choiceID].firstMatch.isSelected)
        modes.buttons[isSpanish ? "Automático" : "Automatic"].tap()
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.LayoutScreen.seeAllButton].exists)
        app.buttons["TopicLayout.done"].tap()
        let viewportWidth = app.scrollViews["TopicSelectionView.gridScrollView"].frame.width
        let adaptiveColumns = max(1, Int((viewportWidth - 40 + 12) / 112))
        let adaptiveWidth = (viewportWidth - 40 - CGFloat(adaptiveColumns - 1) * 12) / CGFloat(adaptiveColumns)
        XCTAssertEqual(card.frame.width, adaptiveWidth, accuracy: 1)
    }

    func testDragReordersTopicsAndPersistsAfterRelaunch() {
        navigateToTopicScreen()
        createTopic()
        navigateToTopicScreen()
        let first = app.buttons[AccessibilityIdentifiers.TopicSelectionView.topicButton(for: 0)]
        let second = app.buttons[AccessibilityIdentifiers.TopicSelectionView.topicButton(for: 1)]
        XCTAssertTrue(second.waitForExistence(timeout: 10))
        let firstName = first.label
        let secondName = second.label
        XCTAssertNotEqual(firstName, secondName)

        first.press(forDuration: 0.6, thenDragTo: second)
        let reordered = NSPredicate(format: "label == %@", secondName)
        expectation(for: reordered, evaluatedWith: first)
        waitForExpectations(timeout: 5)
        XCTAssertEqual(second.label, firstName)

        app.terminate()
        app.launch()
        navigateToTopicScreen()
        XCTAssertTrue(first.waitForExistence(timeout: 10))
        XCTAssertEqual(first.label, secondName)
        XCTAssertEqual(second.label, firstName)
    }

    
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
        
        let boardTitle = app.buttons[AccessibilityIdentifiers.TopicTitleView.titleField]
        XCTAssertTrue(boardTitle.waitForExistence(timeout: 5))
        boardTitle.tap()
        let field = app.textFields[AccessibilityIdentifiers.PhotoZoomView.titleField]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.clearText()
        let topicName = "Topic 99 \(UUID().uuidString)"
        field.typeText(topicName)
        app.tapButton(id: AccessibilityIdentifiers.PhotoZoomView.saveButton)
        let suggestions = app.buttons["BoardSuggestions.no"]
        if suggestions.waitForExistence(timeout: 2) { suggestions.tap() }
        XCTAssertTrue(boardTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(boardTitle.label.contains(topicName))

        returnToTopicScreen(from: .mainMenu)
        
        //Make sure we now have a topic with the new name
        app.selectButton(topicName)
        
    }

    func testDuplicateSelectedTopics() {
        navigateToTopicScreen()
        app.tapButton(id: AccessibilityIdentifiers.TopicSelectionView.menuButton)
        app.tapButton(id: AccessibilityIdentifiers.TopicSelectionView.selectButton)

        let duplicate = app.buttons[AccessibilityIdentifiers.TopicSelectionView.duplicateSelectionButton]
        let delete = app.buttons[AccessibilityIdentifiers.TopicSelectionView.deleteSelectionButton]
        XCTAssertTrue(duplicate.waitForExistence(timeout: 5))
        XCTAssertFalse(duplicate.isEnabled)
        XCTAssertFalse(delete.isEnabled)

        let selectAll = app.navigationBars.buttons[AccessibilityIdentifiers.TopicSelectionView.selectAllButton]
        XCTAssertTrue(selectAll.exists)
        selectAll.tap()
        XCTAssertTrue(duplicate.isEnabled)
        XCTAssertTrue(delete.isEnabled)
        duplicate.tap()
        let confirmation = app.alerts[isSpanish ? "Duplicar Tableros Seleccionados" : "Duplicate Selected Boards"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        XCTAssertTrue(confirmation.staticTexts[isSpanish ? "¿Duplicar el tablero seleccionado?" : "Duplicate the selected board?"].exists)
        confirmation.buttons[isSpanish ? "Cancelar" : "Cancel"].tap()
        checkTopicCount(1)

        func confirmDuplicateAndCheckResult(count: Int) {
            duplicate.tap()
            XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
            confirmation.buttons[isSpanish ? "Duplicar" : "Duplicate"].tap()
            let success = app.alerts[isSpanish ? "Tableros Duplicados" : "Boards Duplicated"]
            XCTAssertTrue(success.waitForExistence(timeout: 10))
            let message = isSpanish
                ? (count == 1 ? "Se ha duplicado 1 tablero." : "Se han duplicado \(count) tableros.")
                : (count == 1 ? "Duplicated 1 board." : "Duplicated \(count) boards.")
            XCTAssertTrue(success.staticTexts[message].exists)
            success.buttons[isSpanish ? "Cerrar" : "Close"].tap()
        }

        confirmDuplicateAndCheckResult(count: 1)
        checkTopicCount(2)

        selectAll.tap()
        confirmDuplicateAndCheckResult(count: 2)
        checkTopicCount(4)

        app.navigationBars.buttons[AccessibilityIdentifiers.TopicSelectionView.selectAllButton].tap()
        app.navigationBars.buttons[AccessibilityIdentifiers.TopicSelectionView.deselectAllButton].tap()
        XCTAssertFalse(duplicate.isEnabled)
        XCTAssertFalse(delete.isEnabled)
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
