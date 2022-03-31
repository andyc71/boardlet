//
//  PECS_MakerUITests.swift
//  PECS MakerUITests
//
//  Created by Andy on 24/09/2021.
//

import XCTest
import MediaCore
import Photos

class PECS_MakerUITests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        //Ideally we would setup the user's photo album, but it's not
        //easy to do. Instead, we make sure that any live photos are
        //deleted, because there's a bug on the simular that means they
        //appear to be selected, but the selection doesn't actually work
#if targetEnvironment(simulator)
        deleteHDRPhotos()
#endif

        /*
        /Users/andy/Library/Developer/CoreSimulator/Devices/983F1EE6-FA7B-4568-B11D-5ADB805B0AC6/data/Containers/Bundle/Application/97B33868-0ED2-492E-952F-837921A17008/PECS MakerUITests-Runner.app/PlugIns/PECS MakerUITests.xctest
        */
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        
        app.launch()
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func deleteHDRPhotos() {

        let exp = expectation(description: "Photo deletion")

        
        Media.requestPermission { _ in
            if Media.currentPermission !=  PHAuthorizationStatus.authorized {
                XCTFail("Not authorized to access media library")
                return
            }
            
            var hdrCount = 0
            for photo in Media.Photos.all {
                if photo.subtypes.contains(where: {$0 == .hdr}) {
                    hdrCount += 1
                }
            }
        
       
            //let allPhotos = Media.Photos.hr.count
            let photos = Media.Photos.hdr
            if photos.count > 30 {
                XCTFail("Too many photos to delete")
                return
            }
        
        
            let photoCount = photos.count
            
            if photoCount == 0 {
                exp.fulfill()
            }
            
            var deleteCount = 0
            for i in (0..<photoCount).reversed() {
                let photo = photos[i]
                photo.delete(completion: {_ in
                    deleteCount += 1
                    if deleteCount == photoCount {
                        exp.fulfill()
                        print("\(deleteCount) photos deleted")
                    }
                })
            }
        }
        
        waitForExpectations(timeout: 10)

            

    }
    
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
    
    func selectPhotosFromMainMenu(count: Int) {
        app.buttons[AccessibilityIdentifiers.MainMenu.selectPhotoButton].tap()

        //Select the first count images
        let images = app.scrollViews.images
        //let count = images.count
        //let count = 8
        for i in 0..<count {
            let image = images.element(boundBy: i)
            if image.isSelected == false {
                image.tap()
            }
        }
        
        //Verify that we have 8 items by checking the text on the button... not ideal
        let selectedItemsButtonLabel = "Show Selected (\(count))"
        XCTAssertTrue(app.buttons[selectedItemsButtonLabel].exists)

        //Confirm selection and go back to main menu
        tapPhotoNavBarAddorDoneButton()

        //Go back into photos screen and verify that we still have 8 items
        app.buttons[AccessibilityIdentifiers.MainMenu.selectPhotoButton].tap()
        let selectedItemsButton = app.buttons[selectedItemsButtonLabel]
        XCTAssertTrue(selectedItemsButton.waitForExistence(timeout: 2))
        
        //Exit the photos screen (Add button is not called Done).
        tapPhotoNavBarAddorDoneButton()
        
    }
    
    func tapPhotoNavBarAddorDoneButton() {
        let addButton = app.navigationBars.firstMatch.buttons["Add"]
        if addButton.exists {
            addButton.tap()
        }
        else {
            app.navigationBars.firstMatch.buttons["Done"].tap()
        }

    }
    
    func selectLayout(pageSize: PageSize, orientation: PageOrientation, layout: PageLayout) {
        
        //Go to the layout selection screen.
        app.buttons[AccessibilityIdentifiers.MainMenu.selectLayoutButton].tap()

        let identfiers = AccessibilityIdentifiers.LayoutScreen.self

        app.buttons[identfiers.pageSizeButton(for: pageSize)].tap()
        app.buttons[identfiers.orientationButton(for: orientation)].tap()
        app.buttons[identfiers.layoutButton(for: layout)].tap()
        
        app.buttons[identfiers.doneButton].tap()
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
        
        //Photo paper plus portrait orientation = 2 layout options.
        app.buttons[identfiers.pageSizeButton(for: .photo10by15)].tap()
        app.buttons[identfiers.orientationButton(for: .portrait)].tap()
        XCTAssertEqual(2, getButtonCount(prefix: identfiers.layoutButtonPrefix))
        //Flip to landscape and make sure no change.
        app.buttons[identfiers.orientationButton(for: .landscape)].tap()
        XCTAssertEqual(2, getButtonCount(prefix: identfiers.layoutButtonPrefix))

        //Tap A4 paper and make sure we have 4+ layout options
        app.buttons[identfiers.pageSizeButton(for: .a4)].tap()
        app.buttons[identfiers.orientationButton(for: .portrait)].tap()
        XCTAssertGreaterThanOrEqual(4, getButtonCount(prefix: identfiers.layoutButtonPrefix))
        app.buttons[identfiers.orientationButton(for: .landscape)].tap()
        XCTAssertGreaterThanOrEqual(4, getButtonCount(prefix: identfiers.layoutButtonPrefix))

        //Tap US Letter paper and make sure we have 4+ layout options
        app.buttons[identfiers.pageSizeButton(for: .usLetter)].tap()
        app.buttons[identfiers.orientationButton(for: .portrait)].tap()
        XCTAssertGreaterThanOrEqual(4, getButtonCount(prefix: identfiers.layoutButtonPrefix))
        app.buttons[identfiers.orientationButton(for: .landscape)].tap()
        XCTAssertGreaterThanOrEqual(4, getButtonCount(prefix: identfiers.layoutButtonPrefix))
        
        app.navigationBars.firstMatch.buttons["Back"].tap()
        
    }
    
    func tapButtonAndItBecomesSelected(id: String) -> Bool {
        let button = app.buttons[id]
        button.tap()
        let isSelected = button.isSelected
        return isSelected
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
    
    func completeTitles(count: Int) {
        //Go to the Titles screen.
        app.buttons[AccessibilityIdentifiers.MainMenu.selectTitlesButton].tap()

        //Fill in the titles
        for i in 0..<count {
            let textBox = app.textFields[AccessibilityIdentifiers.TitlesScreen.titleText(for: i)]
            textBox.tap()
            textBox.typeText("Photo Item \(i)")
        }
                
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
    
    func getButtonCount(prefix: String) -> Int {
        var count = 0
        for i in 0..<app.buttons.count {
            let button = app.buttons.element(boundBy: i)
            if button.identifier.starts(with: prefix) {
                count += 1
            }
        }
        //print("****button count found \(count)")
        return count
    }
    
    func getLabelCount(prefix: String) -> Int {
        var count = 0
        for i in 0..<app.staticTexts.count {
            let button = app.staticTexts.element(boundBy: i)
            if button.identifier.starts(with: prefix) {
                count += 1
            }
        }
        //print("****button count found \(count)")
        return count
    }
    
    func getTextBoxCount(prefix: String) -> Int {
        var count = 0
        for i in 0..<app.textFields.count {
            let button = app.textFields.element(boundBy: i)
            if button.identifier.starts(with: prefix) {
                count += 1
            }
        }
        //print("****button count found \(count)")
        return count
    }

    
    func getImageCount(prefix: String) -> Int {
        var count = 0
        for i in 0..<app.images.count {
            let button = app.images.element(boundBy: i)
            if button.identifier.starts(with: prefix) {
                count += 1
            }
        }
        //print("****button count found \(count)")
        return count
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
        XCTAssertTrue(app.buttons[identifiers.formattingButton].exists)
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

    func completePreviewAndPrintBySaving() {

        //Go to the Preview screen.
        app.buttons[AccessibilityIdentifiers.MainMenu.previewAndPrintButton].tap()
        
        //Tap the Save button()
        app.buttons[AccessibilityIdentifiers.PreviewScreen.saveAndPrintButton].tap()
        
        
        //In the Activity Controller (share screen), tap the Save to Files button
        //which has the wierd label XCElementSnapshotPrivilegedValuePlaceholder
        app.buttons["XCElementSnapshotPrivilegedValuePlaceholder"].tap()
        
        
        //In the Files Controller, tap the save location for iPad.
        app/*@START_MENU_TOKEN@*/.tables.cells.containing(.image, identifier:"ipad")/*[[".otherElements[\"Target View\"].tables",".cells.containing(.staticText, identifier:\"On My iPad\")",".cells.containing(.image, identifier:\"ipad\")",".tables"],[[[-1,3,1],[-1,0,1]],[[-1,2],[-1,1]]],[0,0]]@END_MENU_TOKEN@*/.firstMatch.tap()
        //app/*@START_MENU_TOKEN@*/.tables.cells.containing(.image, identifier:"ipad")/*[[".otherElements[\"Target View\"].tables",".cells.containing(.staticText, identifier:\"On My iPad\")",".cells.containing(.image, identifier:\"ipad\")",".tables"],[[[-1,3,1],[-1,0,1]],[[-1,2],[-1,1]]],[0,0]]@END_MENU_TOKEN@*/.children(matching: .other).element(boundBy: 0).tap()
        
        //Tap save.
        app/*@START_MENU_TOKEN@*/.navigationBars["SaveToFiles.DOCServiceTargetSelectionBrowserView"]/*[[".otherElements[\"Target View\"].navigationBars[\"SaveToFiles.DOCServiceTargetSelectionBrowserView\"]",".navigationBars[\"SaveToFiles.DOCServiceTargetSelectionBrowserView\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.buttons["Save"].tap()
        
        //We might get an overwrite prompt
        let replaceAlert = app.alerts["Replace Existing Items?"]
        if replaceAlert.waitForExistence(timeout: 2) {
        //if replaceAlert.exists {
            replaceAlert.buttons["Replace"].tap()
        }
        //Dismiss the success notification.
//        let successAlert = app.alerts["Success"]
//        XCTAssertTrue(successAlert.waitForExistence(timeout: 2))
//        successAlert.buttons["OK"].tap()
        let successAlert = app.staticTexts[AccessibilityIdentifiers.PreviewScreen.doneAnimation]
        XCTAssertTrue(successAlert.waitForExistence(timeout: 2))
        
        //Dismiss the prompt to rate.
        let rateAlert = app.alerts["Please Rate Easy PECS"]
        XCTAssertTrue(rateAlert.waitForExistence(timeout: 2))
        rateAlert.buttons["No Thanks"].tap()
        
        //XCUIApplication().scrollViews.otherElements/*@START_MENU_TOKEN@*/.buttons["PreviewScreen.saveAndPrintButton"]/*[[".buttons[\"Save or Print\"]",".buttons[\"PreviewScreen.saveAndPrintButton\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
                        
        //print(XCUIApplication().debugDescription)

    }
    
    
    ///Check the preview screen has the option to repeat an image if
    ///there's only one.
    func testEndToEndWithOnePhoto() throws {
        
        let photoCount = 1
        
        //Photos: Select image
        selectPhotosFromMainMenu(count: photoCount)

        //Layout: Select A4 page size - any layout
        selectLayout(pageSize: .a4, orientation: .portrait, layout: PageLayout(width: 2, height: 3))
        
        //Titles: Add titles for all
        completeTitles(count: photoCount)
        
        //Preview and Print
        completePreviewAndPrintBySaving()
        
        
        //Store the printed image somewhere it can be accessed
        //and eye-balled later. Consider giving it a descriptive
        //name, or adding a page to describe the layout. Or add
        //a description to the PDF.
        

        //Repeat for other layouts.
        
        
        
        
        
        
    }

    ///Check the preview screen when it's got more than one image selected.
    func testPreviewScreenCompletedWithMultipleImages() throws {
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
