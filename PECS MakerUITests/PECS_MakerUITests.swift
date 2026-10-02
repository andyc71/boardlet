//
//  PECS_MakerUITests.swift
//  PECS MakerUITests
//
//  Created by Andy on 24/09/2021.
//

import XCTest

class PECS_MakerUITests: PECSTestsBase {

    @MainActor func testAACStandardAvailabilityIsPlusOnly() {
        let search = app.buttons["aacStandardSymbolSearchButton"]
        if easyPECSAppType == .plus {
            XCTAssertTrue(search.waitForExistence(timeout: 5))
            search.tap()
            XCTAssertTrue(app.textFields["aacStandardSearchField"].waitForExistence(timeout: 5))
            XCTAssertFalse(app.buttons["aacStandardAddButton"].isEnabled)
            app.buttons[isSpanish ? "Cancelar" : "Cancel"].tap()
        } else {
            XCTAssertFalse(search.exists)
        }
        createBoardWithSinglePhoto()
        XCTAssertTrue(navigateToPhotoSelectionScreen())
        app.buttons[AccessibilityIdentifiers.PhotoSelectionView.menuButton].tap()
        XCTAssertEqual(app.buttons["AAC Standard"].exists, easyPECSAppType == .plus)
        if easyPECSAppType == .plus {
            app.buttons["AAC Standard"].tap()
            XCTAssertTrue(app.textFields["aacStandardSearchField"].waitForExistence(timeout: 5))
            app.buttons[isSpanish ? "Cancelar" : "Cancel"].tap()
            checkPhotoCountUsingPhotoSelectionScreen(1)
        }
    }

    @MainActor func testAACStandardTopicPickerIsPlusOnly() {
        openTopicImageSelector()
        app.buttons[AccessibilityIdentifiers.TopicImageSelector.selectSymbolButton].tap()
        if easyPECSAppType == .plus {
            XCTAssertTrue(app.buttons["AAC Standard"].waitForExistence(timeout: 5))
            app.buttons["AAC Standard"].tap()
            XCTAssertTrue(app.textFields["aacStandardSearchField"].waitForExistence(timeout: 5))
        } else {
            XCTAssertFalse(app.buttons["AAC Standard"].exists)
            XCTAssertTrue(app.textFields["arasaacSearchField"].waitForExistence(timeout: 5))
        }
        app.buttons[isSpanish ? "Cancelar" : "Cancel"].tap()
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.TopicImageSelector.selectSymbolButton].exists)
    }

    @MainActor func testMainMenuSymbolSearchAvailability() {

        let symbolSearch = app.buttons[AccessibilityIdentifiers.MainMenu.symbolSearchButton]
        XCTAssertTrue(symbolSearch.waitForExistence(timeout: 5))
        let takePhoto = app.buttons["takeBoardPhoto"]
        if takePhoto.exists {
            XCTAssertLessThan(symbolSearch.frame.minY, takePhoto.frame.minY)
        }

        symbolSearch.tap()
        XCTAssertTrue(app.textFields["arasaacSearchField"].waitForExistence(timeout: 5))
        app.buttons[isSpanish ? "Cancelar" : "Cancel"].tap()

        createBoardWithSinglePhoto()
        XCTAssertFalse(symbolSearch.exists)
        XCTAssertFalse(takePhoto.exists)

        guard navigateToPhotoSelectionScreen() else { return }
        app.buttons[AccessibilityIdentifiers.PhotoSelectionView.menuButton].tap()
        XCTAssertTrue(app.buttons["ARASAAC"].waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertEqual(app.buttons["Dynavox"].exists, easyPECSAppType == .plus)
        app.buttons["ARASAAC"].tap()
        XCTAssertTrue(app.textFields["arasaacSearchField"].waitForExistence(timeout: 5))
        app.buttons[isSpanish ? "Cancelar" : "Cancel"].tap()
        checkPhotoCountUsingPhotoSelectionScreen(1)
    }

    func testTopicARASAACPickerAvailability() {
        openTopicImageSelector()
        app.buttons[AccessibilityIdentifiers.TopicImageSelector.selectSymbolButton].tap()
        if easyPECSAppType == .plus {
            XCTAssertTrue(app.buttons["Dynavox"].exists)
            app.buttons["ARASAAC"].tap()
        } else {
            XCTAssertFalse(app.buttons["Dynavox"].exists)
        }
        XCTAssertTrue(app.textFields["arasaacSearchField"].waitForExistence(timeout: 5))
        app.buttons[isSpanish ? "Cancelar" : "Cancel"].tap()
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.TopicImageSelector.selectSymbolButton].exists)
    }

    func testVoiceFeatureCanBeDisabledIndependently() {
        app.buttons[AccessibilityIdentifiers.TopicTitleView.choiceBoardButton].tap()
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.TopicTitleView.pecsMakerButton].waitForExistence(timeout: 5))
        app.terminate()
        app.launchEnvironment["PECS_FEATURE_VOICE"] = "0"
        app.launch()
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.MainMenu.symbolSearchButton].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.TopicTitleView.choiceBoardButton].exists)
    }

    func testARASAACFeatureCanBeDisabledIndependently() {
        app.terminate()
        app.launchEnvironment["PECS_FEATURE_ARASAAC"] = "0"
        app.launch()
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.TopicTitleView.choiceBoardButton].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.MainMenu.symbolSearchButton].exists)
        createBoardWithSinglePhoto()
        XCTAssertTrue(navigateToPhotoSelectionScreen())
        XCTAssertFalse(app.buttons[AccessibilityIdentifiers.MainMenu.symbolSearchButton].exists)
        app.buttons[AccessibilityIdentifiers.PhotoSelectionView.menuButton].tap()
        XCTAssertFalse(app.buttons["ARASAAC"].exists)
        XCTAssertEqual(app.buttons["Dynavox"].exists, easyPECSAppType == .plus)
        app.tap() // Dismiss the add-items menu.
        if !isSplitView { returnToMainMenu() }
        openTopicImageSelector()
        let selectSymbol = app.buttons[AccessibilityIdentifiers.TopicImageSelector.selectSymbolButton]
        XCTAssertEqual(selectSymbol.exists, easyPECSAppType == .plus)
        if easyPECSAppType == .plus {
            selectSymbol.tap()
            XCTAssertTrue(app.buttons["Dynavox"].exists)
            XCTAssertFalse(app.buttons["ARASAAC"].exists)
        }
    }

    private func createBoardWithSinglePhoto() {
        app.terminate()
        app.launchArguments.append(LaunchArguments.autoFillSingle)
        app.launch()
        navigateToTopicScreenFromMainMenu()
        createTopic()
        let photoCard = app.buttons[isSplitView
            ? AccessibilityIdentifiers.MainMenu.selectPhotoButton
            : AccessibilityIdentifiers.MainMenu.changeSelectionsButton]
        XCTAssertTrue(photoCard.waitForExistence(timeout: 5))
    }

    private func openTopicImageSelector() {
        app.descendants(matching: .any)[AccessibilityIdentifiers.TopicTitleView.menuButton].firstMatch.tap()
        app.buttons[AccessibilityIdentifiers.TopicTitleView.changeTopicImageButton].tap()
        XCTAssertTrue(app.buttons["editTopicPhoto"].waitForExistence(timeout: 5))
    }
    
    func testMainMenu() {
        
        //We should only have a topic title edit button in the standard version of the app.
        if appVersionSupportsTopics {
            if isSpanish {
                checkTopicTitleOnMainMenu(topicName: "Nuevo Tablero")
            }
            else {
                checkTopicTitleOnMainMenu(topicName: "New Board")
            }
            app.selectButton(AccessibilityIdentifiers.TopicTitleView.menuButton, assertType: .exists)
        }
        else {
            if isSpanish {
                checkTopicTitleOnMainMenu(topicName: "Tablero Fácil")
            }
            else {
                checkTopicTitleOnMainMenu(topicName: "Easy Choice Board")
            }
            app.selectButton(AccessibilityIdentifiers.TopicTitleView.menuButton, assertType: .doesNotExist)
        }
        
        //Go through each button and:
        //1. Tap it
        //2. Check we land on the right screen
        //3. If in iPad (split view), make sure the button is now selected.
        //4. Return to the Main Menu (non-iPad split view)
        typealias ids = AccessibilityIdentifiers.MainMenu
        let mainMenuButtonsIdentifiers = [
            ids.selectPhotoButton,
            ids.selectLayoutButton,
            ids.selectTitlesButton,
            ids.previewAndPrintButton
        ]

        for id in mainMenuButtonsIdentifiers {
            guard let button = app.selectButton(id) else { return }
            app.tapButton(id: id, canForce: XCUIDevice.shared.iosVersion == 15.5)
            
            if isSplitView {
                
                if id != ids.selectPhotoButton {
                    //Check that the button we just tapped is selected, and all the
                    //other buttons are unselected.
                    //We don't do this if the user taps Select Photos because that
                    //shows as a popup and covers the menu buttons.
                    
                    for id2 in mainMenuButtonsIdentifiers {
                        if id2 == id {
                            XCTAssertTrue(button.isSelected, "Expected button with id \(id2) to be selected")
                        }
                        else {
                            guard let button2 = app.selectButton(id2) else { return }
                            XCTAssertFalse(button2.isSelected, "Expected button with id \(id2) to be unselected because \(id) is selected")
                        }
                    }
                }
            }
            
            //Check that the correct view is now visible.
            guard let expectedScreen = mapMainMenuButtonToScreen(id) else { return }
            guard mainMenuScreenIsVisible(expectedScreen) else { return }
            
            //Go back to the main menu (not needed on split view).
            if appScreenIsVisible(.photoPicker, assertType: .noAssert) {
                tapPhotoNavBarCancelButton()
            }
            else if !isSplitView {
                returnToMainMenu()
            }
        }
        
        //Clear selections button should only exist if we have selected some photos
        //We no longer have a Change Selections button
        //checkChangeSelectionButtonExistence(false)
                                
    }

    func testToolbarUtilitiesAndPreviewOrder() {
        typealias ids = AccessibilityIdentifiers.MainMenu

        let previewButton = app.buttons[ids.previewAndPrintButton]
        XCTAssertTrue(previewButton.waitForExistence(timeout: 5))
        XCTAssertLessThan(app.buttons[ids.selectTitlesButton].frame.maxY, previewButton.frame.minY)

        let toolbarMenu = app.buttons[AccessibilityIdentifiers.TopicTitleView.menuButton]
        XCTAssertTrue(toolbarMenu.waitForExistence(timeout: 5))
        toolbarMenu.tap()
        XCTAssertFalse(app.buttons[ids.changeVoiceButton].exists)
        let settingsButton = app.buttons[ids.settingsButton]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons[ids.moreAppsButton].exists)

        settingsButton.tap()
        XCTAssertTrue(mainMenuScreenIsVisible(.settings))
    }

    func testChoiceBoardVoicePicker() {
        typealias ids = AccessibilityIdentifiers.MainMenu

        let useBoardButton = app.buttons[AccessibilityIdentifiers.TopicTitleView.choiceBoardButton]
        XCTAssertTrue(useBoardButton.waitForExistence(timeout: 5))
        useBoardButton.tap()

        let menuButton = app.buttons[AccessibilityIdentifiers.ChoiceBoard.menuButton]
        let designBoardButton = app.buttons[AccessibilityIdentifiers.TopicTitleView.pecsMakerButton]
        XCTAssertTrue(menuButton.waitForExistence(timeout: 5))
        XCTAssertTrue(designBoardButton.exists)
        XCTAssertLessThan(menuButton.frame.maxX, designBoardButton.frame.minX)
        menuButton.tap()

        let changeVoiceButton = app.buttons[ids.changeVoiceButton]
        XCTAssertTrue(changeVoiceButton.waitForExistence(timeout: 5))
        changeVoiceButton.tap()
        XCTAssertTrue(app.navigationBars[isSpanish ? "Cambiar voz" : "Change Voice"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons[ids.voiceLanguagePicker].exists)
        XCTAssertTrue(app.buttons[ids.defaultVoiceButton].exists)
        app.buttons[ids.defaultVoiceButton].tap()
        XCTAssertTrue(app.buttons[ids.defaultVoiceButton].isSelected)
        let defaultPreview = app.buttons[ids.defaultVoicePreviewButton]
        XCTAssertTrue(defaultPreview.exists)
        defaultPreview.tap()
        XCTAssertTrue(app.buttons[ids.defaultVoiceButton].isSelected)
        if app.staticTexts[ids.voiceQualityNotice].exists {
            app.buttons[isSpanish ? "Obtener más voces" : "Get More Voices"].tap()
            XCTAssertTrue(app.staticTexts[ids.moreVoicesHelpTitle].waitForExistence(timeout: 5))
            XCTAssertTrue(app.staticTexts[ids.moreVoicesHelpPath].exists)
            let helpScreenshot = XCTAttachment(screenshot: app.screenshot())
            helpScreenshot.name = "More Voices Help"
            helpScreenshot.lifetime = .keepAlways
            add(helpScreenshot)
            app.buttons[ids.moreVoicesHelpDoneButton].tap()
        }
        let availableVoice = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "VoicePicker.voice.")).firstMatch
        XCTAssertTrue(availableVoice.waitForExistence(timeout: 5))
        let chosenVoiceIdentifier = availableVoice.identifier
        let chosenVoicePreview = app.buttons[chosenVoiceIdentifier.replacingOccurrences(of: "VoicePicker.voice.", with: "VoicePicker.preview.")]
        XCTAssertTrue(chosenVoicePreview.exists)
        chosenVoicePreview.tap()
        XCTAssertTrue(app.buttons[ids.defaultVoiceButton].isSelected)
        availableVoice.tap()
        XCTAssertTrue(app.buttons[chosenVoiceIdentifier].isSelected)
        app.buttons[isSpanish ? "Listo" : "Done"].tap()

        menuButton.tap()
        changeVoiceButton.tap()
        XCTAssertTrue(app.buttons[chosenVoiceIdentifier].isSelected)
        app.buttons[isSpanish ? "Listo" : "Done"].tap()
    }


    
    func mapMainMenuButtonToScreen(_ mainMenuButtonID: String) -> MainMenuScreen? {
        typealias ids = AccessibilityIdentifiers.MainMenu
        
        if mainMenuButtonID == ids.selectPhotoButton {
            return isSplitView ? .changeSelections : .selectPhotos
        }
        else if mainMenuButtonID == ids.selectLayoutButton {
            return .layout
        }
        else if mainMenuButtonID == ids.selectTitlesButton {
            return .titles
        }
        else if mainMenuButtonID == ids.previewAndPrintButton {
            return .preview
        }
        else {
            XCTFail("Could not map main menu button with id \(mainMenuButtonID) to a screen")
            return nil
        }
    }
        
    @MainActor func testPhotoSelection() throws {

        let count = 8
        selectPhotosFromMainMenu(count: count, recheckSelections: true)
    }
    
    ///Check the contents of the Layout screen
    func testLayoutScreenContents() throws {

        //Go to the layout selection screen.
        app.tapButton(id:AccessibilityIdentifiers.MainMenu.selectLayoutButton)
        
        let identfiers = AccessibilityIdentifiers.LayoutScreen.self

        //Check contents of the Page Size section
        XCTAssertTrue(app.staticTexts[identfiers.pageSizeHeading].exists)
        //Check a few paper sizes
        XCTAssertTrue(app.buttons[identfiers.pageSizeButton(for: .a4)].exists)
        XCTAssertTrue(app.buttons[identfiers.pageSizeButton(for: .a5)].exists)
        XCTAssertTrue(app.buttons[identfiers.pageSizeButton(for: .usLetter)].exists)
        XCTAssertTrue(app.buttons[identfiers.pageSizeButton(for: .quarto)].exists)
        XCTAssertTrue(app.buttons[identfiers.pageSizeButton(for: .photo10by15)].exists)

        //Check the contents of the Orientation section
        XCTAssertTrue(app.staticTexts[identfiers.orientationHeading].exists)
        //Check for portrait and landscape
        XCTAssertTrue(app.buttons[identfiers.orientationButton(for: .portrait)].exists)
        XCTAssertTrue(app.buttons[identfiers.orientationButton(for: .landscape)].exists)

        
        //Check the contents of the Layout section
        XCTAssertTrue(app.staticTexts[identfiers.orientationHeading].exists)

        //MARK: Try some different combinations of paper size, orientation and layout
        
        /*
        if XCUIDevice.deviceName.starts(with: "iPhone 8") {
            XCTExpectFailure("Layout counts will be off on smaller devices until we find a way to scroll down.")
        }
        */
        
        //Photo paper plus portrait orientation = 26 layout options.
        app.tapButton(id: identfiers.pageSizeButton(for: .photo10by15))
        app.tapButton(id: identfiers.orientationButton(for: .portrait))
        //It should be around 26, but some of them will disappear off the screen.
        checkLayoutOptions(minimumCount: 20, orientation: .portrait)
        //Flip to landscape and make sure it reduces to 25.
        app.tapButton(id: identfiers.orientationButton(for: .landscape))
        checkLayoutOptions(minimumCount: 20, orientation: .landscape)

        //Tap A4 paper and make sure we have at least 30 layout options.
        //It's actually 36, but they will not all be on-screen
        app.tapButton(id: identfiers.pageSizeButton(for: .a4))
        app.tapButton(id: identfiers.orientationButton(for: .portrait))
        checkLayoutOptions(minimumCount: 30, orientation: .portrait)
        app.tapButton(id: identfiers.orientationButton(for: .landscape))
        checkLayoutOptions(minimumCount: 30, orientation: .landscape)

        //Tap US Letter paper and make sure we have 30+ layout options
        app.tapButton(id: identfiers.pageSizeButton(for: .usLetter))
        app.tapButton(id: identfiers.orientationButton(for: .portrait))
        checkLayoutOptions(minimumCount: 30, orientation: .portrait)
        app.tapButton(id: identfiers.orientationButton(for: .landscape))
        checkLayoutOptions(minimumCount: 30, orientation: .landscape)

        returnToMainMenu()
        
    }
    
    ///Check that the layout screen correctly remembers the user's selections
    ///when you go in and out.
    func testLayoutScreenRemebersSelections() throws {

        //Go to the layout selection screen.
        app.tapButton(id: AccessibilityIdentifiers.MainMenu.selectLayoutButton)

        let identfiers = AccessibilityIdentifiers.LayoutScreen.self

        //Tap US Letter, Landscape, 2x3
        XCTAssertTrue(tapButtonAndItBecomesSelected(id: identfiers.pageSizeButton(for: .usLetter)))
        XCTAssertTrue(tapButtonAndItBecomesSelected(id: identfiers.orientationButton(for: .landscape)))
        XCTAssertTrue(tapButtonAndItBecomesSelected(id: identfiers.layoutButton(for: PageLayout(width: 2, height: 3))))

        //Tap Photo, Portrait, 1x1
        XCTAssertTrue(tapButtonAndItBecomesSelected(id: identfiers.pageSizeButton(for: .photo10by15)))
        XCTAssertTrue(tapButtonAndItBecomesSelected(id: identfiers.orientationButton(for: .portrait)))
        XCTAssertTrue(tapButtonAndItBecomesSelected(id: identfiers.layoutButton(for: PageLayout(width: 1, height: 1))))
        
        
//        let backButton = app.navigationBars.firstMatch.buttons[backButtonName]
//        app.navigationBars.firstMatch.buttons.firstMatch
//        XCTAssertTrue(backButton.waitForExistence(timeout: 2))
//        backButton.tap()
        //tapBackButton()
        
        if isSplitView {
            //Go to any other screen
            app.tapButton(id: AccessibilityIdentifiers.MainMenu.previewAndPrintButton)
        }
        else {
            returnToMainMenu()
        }

        //Go to the layout selection screen. Make sure the selections are the same.
        app.tapButton(id: AccessibilityIdentifiers.MainMenu.selectLayoutButton)
        XCTAssertTrue(app.buttons[identfiers.pageSizeButton(for: .photo10by15)].isSelected)
        XCTAssertFalse(app.buttons[identfiers.pageSizeButton(for: .a4)].isSelected)
        XCTAssertFalse(app.buttons[identfiers.pageSizeButton(for: .usLetter)].isSelected)
        XCTAssertTrue(app.buttons[identfiers.orientationButton(for: .portrait)].isSelected)
        XCTAssertFalse(app.buttons[identfiers.orientationButton(for: .landscape)].isSelected)
        XCTAssertTrue(app.buttons[identfiers.layoutButton(for: PageLayout(width: 1, height: 1))].isSelected)
        
    }
    
    ///Check the contents of the Titles screen
    func testTitleScreenContentsWhenEmpty() throws {

        //Go to the Titles screen.
        app.tapButton(id: AccessibilityIdentifiers.MainMenu.selectTitlesButton)
        
        //Check that we have a tip view and an add photos button
        checkNoPhotosTipExistence(true)
        
        //Check that the number of image/label rows is zero.
        XCTAssertEqual(0, getImageCount(prefix: AccessibilityIdentifiers.TitlesScreen.imagePrefix))
        XCTAssertEqual(0, getTextBoxCount(prefix: AccessibilityIdentifiers.TitlesScreen.titlePrefix))
        
        //Return to the main screen
        //app.buttons[AccessibilityIdentifiers.TitlesScreen.doneButton].tap()
        
    }
    
    func checkNoPhotosTipExistence(_ exists: Bool) {
        app.selectStaticText(AccessibilityIdentifiers.NoPhotosView.tipView, assertType: exists ? .exists : .doesNotExist)
        app.selectButton(AccessibilityIdentifiers.NoPhotosView.addPhotosButton, assertType: exists ? .exists : .doesNotExist)
    }

    
    ///Check the contents of the Titles screen
    func testTitleScreenContents() throws {

        navigateToTitlesScreen()
                        
        //Check that we have a tip view and an add photos button
        checkNoPhotosTipExistence(true)

        //Display the photo picker.
        app.tapButton(id: AccessibilityIdentifiers.NoPhotosView.addPhotosButton)
        
        let photoCount = 5
        //selectPhotosFromMainMenu(count: photoCount, recheckSelections: false)
        selectPhotosFromPicker(itemsToSelect: photoCount)
        
        //Check that we don't have a tip view or an add photos button
        checkNoPhotosTipExistence(false)

        checkButtonCount(prefix: AccessibilityIdentifiers.TitlesScreen.imagePrefix, expectedCount: photoCount)
        XCTAssertEqual(photoCount, getTextBoxCount(prefix: AccessibilityIdentifiers.TitlesScreen.titlePrefix))
        
        //Return to the main screen
        //tapBackButton()
        //app.buttons[AccessibilityIdentifiers.TitlesScreen.doneButton].tap()
        returnToMainMenu()

    }
    

    ///Check the filling out of the title screen
    @MainActor func testTitleScreenCompletion() throws {

        //Select some photos
        let photoCount = 5
        selectPhotosFromMainMenu(count: photoCount, recheckSelections: false)

        //Fill in the titles
        completeTitles(count: photoCount)
        
        //Go to any other screen and then return to the titles screen to
        //check everything is still there.
        returnToMainMenu()
        app.tapButton(id: AccessibilityIdentifiers.MainMenu.changeSelectionsButton)
        returnToMainMenu()
        app.tapButton(id: AccessibilityIdentifiers.MainMenu.selectTitlesButton)

        for i in 0..<photoCount {
            let textBox = app.textFields[AccessibilityIdentifiers.TitlesScreen.titleText(for: i)]
            XCTAssertTrue(textBox.waitForExistence(timeout: 2))
            XCTAssertEqual("Photo Item \(i)", textBox.value as? String)
        }

        //Return to the main screen
        //app.buttons[AccessibilityIdentifiers.TitlesScreen.doneButton].tap()
        //tapBackButton()
        returnToMainMenu()

    }
    
    ///Check the preview screen. Only checking the contents here, because we
    ///test the completion as part of the various end-to-end tests.
    @MainActor func testPreviewScreenContents() throws {
        
        //Go to the Preview screen.
        app.tapButton(id: AccessibilityIdentifiers.MainMenu.previewAndPrintButton)

        let identifiers = AccessibilityIdentifiers.PreviewScreen.self

        //We haven't selected any images, so we should just have one blank
        //page for the preview.
        let previewImagePageCount = 1
        let previewImages = app.images.matching(NSPredicate(format: "identifier BEGINSWITH %@", identifiers.previewImagePrefix))
        let rendered = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            previewImages.count == previewImagePageCount
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [rendered], timeout: 10), .completed,
                       "The asynchronously generated preview must render one page")

        //As there aren't any images selected, we can't repeat the first image.
        XCTAssertFalse(app.switches[identifiers.repeatImageButton].exists)
        
        //Check the rest of the buttons.
        XCTAssertTrue(app.buttons[identifiers.formattingButton].exists)
        XCTAssertTrue(app.buttons[identifiers.saveAndPrintButton].exists)
        //XCTAssertTrue(app.buttons[identifiers.doneButton].exists)
        
        //Return to the main screen
        //tapBackButton()
        returnToMainMenu()
        
        //Select one image, Go back to the Preview screen and
        //make sure the repeat image button is there.
        selectPhotosFromMainMenu(count: 1)
        
        app.tapButton(id: AccessibilityIdentifiers.MainMenu.previewAndPrintButton)
        XCTAssertTrue(app.switches[identifiers.repeatImageButton].exists)
        //tapBackButton()
        returnToMainMenu()

        //Select 2 images, Go back to the Preview screen and
        //make sure the repeat image button is gone.
        selectPhotos(startScreen: .mainMenu, itemsToSelect: 1, firstItem: 1, expectedCount: 2)
        
        returnToMainMenu()
        
        app.tapButton(id: AccessibilityIdentifiers.MainMenu.previewAndPrintButton)
        XCTAssertFalse(app.switches[identifiers.repeatImageButton].exists)
        //tapBackButton()
        returnToMainMenu()
    }
    
    
    ///Check the formatting screen. Only checking the contents here, because we
    ///test the completion as part of the various end-to-end tests.
    func testFormattingScreenContents() throws {
        
        //Go to the Preview screen.
        app.tapButton(id: AccessibilityIdentifiers.MainMenu.previewAndPrintButton)

        //Go to the formatting screen.
        app.tapButton(id: AccessibilityIdentifiers.PreviewScreen.formattingButton)

        //Check the rest of the buttons.
        let identifiers = AccessibilityIdentifiers.FormattingView.self
        
        //Titles section
        XCTAssertTrue(app.staticTexts[identifiers.CardSection.title].exists)
        if XCUIDevice.shared.iosVersion >= 16.0 {
            let colorWell = app.colorWells[identifiers.CardSection.Font.color]
            let colorButton = app.buttons[identifiers.CardSection.Font.color]
            XCTAssertTrue(
                colorWell.waitForExistence(timeout: 2) || colorButton.waitForExistence(timeout: 2),
                "Font colour control does not exist"
            )
        }
        else {
            XCTAssertTrue(app.otherElements[identifiers.CardSection.Font.color].exists)
        }
        XCTAssertTrue(app.switches[identifiers.CardSection.Font.bold].exists)

        if XCUIDevice.shared.iosVersion < 15.0 {
            //Workaround for a bug in IOS14 that causes all of the accessibility identifiers not
            //to work on a Segmented Picker control so we have to use hard-coded labels.
            //https://stackoverflow.com/questions/60894793/segmented-picker-removes-accessibility
            XCTAssertTrue(app.scrollViews.otherElements/*@START_MENU_TOKEN@*/.segmentedControls.buttons["Top"]/*[[".segmentedControls.buttons[\"Top\"]",".buttons[\"Top\"]"],[[[-1,1],[-1,0]]],[1]]@END_MENU_TOKEN@*/.waitForExistence(timeout: 2))
            XCTAssertTrue(app.scrollViews.otherElements.segmentedControls.buttons["Bottom"].waitForExistence(timeout: 2))
        }
        else {
            app.selectButton(identifiers.CardSection.TextPosition.top)
            app.selectButton(identifiers.CardSection.TextPosition.bottom)
        }
        XCTAssertTrue(app.sliders[identifiers.CardSection.Font.Size.slider].exists)

        //Margins section
        XCTAssertTrue(app.staticTexts[identifiers.Margins.sectionTitle].exists)
        XCTAssertTrue(app.sliders[identifiers.Margins.sizeSlider].exists)

        //Gridlines section
        app.scrollFormatting(towardTop: false)
        XCTAssertTrue(app.staticTexts[identifiers.Gridlines.sectionTitle].exists)
        if XCUIDevice.shared.iosVersion >= 16.0 {
            let colorWell = app.colorWells[identifiers.Gridlines.colour]
            let colorButton = app.buttons[identifiers.Gridlines.colour]
            XCTAssertTrue(
                colorWell.waitForExistence(timeout: 2) || colorButton.waitForExistence(timeout: 2),
                "Gridline colour control does not exist"
            )
        }
        else {
            XCTAssertTrue(app.otherElements[identifiers.Gridlines.colour].exists)
        }
        XCTAssertTrue(app.switches[identifiers.Gridlines.thicker].exists)

        //Go back to the preview screen
        //tapBackButton()
        app.tapButton(id: AccessibilityIdentifiersSSUI.PopupHeader.closeButton)
        
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PreviewScreen.formattingButton].exists)

        //Return to the main screen
        //app.buttons[AccessibilityIdentifiers.PreviewScreen.doneButton].tap()
        //tapBackButton()
        returnToMainMenu()

    }
    
    /*
    ///Check the preview screen has a different sized preview image (iPad only)
    func testPreviewScreenRotation() throws {
        XCTFail("Not implemented")
    }*/

    ///Check the preview screen has the option to repeat an image if
    ///there's only one.
    @MainActor func testEndToEndWithOnePhoto() throws {
        let photoCount = 1
        
        Snapshot.snapshot(ScreenshotNames.homeScreen)
        
        //Photos: Select image
        selectPhotosFromMainMenu(count: photoCount, snapshotID: ScreenshotNames.photosScreen, recheckSelections: false)

        //Layout: Select A4 page size - any layout
        selectLayout(pageSize: .a4, orientation: .portrait, layout: PageLayout(width: 2, height: 3), snapshotID: ScreenshotNames.layoutScreen)
        
        //Titles: Add titles for all
        completeTitles(count: photoCount, snapshotID: ScreenshotNames.titlesScreen)
        
        //Preview and Print
        completePreviewAndPrintBySaving(snapshotID: ScreenshotNames.previewScreen)


        //Store the printed image somewhere it can be accessed
        //and eye-balled later. Consider giving it a descriptive
        //name, or adding a page to describe the layout. Or add
        //a description to the PDF.
        

        //Repeat for other layouts.
        
        
    }
    
    func testTopicTitleRenaming() {
        
        //Skip the test if we're running the stanard version of the app.
        if !appVersionSupportsTopics {
            return
        }
        
        //Tap the button to start editing the title
        app.tapButton(id: AccessibilityIdentifiers.TopicTitleView.menuButton)
        app.tapButton(id: AccessibilityIdentifiers.TopicTitleView.renameButton)
        
        /* Old style editing with in-place text field
        
        //Clear any text from the edit field
        let titleEditField = app.textFields[AccessibilityIdentifiers.PageLayoutTitleView.titleField]
        XCTAssert(titleEditField.waitForExistence(timeout: 2))
        guard let existingText = titleEditField.value as? String else {
            XCTFail("Could not get text from title field")
            return
        }
        
        let clearButton = app.buttons[AccessibilityIdentifiers.PageLayoutTitleView.clearButton]
        XCTAssert(clearButton.waitForExistence(timeout: 2))
        clearButton.tap()
        
        guard let clearedText = titleEditField.value as? String else {
            XCTFail("Could not get text from title field")
            return
        }
        XCTAssertNotEqual(existingText, clearedText)
        

        //Tap on the field and type a new title
        tapElementAndWaitForKeyboardToAppear(element: titleEditField)
        let title = "Topic number \(Int.random(in: 1...10000))"
        titleEditField.typeText(title)
        titleEditField.typeText("\n")
        
        //Press confirm
        let titleConfirmButton = app.buttons[AccessibilityIdentifiers.PageLayoutTitleView.confirmButton]
        XCTAssert(titleConfirmButton.waitForExistence(timeout: 2))
        titleConfirmButton.tap()
         */
        
        //New style editing with rename item popup
        let title = completeEditPopupWithRandomText(prefix: "Board number ")
        
        //Go off to a random other screen and come back
        app.tapButton(id: AccessibilityIdentifiers.MainMenu.selectLayoutButton)

//        let backbutton = app.navigationBars.firstMatch.buttons[backButtonName]
//        XCTAssert(backbutton.waitForExistence(timeout: 2))
//        backbutton.tap()
        returnToMainMenu()
        
        //Re-get the title field, noting that it is now a label, not an edit field
        //let titleLabel = app.staticTexts[AccessibilityIdentifiers.TopicTitleView.titleField]
        //XCTAssert(titleLabel.waitForExistence(timeout: 2))
        let titleLabel = app.navigationBars.staticTexts[title]
        XCTAssert(titleLabel.waitForExistence(timeout: 2))
        
        XCTAssertEqual(title, titleLabel.label)


        
    }

    /*
    ///Check the preview screen when it's got more than one image selected.
    func testPreviewScreenCompletedWithMultiplePhotos() throws {
        XCTFail("Not implemented")
    }

    ///Check the preview screen when it's got enough images to spill
    ///onto multiple pages.
    func testPreviewScreenCompletedWithMultiplePages() throws {
        XCTFail("Not implemented")
    }

*/
    
    

    
    
//    func testLaunchPerformance() throws {
//        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
//            // This measures how long it takes to launch your application.
//            measure(metrics: [XCTApplicationLaunchMetric()]) {
//                XCUIApplication().launch()
//            }
//        }
//    }


    
}

/// These journeys intentionally cross the real out-of-process Photos picker.
@MainActor
final class SystemPickerIntegrationTests: PECSTestsBase {
    func testMatrixOrientation() {
        assertRequiredOrientation()
        SystemPhotoPickerDriver(app: app).captureEvidence(named: "Requested matrix orientation")
    }

    func testBoardCancelImportAppendCancelAndReopen() {
        let picker = SystemPhotoPickerDriver(app: app)
        XCTAssertTrue(navigateToPhotoPicker(from: .mainMenu))
        picker.assertOpen()
        picker.cancel()
        picker.assertDismissed()
        XCTAssertTrue(navigateToPhotoPicker(from: .mainMenu))
        selectPhotosFromPicker(itemsToSelect: 2)
        XCTAssertTrue(navigateToPhotoSelectionScreen())
        checkPhotoCountUsingPhotoSelectionScreen(2)
        XCTAssertTrue(navigateToPhotoPicker(from: .changeSelections))
        picker.assertOpen()
        picker.selectPhoto(matching: NSPredicate(format: "label CONTAINS %@ OR label CONTAINS %@", "February 03, 2020", "February 3, 2020"))
        picker.cancel()
        picker.assertDismissed()
        checkPhotoCountUsingPhotoSelectionScreen(2)
        XCTAssertTrue(navigateToPhotoPicker(from: .changeSelections))
        selectPhotosFromPicker(itemsToSelect: 1, firstItem: 2)
        checkPhotoCountUsingPhotoSelectionScreen(3)
        picker.captureEvidence(named: "Board imported and appended three photos")
    }

    func testEmptyBoardEntryPointCancel() {
        selectPhotosFromMainMenu(count: 1)
        XCTAssertTrue(navigateToPhotoSelectionScreen())
        app.buttons[A12SSUI.PhotoCell.image(for: 0)].press(forDuration: 1)
        app.tapButton(id: AccessibilityIdentifiers.PhotoContextMenu.deleteButton)
        respondYesToAlert()
        checkPhotoCountUsingPhotoSelectionScreen(0)
        XCTAssertTrue(navigateToPhotoPicker(from: .changeSelections))
        let picker = SystemPhotoPickerDriver(app: app)
        picker.assertOpen()
        picker.cancel()
        picker.assertDismissed()
        checkPhotoCountUsingPhotoSelectionScreen(0)
    }

    func testTopicPhotoCancelSelectReplaceAndReopen() {
        app.descendants(matching: .any)[AccessibilityIdentifiers.TopicTitleView.menuButton].firstMatch.tap()
        app.buttons[AccessibilityIdentifiers.TopicTitleView.changeTopicImageButton].tap()
        let choose = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.addMorePhotosButton]
        XCTAssertTrue(choose.waitForExistence(timeout: 10))
        let picker = SystemPhotoPickerDriver(app: app)
        choose.tap()
        picker.assertOpen()
        picker.cancel()
        picker.assertDismissed()
        for day in [1, 2] {
            choose.tap()
            picker.assertOpen()
            picker.selectPhoto(matching: NSPredicate(format: "label CONTAINS %@ OR label CONTAINS %@", "January 0\(day), 2020", "January \(day), 2020"))
            picker.confirmSingleSelectionIfNeeded()
            picker.assertDismissed()
            XCTAssertTrue(choose.waitForExistence(timeout: 10))
            XCTAssertTrue(app.buttons["editTopicPhoto"].exists)
            let expectedSize = day == 1 ? CGSize(width: 120, height: 80) : CGSize(width: 80, height: 120)
            let saved = XCTNSPredicateExpectation(predicate: NSPredicate { [self] _, _ in
                guard let files = FileManager.default.enumerator(at: tempDir, includingPropertiesForKeys: nil) else { return false }
                return files.compactMap { $0 as? URL }.filter { $0.lastPathComponent == "TopicImage.png" }
                    .contains { UIImage(contentsOfFile: $0.path)?.size == expectedSize }
            }, object: nil)
            XCTAssertEqual(XCTWaiter.wait(for: [saved], timeout: 10), .completed, "The selected provider image must be persisted as the topic image")
            picker.captureEvidence(named: "Topic image imported \(day)")
        }
    }
}
