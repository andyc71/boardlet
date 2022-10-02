//
//  PECS_MakerUITests.swift
//  PECS MakerUITests
//
//  Created by Andy on 24/09/2021.
//

import XCTest

class PECS_MakerUITests: PECSTestsBase {
    
    func testMainMenu() {
        
        var menuButton = app.buttons[AccessibilityIdentifiers.MainMenu.selectPhotoButton]
        XCTAssert(menuButton.waitForExistence(timeout: 2))
        menuButton.tap()

        //Clear selections button should only exist if we have selected some photos
        checkClearButtonExists(false)

        //tapPhotoNavBarAddorDoneButton()
        tapPhotoNavBarCancelButton()
        
        menuButton = app.buttons[AccessibilityIdentifiers.MainMenu.selectLayoutButton]
        XCTAssert(menuButton.waitForExistence(timeout: 2))
        menuButton.tap()
        
        var backbutton = app.navigationBars.firstMatch.buttons[backButtonName]
        XCTAssert(backbutton.waitForExistence(timeout: 2))
        backbutton.tap()
        
        menuButton = app.buttons[AccessibilityIdentifiers.MainMenu.selectTitlesButton]
        XCTAssert(menuButton.waitForExistence(timeout: 2))
        menuButton.tap()

        backbutton = app.navigationBars.firstMatch.buttons[backButtonName]
        XCTAssert(backbutton.waitForExistence(timeout: 2))
        backbutton.tap()

        menuButton = app.buttons[AccessibilityIdentifiers.MainMenu.previewAndPrintButton]
        XCTAssert(menuButton.waitForExistence(timeout: 2))
        menuButton.tap()
        
        backbutton = app.navigationBars.firstMatch.buttons[backButtonName]
        XCTAssert(backbutton.waitForExistence(timeout: 2))
        backbutton.tap()

        
        
        //let app = XCUIApplication()
        //app.scrollViews.otherElements/*@START_MENU_TOKEN@*/.buttons["MainMenu.selectLayoutButton"]/*[[".buttons[\"Select Layout\"]",".buttons[\"MainMenu.selectLayoutButton\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        //app.navigationBars["Layout"].buttons["Back"].tap()
        
            
        
        
    }
        
    func testPhotoSelection() throws {

        let count = 8
        selectPhotosFromMainMenu(count: count)
    }
    
    ///Check the contents of the Layout screen
    func testLayoutScreenContents() throws {

        //Go to the layout selection screen.
        app.buttons[AccessibilityIdentifiers.MainMenu.selectLayoutButton].tap()
        
        let identfiers = AccessibilityIdentifiers.LayoutScreen.self

        //Check contents of the Page Size section
        XCTAssertTrue(app.staticTexts[identfiers.pageSizeHeading].exists)
        //Check a few paper sizes
        XCTAssertTrue(app.buttons[identfiers.pageSizeButton(for: .a4)].exists)
        XCTAssertTrue(app.buttons[identfiers.pageSizeButton(for: .usLetter)].exists)
        XCTAssertTrue(app.buttons[identfiers.pageSizeButton(for: .photo10by15)].exists)

        //Check the contents of the Orientation section
        XCTAssertTrue(app.staticTexts[identfiers.orientationHeading].exists)
        //Check for portrait and landscape
        XCTAssertTrue(app.buttons[identfiers.orientationButton(for: .portrait)].exists)
        XCTAssertTrue(app.buttons[identfiers.orientationButton(for: .landscape)].exists)

        
        //Check the contents of the Layout section
        XCTAssertTrue(app.staticTexts[identfiers.orientationHeading].exists)

        //MARK: Try some different combinations of paper size, orientation and layout
        
        //Photo paper plus portrait orientation = 26 layout options.
        app.buttons[identfiers.pageSizeButton(for: .photo10by15)].tap()
        app.buttons[identfiers.orientationButton(for: .portrait)].tap()
        XCTAssertEqual(10, getButtonCount(prefix: identfiers.layoutButtonPrefix))
        checkLayoutImageOrientation(.portrait)
        //Flip to landscape and make sure it reduces to 25.
        app.buttons[identfiers.orientationButton(for: .landscape)].tap()
        XCTAssertEqual(9, getButtonCount(prefix: identfiers.layoutButtonPrefix))
        checkLayoutImageOrientation(.landscape)

        //Tap A4 paper and make sure we have at least 30 layout options.
        //It's actually 36, but they will not all be on-screen
        app.buttons[identfiers.pageSizeButton(for: .a4)].tap()
        app.buttons[identfiers.orientationButton(for: .portrait)].tap()
        XCTAssertGreaterThanOrEqual(getButtonCount(prefix: identfiers.layoutButtonPrefix), 30)
        checkLayoutImageOrientation(.portrait)
        app.buttons[identfiers.orientationButton(for: .landscape)].tap()
        XCTAssertGreaterThanOrEqual(getButtonCount(prefix: identfiers.layoutButtonPrefix), 30)
        checkLayoutImageOrientation(.landscape)

        //Tap US Letter paper and make sure we have 30+ layout options
        app.buttons[identfiers.pageSizeButton(for: .usLetter)].tap()
        app.buttons[identfiers.orientationButton(for: .portrait)].tap()
        XCTAssertGreaterThanOrEqual(getButtonCount(prefix: identfiers.layoutButtonPrefix), 30)
        checkLayoutImageOrientation(.portrait)
        app.buttons[identfiers.orientationButton(for: .landscape)].tap()
        XCTAssertGreaterThanOrEqual(getButtonCount(prefix: identfiers.layoutButtonPrefix), 30)
        checkLayoutImageOrientation(.landscape)

        let backButton = app.navigationBars.firstMatch.buttons[backButtonName]
        XCTAssertTrue(backButton.waitForExistence(timeout: 2))
        backButton.tap()
        
    }
    
    ///Check that the layout screen correctly remembers the user's selections
    ///when you go in and out.
    func testLayoutScreenRemebersSelections() throws {

        //Go to the layout selection screen.
        app.buttons[AccessibilityIdentifiers.MainMenu.selectLayoutButton].tap()

        let identfiers = AccessibilityIdentifiers.LayoutScreen.self

        //Tap US Letter, Landscape, 2x3
        XCTAssertTrue(tapButtonAndItBecomesSelected(id: identfiers.pageSizeButton(for: .usLetter)))
        XCTAssertTrue(tapButtonAndItBecomesSelected(id: identfiers.orientationButton(for: .landscape)))
        XCTAssertTrue(tapButtonAndItBecomesSelected(id: identfiers.layoutButton(for: PageLayout(width: 2, height: 3))))

        //Tap Photo, Portrait, 1x1
        XCTAssertTrue(tapButtonAndItBecomesSelected(id: identfiers.pageSizeButton(for: .photo10by15)))
        XCTAssertTrue(tapButtonAndItBecomesSelected(id: identfiers.orientationButton(for: .portrait)))
        XCTAssertTrue(tapButtonAndItBecomesSelected(id: identfiers.layoutButton(for: PageLayout(width: 1, height: 1))))
        
        let backButton = app.navigationBars.firstMatch.buttons[backButtonName]
        XCTAssertTrue(backButton.waitForExistence(timeout: 2))
        backButton.tap()
        
        //Go to the layout selection screen. Make sure the selections are the same.
        app.buttons[AccessibilityIdentifiers.MainMenu.selectLayoutButton].tap()
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
        app.buttons[AccessibilityIdentifiers.MainMenu.selectTitlesButton].tap()
        
        //Check that the number of image/label rows is zero.
        XCTAssertEqual(0, getImageCount(prefix: AccessibilityIdentifiers.TitlesScreen.imagePrefix))
        XCTAssertEqual(0, getTextBoxCount(prefix: AccessibilityIdentifiers.TitlesScreen.titlePrefix))
        
        //Return to the main screen
        app.buttons[AccessibilityIdentifiers.TitlesScreen.doneButton].tap()
    }

    
    ///Check the contents of the Titles screen
    func testTitleScreenContents() throws {

        let photoCount = 5
        selectPhotosFromMainMenu(count: photoCount, recheckSelections: false)

        //Go to the Titles screen.
        app.buttons[AccessibilityIdentifiers.MainMenu.selectTitlesButton].tap()
        
        //Check that the number of image/label rows is the same as the photo count.
//        for i in 0..<photoCount {
//            let imageId = A12.TitlesScreen.image(for: i)
//            XCTAssert(app.button[imageId].exists, "Image with id \(imageId) does not exist")
//        }
        
        checkButtonCount(prefix: AccessibilityIdentifiers.TitlesScreen.imagePrefix, expectedCount: photoCount)
        XCTAssertEqual(photoCount, getTextBoxCount(prefix: AccessibilityIdentifiers.TitlesScreen.titlePrefix))
        
        //Return to the main screen
        app.buttons[AccessibilityIdentifiers.TitlesScreen.doneButton].tap()

    }
    

    ///Check the filling out of the title screen
    func testTitleScreenCompletion() throws {

        //Select some photos
        let photoCount = 5
        selectPhotosFromMainMenu(count: photoCount, recheckSelections: false)

        //Fill in the titles
        completeTitles(count: photoCount)
        
        //Go back in and check everything is still there.
        //Go to the layout selection screen.
        let titleButton = app.buttons[AccessibilityIdentifiers.MainMenu.selectTitlesButton]
        XCTAssertTrue(titleButton.waitForExistence(timeout: 2))
        titleButton.tap()

        for i in 0..<photoCount {
            let textBox = app.textFields[AccessibilityIdentifiers.TitlesScreen.titleText(for: i)]
            XCTAssertTrue(textBox.waitForExistence(timeout: 2))
            XCTAssertEqual("Photo Item \(i)", textBox.value as? String)
        }

        //Return to the main screen
        app.buttons[AccessibilityIdentifiers.TitlesScreen.doneButton].tap()

    }
    
    func deletePhotoUsingTitlesScreen(itemToDelete: Int, photoCount: Int) {
        
        //Go back in to titles screen.
        app.buttons[AccessibilityIdentifiers.MainMenu.selectTitlesButton].tap()

        //Press the delete button for the first item
        let deleteButton = app.buttons[AccessibilityIdentifiers.TitlesScreen.deleteButton(for: itemToDelete)]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2))
        deleteButton.tap()

        //Verify there is one less item
        for i in 0..<photoCount {
            let textBox = app.textFields[AccessibilityIdentifiers.TitlesScreen.titleText(for: i)]
            XCTAssertTrue(textBox.waitForExistence(timeout: 2))
        }
    
        //Verify that the last item is gone.
        let textBoxId = AccessibilityIdentifiers.TitlesScreen.titleText(for: photoCount)
        let textBox = app.textFields[textBoxId]
        XCTAssertFalse(textBox.exists, "Text box with id \(textBoxId) should not exist")

        //Return to the main screen
        app.buttons[AccessibilityIdentifiers.TitlesScreen.doneButton].tap()
    

    }
    
    func duplicatePhotoUsingTitlesScreen(itemToDuplicate: Int, photoCount: Int) {
        
        //Go back in to titles screen.
        app.buttons[AccessibilityIdentifiers.MainMenu.selectTitlesButton].tap()

        //Press the duplicate button for the first item
        let duplicateButton = app.buttons[AccessibilityIdentifiers.TitlesScreen.duplicateButton(for: itemToDuplicate)]
        XCTAssertTrue(duplicateButton.waitForExistence(timeout: 2))
        duplicateButton.tap()

        //Verify there is one more item
        for i in 0..<photoCount {
            let textBoxId = AccessibilityIdentifiers.TitlesScreen.titleText(for: i)
            let textBox = app.textFields[textBoxId]
            XCTAssertTrue(textBox.waitForExistence(timeout: 2), "Cannot find text box with id: \(textBoxId)")
        }
    
        //Return to the main screen
        app.buttons[AccessibilityIdentifiers.TitlesScreen.doneButton].tap()

    }
    
    ///Check deletion of a photo
    func testPhotoDeletion() throws {

        //Select some photos
        let photoCount = 3
        selectPhotosFromMainMenu(count: photoCount, recheckSelections: false)

        //Delete one of the photos and verify the new count.
        deletePhotoUsingTitlesScreen(itemToDelete: 0, photoCount: photoCount - 1)

        //Go into the photo screen and check one
        //photo has been remvoed there as well.
        checkPhotoCount(photoCount - 1)
        
    }
    
    
    ///Check deletion of a photo
    func testPhotoDuplication() throws {

        //Select some photos
        let originalPhotoCount = 3
        selectPhotosFromMainMenu(count: originalPhotoCount, recheckSelections: false)
        
        //Duplicate one of the photos and verify the new count.
        duplicatePhotoUsingTitlesScreen(itemToDuplicate: 0, photoCount: originalPhotoCount + 1)

        //The count on the OOTB photos screen should not have changed
        checkPhotoCount(originalPhotoCount)
        
        //Delete one of the photos and verify the new count.
        deletePhotoUsingTitlesScreen(itemToDelete: 0, photoCount: originalPhotoCount)
        
        //The count on the OOTB photos screen will still be the same because
        //we only deleted the duplicate
        checkPhotoCount(originalPhotoCount)

        //Delete another one of the photos and verify the new count.
        deletePhotoUsingTitlesScreen(itemToDelete: 0, photoCount: originalPhotoCount - 1)
        
        //The count on the OOTB photos screen will now have reduced.
        //we only deleted the duplicate
        checkPhotoCount(originalPhotoCount - 1)

        
    }
    
    
    ///Check the preview screen. Only checking the contents here, because we
    ///test the completion as part of the various end-to-end tests.
    func testPreviewScreenContents() throws {
        
        //Go to the Preview screen.
        app.buttons[AccessibilityIdentifiers.MainMenu.previewAndPrintButton].tap()

        let identifiers = AccessibilityIdentifiers.PreviewScreen.self

        //We haven't selected any images, so we should just have one blank
        //page for the preview.
        let previewImagePageCount = 1
        let previewImagesFound = getImageCount(prefix: identifiers.previewImagePrefix)
        XCTAssertEqual(previewImagePageCount, previewImagesFound)

        //As there aren't any images selected, we can't repeat the first image.
        XCTAssertFalse(app.switches[identifiers.repeatImageButton].exists)
        
        //Check the rest of the buttons.
        //XCTAssertTrue(app.buttons[identifiers.formattingButton].exists)
        XCTAssertTrue(app.buttons[identifiers.saveAndPrintButton].exists)
        XCTAssertTrue(app.buttons[identifiers.doneButton].exists)

        //Return to the main screen
        app.buttons[identifiers.doneButton].tap()
        
        //Select one image, Go back to the Preview screen and
        //make sure the repeat image button is there.
        selectPhotosFromMainMenu(count: 1)
        app.buttons[AccessibilityIdentifiers.MainMenu.previewAndPrintButton].tap()
        XCTAssertTrue(app.switches[identifiers.repeatImageButton].exists)
        app.buttons[identifiers.doneButton].tap()

        //Select 2 images, Go back to the Preview screen and
        //make sure the repeat image button is gone.
        selectPhotosFromMainMenu(itemsToSelect: 1, firstItem: 1, expectedCount: 2)
        app.buttons[AccessibilityIdentifiers.MainMenu.previewAndPrintButton].tap()
        XCTAssertFalse(app.switches[identifiers.repeatImageButton].exists)
        app.buttons[identifiers.doneButton].tap()
        
        
        

    }
    
    /*
    ///Check the preview screen has a different sized preview image (iPad only)
    func testPreviewScreenRotation() throws {
        XCTFail("Not implemented")
    }*/

    ///Check the preview screen has the option to repeat an image if
    ///there's only one.
    func testEndToEndWithOnePhoto() throws {
        
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
