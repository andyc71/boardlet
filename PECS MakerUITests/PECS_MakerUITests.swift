//
//  PECS_MakerUITests.swift
//  PECS MakerUITests
//
//  Created by Andy on 24/09/2021.
//

import XCTest

class PECS_MakerUITests: PECSTestsBase {
    
    func testMainMenu() {
        
        //We should only have a topic title edit button in the standard version of the app.
        if easyPECSAppType == .standard {
            checkTopicTitleOnMainMenu(topicName: "Easy Choice Board")
            app.selectButton(AccessibilityIdentifiers.TopicTitleView.menuButton, assertType: .doesNotExist)
        }
        else {
            checkTopicTitleOnMainMenu(topicName: "New Topic")
            app.selectButton(AccessibilityIdentifiers.TopicTitleView.menuButton, assertType: .exists)
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
            ids.previewAndPrintButton,
            ids.settingsButton
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
    
    func mapMainMenuButtonToScreen(_ mainMenuButtonID: String) -> MainMenuScreen? {
        typealias ids = AccessibilityIdentifiers.MainMenu
        
        if mainMenuButtonID == ids.selectPhotoButton {
            return .selectPhotos
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
        else if mainMenuButtonID == ids.settingsButton {
            return .settings
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
        
        app.scrollDown()

        /*
        if XCUIDevice.deviceName.starts(with: "iPhone 8") {
            XCTExpectFailure("Layout counts will be off on smaller devices until we find a way to scroll down.")
        }
        */
        
        //Photo paper plus portrait orientation = 26 layout options.
        app.tapButton(id: identfiers.pageSizeButton(for: .photo10by15))
        app.tapButton(id: identfiers.orientationButton(for: .portrait))
        //It should be around 26, but some of them will disappear off the screen.
        XCTAssertGreaterThanOrEqual(getButtonCount(prefix: identfiers.layoutButtonPrefix), 20)
        checkLayoutImageOrientation(.portrait)
        //Flip to landscape and make sure it reduces to 25.
        app.tapButton(id: identfiers.orientationButton(for: .landscape))
        XCTAssertGreaterThanOrEqual(getButtonCount(prefix: identfiers.layoutButtonPrefix), 20)
        checkLayoutImageOrientation(.landscape)

        //Tap A4 paper and make sure we have at least 30 layout options.
        //It's actually 36, but they will not all be on-screen
        app.tapButton(id: identfiers.pageSizeButton(for: .a4))
        app.tapButton(id: identfiers.orientationButton(for: .portrait))
        XCTAssertGreaterThanOrEqual(getButtonCount(prefix: identfiers.layoutButtonPrefix), 30)
        checkLayoutImageOrientation(.portrait)
        app.tapButton(id: identfiers.orientationButton(for: .landscape))
        XCTAssertGreaterThanOrEqual(getButtonCount(prefix: identfiers.layoutButtonPrefix), 30)
        checkLayoutImageOrientation(.landscape)

        //Tap US Letter paper and make sure we have 30+ layout options
        app.tapButton(id: identfiers.pageSizeButton(for: .usLetter))
        app.tapButton(id: identfiers.orientationButton(for: .portrait))
        XCTAssertGreaterThanOrEqual(getButtonCount(prefix: identfiers.layoutButtonPrefix), 30)
        checkLayoutImageOrientation(.portrait)
        app.tapButton(id: identfiers.orientationButton(for: .landscape))
        XCTAssertGreaterThanOrEqual(getButtonCount(prefix: identfiers.layoutButtonPrefix), 30)
        checkLayoutImageOrientation(.landscape)

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
        let previewImagesFound = getImageCount(prefix: identifiers.previewImagePrefix)
        XCTAssertEqual(previewImagePageCount, previewImagesFound)

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
        XCTAssertTrue(app.staticTexts[identifiers.Titles.sectionTitle].exists)
        if XCUIDevice.shared.iosVersion >= 18.0 {
            XCTAssertTrue(app.colorWells[identifiers.Titles.textColor].exists)
        }
        else if XCUIDevice.shared.iosVersion >= 16.0 {
            XCTAssertTrue(app.buttons[identifiers.Titles.textColor].exists)
        }
        else {
            XCTAssertTrue(app.otherElements[identifiers.Titles.textColor].exists)
        }
        XCTAssertTrue(app.switches[identifiers.Titles.boldFontOption].exists)

        if XCUIDevice.shared.iosVersion < 15.0 {
            //Workaround for a bug in IOS14 that causes all of the accessibility identifiers not
            //to work on a Segmented Picker control so we have to use hard-coded labels.
            //https://stackoverflow.com/questions/60894793/segmented-picker-removes-accessibility
            XCTAssertTrue(app.scrollViews.otherElements/*@START_MENU_TOKEN@*/.segmentedControls.buttons["Top"]/*[[".segmentedControls.buttons[\"Top\"]",".buttons[\"Top\"]"],[[[-1,1],[-1,0]]],[1]]@END_MENU_TOKEN@*/.waitForExistence(timeout: 2))
            XCTAssertTrue(app.scrollViews.otherElements.segmentedControls.buttons["Bottom"].waitForExistence(timeout: 2))
        }
        else {
            app.selectButton(identifiers.Titles.TextPosition.top)
            app.selectButton(identifiers.Titles.TextPosition.bottom)
        }
        XCTAssertTrue(app.sliders[identifiers.Titles.sizeSlider].exists)

        //Margins section
        XCTAssertTrue(app.staticTexts[identifiers.Margins.sectionTitle].exists)
        XCTAssertTrue(app.sliders[identifiers.Margins.sizeSlider].exists)

        //Gridlines section
        XCTAssertTrue(app.staticTexts[identifiers.Gridlines.sectionTitle].exists)
        if XCUIDevice.shared.iosVersion >= 18.0 {
            XCTAssertTrue(app.colorWells[identifiers.Gridlines.colour].exists)
        }
        else if XCUIDevice.shared.iosVersion >= 16.0 {
            XCTAssertTrue(app.buttons[identifiers.Gridlines.colour].exists)
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
        if easyPECSAppType == .standard {
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
        let title = completeEditPopupWithRandomText(prefix: "Topic number ")
        
        //Go off to a random other screen and come back
        app.tapButton(id: AccessibilityIdentifiers.MainMenu.selectLayoutButton)

//        let backbutton = app.navigationBars.firstMatch.buttons[backButtonName]
//        XCTAssert(backbutton.waitForExistence(timeout: 2))
//        backbutton.tap()
        tapBackButton()
        
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
