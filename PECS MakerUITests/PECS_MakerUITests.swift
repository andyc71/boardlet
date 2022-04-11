//
//  PECS_MakerUITests.swift
//  PECS MakerUITests
//
//  Created by Andy on 24/09/2021.
//

import XCTest

class PECS_MakerUITests: PECSTestsBase {
    
    func testMainMenu() {
        
        app.buttons[AccessibilityIdentifiers.MainMenu.selectPhotoButton].tap()
        app.navigationBars.firstMatch.buttons["Cancel"].tap()
        
        app.buttons[AccessibilityIdentifiers.MainMenu.selectLayoutButton].tap()
        app.navigationBars.firstMatch.buttons["Back"].tap()
        
        app.buttons[AccessibilityIdentifiers.MainMenu.selectTitlesButton].tap()
        app.navigationBars.firstMatch.buttons["Back"].tap()
        
        app.buttons[AccessibilityIdentifiers.MainMenu.previewAndPrintButton].tap()
        app.navigationBars.firstMatch.buttons["Back"].tap()
    
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
        
        //Photo paper plus portrait orientation = 3 layout options.
        app.buttons[identfiers.pageSizeButton(for: .photo10by15)].tap()
        app.buttons[identfiers.orientationButton(for: .portrait)].tap()
        XCTAssertEqual(3, getButtonCount(prefix: identfiers.layoutButtonPrefix))
        checkLayoutImageOrientation(.portrait)
        //Flip to landscape and make sure no change.
        app.buttons[identfiers.orientationButton(for: .landscape)].tap()
        XCTAssertEqual(3, getButtonCount(prefix: identfiers.layoutButtonPrefix))
        checkLayoutImageOrientation(.landscape)

        //Tap A4 paper and make sure we have 4+ layout options
        app.buttons[identfiers.pageSizeButton(for: .a4)].tap()
        app.buttons[identfiers.orientationButton(for: .portrait)].tap()
        XCTAssertGreaterThanOrEqual(getButtonCount(prefix: identfiers.layoutButtonPrefix), 4)
        checkLayoutImageOrientation(.portrait)
        app.buttons[identfiers.orientationButton(for: .landscape)].tap()
        XCTAssertGreaterThanOrEqual(getButtonCount(prefix: identfiers.layoutButtonPrefix), 4)
        checkLayoutImageOrientation(.landscape)

        //Tap US Letter paper and make sure we have 4+ layout options
        app.buttons[identfiers.pageSizeButton(for: .usLetter)].tap()
        app.buttons[identfiers.orientationButton(for: .portrait)].tap()
        XCTAssertGreaterThanOrEqual(getButtonCount(prefix: identfiers.layoutButtonPrefix), 4)
        checkLayoutImageOrientation(.portrait)
        app.buttons[identfiers.orientationButton(for: .landscape)].tap()
        XCTAssertGreaterThanOrEqual(getButtonCount(prefix: identfiers.layoutButtonPrefix), 4)
        checkLayoutImageOrientation(.landscape)

        app.navigationBars.firstMatch.buttons["Back"].tap()
        
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
        
        app.navigationBars.firstMatch.buttons["Back"].tap()
        
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
        
        //Check that the number of image/label rows is the same as the photo count.
        XCTAssertEqual(0, getImageCount(prefix: AccessibilityIdentifiers.TitlesScreen.imagePrefix))
        XCTAssertEqual(0, getTextBoxCount(prefix: AccessibilityIdentifiers.TitlesScreen.titlePrefix))
        
        //Return to the main screen
        app.buttons[AccessibilityIdentifiers.TitlesScreen.doneButton].tap()
    }

    
    ///Check the contents of the Titles screen
    func testTitleScreenContents() throws {

        let photoCount = 5
        selectPhotosFromMainMenu(count: photoCount)

        //Go to the Titles screen.
        app.buttons[AccessibilityIdentifiers.MainMenu.selectTitlesButton].tap()
        
        //Check that the number of image/label rows is the same as the photo count.
        XCTAssertEqual(photoCount, getImageCount(prefix: AccessibilityIdentifiers.TitlesScreen.imagePrefix))
        XCTAssertEqual(photoCount, getTextBoxCount(prefix: AccessibilityIdentifiers.TitlesScreen.titlePrefix))
        
        //Return to the main screen
        app.buttons[AccessibilityIdentifiers.TitlesScreen.doneButton].tap()

    }
    

    ///Check the filling out of the title screen
    func testTitleScreenCompletion() throws {

        //Select some photos
        let photoCount = 5
        selectPhotosFromMainMenu(count: photoCount)

        //Fill in the titles
        completeTitles(count: photoCount)
        
        //Go back in and check everything is still there.
        //Go to the layout selection screen.
        app.buttons[AccessibilityIdentifiers.MainMenu.selectTitlesButton].tap()

        for i in 0..<photoCount {
            let textBox = app.textFields[AccessibilityIdentifiers.TitlesScreen.titleText(for: i)]
            XCTAssertEqual("Photo Item \(i)", textBox.value as? String)
        }

        //Return to the main screen
        app.buttons[AccessibilityIdentifiers.TitlesScreen.doneButton].tap()

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
        selectPhotosFromMainMenu(count: 2)
        app.buttons[AccessibilityIdentifiers.MainMenu.previewAndPrintButton].tap()
        XCTAssertFalse(app.switches[identifiers.repeatImageButton].exists)
        app.buttons[identifiers.doneButton].tap()

    }
    
    ///Check the preview screen has a different sized preview image (iPad only)
    func testPreviewScreenRotation() throws {
        XCTFail("Not implemented")
    }

    ///Check the preview screen has the option to repeat an image if
    ///there's only one.
    func testEndToEndWithOnePhoto() throws {
        
        let photoCount = 1
        
        Snapshot.snapshot(ScreenshotNames.homeScreen)
        
        //Photos: Select image
        selectPhotosFromMainMenu(count: photoCount, snapshotID: ScreenshotNames.photosScreen)

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

    ///Check the preview screen when it's got more than one image selected.
    func testPreviewScreenCompletedWithMultiplePhotos() throws {
        XCTFail("Not implemented")
    }

    ///Check the preview screen when it's got enough images to spill
    ///onto multiple pages.
    func testPreviewScreenCompletedWithMultiplePages() throws {
        XCTFail("Not implemented")
    }


    
    

    
    
//    func testLaunchPerformance() throws {
//        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
//            // This measures how long it takes to launch your application.
//            measure(metrics: [XCTApplicationLaunchMetric()]) {
//                XCUIApplication().launch()
//            }
//        }
//    }


    
}
