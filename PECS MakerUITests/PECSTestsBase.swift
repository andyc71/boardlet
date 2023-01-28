//
//  DarkModeTests.swift
//  PECS MakerUITests
//
//  Created by Andy on 09/04/2022.
//

import XCTest
import MediaCore
import Photos


class PECSTestsBase: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCUIDevice.shared.orientation = .landscapeLeft
        }
        else {
            XCUIDevice.shared.orientation = .portrait
        }
        
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

        setLaunchArguments()

        if Snapshots.takeSnapshots {
            setupSnapshot(app)
        }
        app.launch()
    }
    
    func setLaunchArguments() {
        app.launchArguments = [LaunchArguments.keepPDFs, LaunchArguments.noAnalytics]
        
        //app.launchArguments += ["-AppleLocale", "es_ES"]
        //app.launchArguments += ["-AppleLanguages", "(es)"]
        
        if useDarkMode {
            app.launchArguments.append(LaunchArguments.darkMode)
        }
        else {
            app.launchArguments.append(LaunchArguments.lightMode)
        }

        print("Is Spanish? \(isSpanish)")
        
    }
    
    var useDarkMode: Bool {
        get { return false }
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
    
    var isSplitView: Bool {
        return XCUIDevice.shared.iosVersion >= 16.0 &&
        app.windows.firstMatch.frame.size.width > 1024
    }
    
    func returnToMainMenu() {
        if isSplitView {
            return //Main menu is already available alongside detail view.
        }
        tapBackButton()
    }

    func selectPhotosFromMainMenu(count: Int, snapshotID: String? = nil, recheckSelections: Bool = true) {
        selectPhotosFromMainMenu(itemsToSelect: count, firstItem: 0, expectedCount: count, snapshotID: snapshotID, recheckSelections: recheckSelections)
    }
    
    func checkClearButtonExists(_ exists: Bool) {
        let menuButton = app.buttons[AccessibilityIdentifiers.MainMenu.clearSelectionsButton]
        if exists {
            XCTAssertTrue(menuButton.waitForExistence(timeout: 2))
        }
        else {
            XCTAssertFalse(menuButton.exists)
        }
    }


    ///This function is overly complicated, but necessary because we have to cater for the situation
    ///where we want to select one item, return to the screen and then sleect another, but IOS gives
    ///us no way of knowing which items are already selected.
    ///It will often fail if there are too many photos and the top row has partially scrolled off screen. Fix
    ///is to remove some photos from the Photos app.
    func selectPhotosFromMainMenu(itemsToSelect: Int, firstItem: Int, expectedCount: Int, snapshotID: String? = nil, recheckSelections: Bool = true) {

        let selectPhotoButton = app.buttons[AccessibilityIdentifiers.MainMenu.selectPhotoButton]
        XCTAssertTrue(selectPhotoButton.waitForExistence(timeout: 2))
        selectPhotoButton.tap()
        

        //Select the first count images
        //let phot = app.otherElements["Photos"]
        //let photosContainer = app/*@START_MENU_TOKEN@*/.otherElements["Photos"].scrollViews/*[[".otherElements[\"Photos\"].scrollViews",".scrollViews"],[[[-1,1],[-1,0]]],[1]]@END_MENU_TOKEN@*/.otherElements.otherElements
        //XCTAssertTrue(photosContainer.element.waitForExistence(timeout: 2))
        //let images = app.scrollViews.images
        //let images = photosContainer.images
        //let images = app/*@START_MENU_TOKEN@*/.scrollViews/*[[".otherElements[\"Photos\"].scrollViews",".scrollViews"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.otherElements
        //XCTAssertTrue(images.firstMatch.waitForExistence(timeout: 2))
        //let images = photosContainer.children(matching: .image)
        //let count = images.count
        //let count = 8
        //print(app.debugDescription)
        
        //let query = NSPredicate(format: "label LIKE 'Photo*'")
        
        //let images = app.scrollViews.otherElements.images.matching(query)
        
        /* //Yummy Pets
        let elementID = "YPLibraryViewCell" //Yummy Pets
         let images = app.collectionViews.firstMatch.children(matching: .cell).matching(identifier: elementID)
        for i in firstItem..<firstItem + itemsToSelect {
            let image = images.element(boundBy: i)
            XCTAssertTrue(image.waitForExistence(timeout: 2))
            image.tap()
        }
         */
        
        //Make sure the first item is completely on-screen.
        let photoView = app.collectionViews.firstMatch
        XCTAssertTrue(photoView.waitForExistence(timeout: 2), "Photo collection view does not exist")
        photoView.swipeDown()
        
        //Now select the photos.
        let elementID = "zl btn unselected" //ZL
        for i in firstItem..<firstItem + itemsToSelect {
            let image = app.collectionViews.children(matching: .cell).element(boundBy: i).buttons[elementID]
            XCTAssertTrue(image.waitForExistence(timeout: 2))
            image.tap()
        }
        
        //EarlGrey.selectElement(with: grey_accessibilityID(elementID))
        //EarlGrey.selectElement(with: grey_accessibilityLabel(elementID))
            //.assert(grey_equalTo(expectedCount))

        
        snapshotIfNeeded(snapshotID)

        //Confirm selection and go back to main menu
        tapPhotoNavBarAddorDoneButton()
        
        checkClearButtonExists(expectedCount > 0)
        
//        let element = elementsQuery/*@START_MENU_TOKEN@*/.otherElements["collectionContainerView"].collectionViews.children(matching: .cell).matching(identifier: "YPLibraryViewCell").element(boundBy: 0)/*[[".otherElements[\"collectionContainerView\"].collectionViews",".children(matching: .cell).matching(identifier: \"Library Image\").element(boundBy: 0)",".children(matching: .cell).matching(identifier: \"YPLibraryViewCell\").element(boundBy: 0)",".collectionViews"],[[[-1,3,1],[-1,0,1]],[[-1,2],[-1,1]]],[1,0]]@END_MENU_TOKEN@*/.children(matching: .other).element
//        element.tap()
//        elementsQuery/*@START_MENU_TOKEN@*/.collectionViews.staticTexts["1"]/*[[".otherElements[\"collectionContainerView\"].collectionViews",".cells.matching(identifier: \"Library Image\").staticTexts[\"1\"]",".cells.matching(identifier: \"YPLibraryViewCell\").staticTexts[\"1\"]",".staticTexts[\"1\"]",".collectionViews"],[[[-1,4,1],[-1,0,1]],[[-1,3],[-1,2],[-1,1]]],[0,0]]@END_MENU_TOKEN@*/.tap()
//        element.tap()
        
        
        
        

        if recheckSelections {
            checkPhotoCount(expectedCount)
        }
    }
    
    var backButtonName: String {
        isSpanish ? "Atrás" : "Back"
    }
    
    func checkPhotoCount(_ count: Int) {
        //Go back into photos screen and verify that we still have 8 items
        let selectPhotoButton = app.buttons[AccessibilityIdentifiers.MainMenu.selectPhotoButton]
        XCTAssert(selectPhotoButton.waitForExistence(timeout: 2))
        selectPhotoButton.tap()
        
        /* // Yummy Pets
        //let selectedItemsButtonLabel = "Show Selected (\(count))"
        let selectedItemsButtonLabel = "\(count)"
        let selectedItemsButton = app.staticTexts[selectedItemsButtonLabel]
        XCTAssertTrue(selectedItemsButton.waitForExistence(timeout: 2))
        */
        
        //ZLPhotoBrowser
        let selectedItemsButtonLabel = isSpanish ? "Hecho(\(count))" : "Done(\(count))"
        let selectedItemsButton = app.buttons[selectedItemsButtonLabel]
        XCTAssertTrue(selectedItemsButton.waitForExistence(timeout: 2))

        
        //Exit the photos screen (Add button is not called Done).
        //tapPhotoNavBarAddorDoneButton()
        tapPhotoNavBarCancelButton()
        
    }
    
    var photoBrowserDoneButtonName : String {
        get {
            if isSpanish {
                return "OK"
            }
            else {
                return "Done"
            }
        }
    }

    var photoBrowserAddButtonName : String {
        get {
            if isSpanish {
                return "Add"
            }
            else {
                return "Add"
            }
        }
    }

    func tapPhotoNavBarAddorDoneButton() {
        /*
        let addButton = app.navigationBars.firstMatch.buttons[photoBrowserAddButtonName]
        if addButton.exists {
            addButton.tap()
        }
        else {
            //app.navigationBars.firstMatch.buttons[photoBrowserDoneButtonName].tap()
        }
         */
        
        //Yummy pets
        //app.navigationBars["YPImagePicker.YPPickerVC"].buttons["Next"].tap()
        
        //ZLPhotoBrowser
        let query = isSpanish ? NSPredicate(format: "label LIKE 'Hecho(*'") :
            NSPredicate(format: "label LIKE 'Done(*'")
        let buttons = app.buttons.matching(query)
        let button = buttons.firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 2))
        button.tap()

    }
    
    func tapPhotoNavBarCancelButton() {
        
        //ZLPhotoBrowser
        let buttonID = isSpanish ? "Cancelar" : "Cancel"
        //let button = app.buttons["zl navClose"] //This ID is when using an image
        let button = app.buttons[buttonID]
        XCTAssertTrue(button.waitForExistence(timeout: 2))
        button.tap()

    }
    
    func selectLayout(pageSize: PageSize, orientation: PageOrientation, layout: PageLayout, snapshotID: String? = nil) {

        let selectLayoutButton = app.buttons[AccessibilityIdentifiers.MainMenu.selectLayoutButton]
        XCTAssertTrue(selectLayoutButton.waitForExistence(timeout: 2))
        selectLayoutButton.tap()

        let identfiers = AccessibilityIdentifiers.LayoutScreen.self

        app.buttons[identfiers.pageSizeButton(for: pageSize)].tap()
        app.buttons[identfiers.orientationButton(for: orientation)].tap()
        app.buttons[identfiers.layoutButton(for: layout)].tap()
        
        snapshotIfNeeded(snapshotID)
        
        returnToMainMenu()
    }
    
    func checkLayoutImageOrientation(_ orientation: PageOrientation) {
        let identfiers = AccessibilityIdentifiers.LayoutScreen.self
        let buttons = getButtonsWithPrefix(identfiers.layoutButtonPrefix)
        for button in buttons {
            if orientation == .portrait {
                XCTAssertLessThan(button.frame.size.width, button.frame.size.height)
            }
            else {
                XCTAssertGreaterThan(button.frame.size.width, button.frame.size.height)
            }
        }
    }
    
    func getButtonsWithPrefix(_ prefix: String) -> [XCUIElement] {
        var buttons = [XCUIElement]()
        for i in 0..<app.buttons.count {
            let button = app.buttons.element(boundBy: i)
            if button.identifier.starts(with: prefix) {
                buttons.append(button)
            }
        }
        return buttons
    }
    
    func tapButtonAndItBecomesSelected(id: String) -> Bool {
        let button = app.buttons[id]
        XCTAssert(button.waitForExistence(timeout: 2))
        button.tap()
        let isSelected = button.isSelected
        return isSelected
    }
    
    func completeTitles(count: Int, snapshotID: String? = nil, isAutoFilled: Bool = false) {
        //Go to the Titles screen.
        let button = app.buttons[AccessibilityIdentifiers.MainMenu.selectTitlesButton]
        XCTAssertTrue(button.waitForExistence(timeout: 2))
        button.tap()

        //Fill in the titles. Even if they are autofilled we need to tab
        //through them to ensure the Done button eventually scrolls onto screen
        for i in 0..<count {
            let textBox = app.textFields[AccessibilityIdentifiers.TitlesScreen.titleText(for: i)]
            XCTAssertTrue(textBox.waitForExistence(timeout: 2))
            tapElementAndWaitForKeyboardToAppear(element: textBox)
            if !isAutoFilled {
                textBox.typeText("Photo Item \(i)")
                //Dismiss the keyboard
                textBox.typeText("\n")
            }
        }
        
        snapshotIfNeeded(snapshotID)
                
        //Return to the main screen
        returnToMainMenu()
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
    
    func checkButtonCount(prefix: String, expectedCount: Int) {
        for i in 0..<expectedCount {
            let buttonName = "\(prefix)\(i)"
            let button = app.buttons[buttonName]
            XCTAssertTrue(button.exists, "Button with ID \(buttonName) does not exist")
        }

        let buttonName = "\(prefix)\(expectedCount)"
        let button = app.buttons[buttonName]
        XCTAssertFalse(button.exists)

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
    
    var isSpanish: Bool {
        get {
            //XCUIApplication().launchArguments += [“-AppleLanguages”, “(fr)”]
            //XCUIApplication().launchArguments += [“-AppleLocale”, “fr_FR”]
            
            //Will return the Device language:
//            guard let locale = NSLocale.current.languageCode else {
//                return false
//            }
            
            //Bundle.main.preferredLocalizations[0]
            //Will return the App language:
            let preferredLanguage = Locale.preferredLanguages[0]
            //let preferredLang = String(preferredLanguage.suffix(2).uppercased())
            
            if preferredLanguage == "es" || locale.uppercased().prefix(2) == "ES" {
                NSLog("****Device Lang: \(locale) Preferred Lang: \(preferredLanguage) - Spanish")
                return true
            }
            else {
                NSLog("****Device Lang: \(locale) Preferred Lang: \(preferredLanguage) - English")
                return false
            }
            //print("*****\(pre)")

        }
        
    }
    
    var actionSheetPrintButtonName: String {
        if isSpanish {
            return "Imprimir"
        }
        else {
            return "Print"
        }
    }

    var actionSheetSaveButtonName: String {
        if isSpanish {
            return "Guardar en Archivos"
        }
        else {
            return "Save to Files"
        }
    }

    var fileBrowserSaveButtonName: String {
        if isSpanish {
            return "Guardar"
        }
        else {
            return "Save"
        }
    }

    var fileBrowserCancelButtonName: String {
        if isSpanish {
            return "Cancelar"
        }
        else {
            return "Cancel"
        }
    }

    var fileBrowserReplaceButtonName: String {
        if isSpanish {
            return "Reemplazar"
        }
        else {
            return "Replace"
        }
    }
    

    var fileBrowserReplaceAlertTitle: String {
        if isSpanish {
            return "¿Reemplazar los elementos existentes?"
        }
        else {
            return "Replace Existing Items?"
        }
    }
    
    
    func completePreviewAndPrintBySaving(repeatSingleImage: Bool = false, snapshotID: String? = nil) {
        
        //Go to the Preview screen.
        app.tapButton(id: AccessibilityIdentifiers.MainMenu.previewAndPrintButton)
        
        app.tapButton(id: AccessibilityIdentifiers.PreviewScreen.formattingButton)
        
        /*
         //Not necessary because we have a specific test for this.
         let identifiers = AccessibilityIdentifiers.FormattingView.self
         
         //Titles section
         XCTAssertTrue(app.staticTexts[identifiers.Titles.sectionTitle].exists)
         XCTAssertTrue(app.otherElements[identifiers.Titles.textColor].exists)
         XCTAssertTrue(app.switches[identifiers.Titles.boldFontOption].exists)
         XCTAssertTrue(app.buttons[identifiers.Titles.TextPosition.top].exists)
         XCTAssertTrue(app.buttons[identifiers.Titles.TextPosition.bottom].exists)
         XCTAssertTrue(app.sliders[identifiers.Titles.sizeSlider].exists)
         
         //Margins section
         XCTAssertTrue(app.staticTexts[identifiers.Margins.sectionTitle].exists)
         XCTAssertTrue(app.sliders[identifiers.Margins.sizeSlider].exists)
         
         //Gridlines section
         XCTAssertTrue(app.staticTexts[identifiers.Gridlines.sectionTitle].exists)
         XCTAssertTrue(app.otherElements[identifiers.Gridlines.colour].exists)
         XCTAssertTrue(app.switches[identifiers.Gridlines.thicker].exists)
         */
        
        
        //Go back to the preview screen
        //tapBackButton()
        app.tapButton(id: AccessibilityIdentifiersSSUI.PopupHeader.closeButton)
        
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PreviewScreen.formattingButton].exists)
        
        if repeatSingleImage {
            let repeatButton = app.switches[AccessibilityIdentifiers.PreviewScreen.repeatImageButton]
            XCTAssertTrue(repeatButton.waitForExistence(timeout: 2))
            repeatButton.tap()
        }
        
        snapshotIfNeeded(snapshotID)
        
        //Tap the Save button()
        app.tapButton(id: AccessibilityIdentifiers.PreviewScreen.saveAndPrintButton)
        
        
        //In the Activity Controller (share screen), tap the Save to Files button
        //which has the wierd label XCElementSnapshotPrivilegedValuePlaceholder
        //Activity inspector says this is called "Activity" even though it says "Save to Files"
        
        //let saveToFilesButton = app.otherElements["ActivityListView"].cells.containing(.other, identifier: "Save").firstMatch
        let saveToFilesButton: XCUIElement!
        if XCUIDevice.shared.iosVersion < 15.0 {
            saveToFilesButton =  app.buttons["Save to Files"]
        }
        else {
            saveToFilesButton = app/*@START_MENU_TOKEN@*/.collectionViews/*[[".otherElements[\"ActivityListView\"].collectionViews",".collectionViews"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.buttons["XCElementSnapshotPrivilegedValuePlaceholder"].children(matching: .other).element(boundBy: 1).children(matching: .other).element(boundBy: 2)
        }
        
        //let saveToFilesButton = app.buttons["Activity Button"]
        XCTAssert(saveToFilesButton.waitForExistence(timeout: 2))
        saveToFilesButton.tap()
        
        if XCUIDevice.isiPad {
            //In the Files Controller, tap the save location.
            let iPadButton = isSpanish ? app.cells["En mi iPad"] : app.cells["On My iPad"]
            let iPadButton2 = isSpanish ? app.staticTexts["DOC.sidebar.item.En Mi iPad"] :
            app.staticTexts["DOC.sidebar.item.On My iPad"]
            //iPad Air 5th Gen (IOS 15.5)
            let iPadButton3 = isSpanish ? app.staticTexts["En Mi iPad"] :
            app.staticTexts["On My iPad"]
            
            if iPadButton.waitForExistence(timeout: 2) {
                iPadButton.tap()
            }
            else if iPadButton2.waitForExistence(timeout: 2) {
                iPadButton2.tap()
            }
            else if iPadButton3.waitForExistence(timeout: 2) {
                iPadButton3.tap()
            }
            else {
                XCTFail("Unable to find My iPad save location")            }
        }
        else {
            //En mi iPhone
            let iPhoneButton = isSpanish ? app.staticTexts["En mi iPhone"] : app.staticTexts["On My iPhone"]
            if iPhoneButton.waitForExistence(timeout: 2) {
                iPhoneButton.tap()
            }
            else {
                XCTFail("Unable to find My iPhone as a file save location")
            }
        }
        
        //Tap save.
        //app/*@START_MENU_TOKEN@*/.navigationBars["SaveToFiles.DOCServiceTargetSelectionBrowserView"]/*[[".otherElements[\"Target View\"].navigationBars[\"SaveToFiles.DOCServiceTargetSelectionBrowserView\"]",".navigationBars[\"SaveToFiles.DOCServiceTargetSelectionBrowserView\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*///.buttons[fileBrowserSaveButtonName].tap()
        app.tapButton(id: fileBrowserSaveButtonName)
        
        /*
         //We might get an overwrite prompt....
         //Would be nice to check for the alert dialog title first, but we seem to
         //have two different versions floating around in Spanish:
         //¿Reemplazar ítems existentes? and ¿Reemplazar los elementos existentes?
         let replaceAlert = app.alerts[fileBrowserReplaceAlertTitle]
         if replaceAlert.waitForExistence(timeout: 2) {
         replaceAlert.buttons[fileBrowserReplaceButtonName].tap()
         }
         else {
         let replaceAlert = app.alerts["¿Reemplazar ítems existentes?"]
         replaceAlert.waitForExistence(timeout: 2)
         }
         */
        //Tap the replace button, if it exists.
        let replaceButton = app.buttons[fileBrowserReplaceButtonName]
        if replaceButton.waitForExistence(timeout: 2) {
            replaceButton.tap()
        }
        
        //Dismiss the success notification.
        //        let successAlert = app.alerts["Success"]
        //        XCTAssertTrue(successAlert.waitForExistence(timeout: 2))
        //        successAlert.buttons["OK"].tap()
        
        let successAlert = app.images[AccessibilityIdentifiersSSUI.Animations.doneAnimation]
        XCTAssertTrue(successAlert.waitForExistence(timeout: 2))
        
        //Dismiss the prompt to rate.
        //dismissRatingAlert()
        
    }
    
    func snapshotIfNeeded(_ snapshotID: String?) {
        if let snapshotID = snapshotID {
            Snapshot.snapshot(snapshotID)
        }
    }
    
    func tapSidebarButton() {
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }
    
    func tapBackButton() {
        let button = app.navigationBars.buttons.element(boundBy: 0)
        guard button.waitForExistence(timeout: 2) else {
            XCTFail("Back button does not exist")
            return
        }
        button.tap()
        
        //        let backButton = app.navigationBars.firstMatch.buttons[backButtonName]
        //        XCTAssertTrue(backButton.waitForExistence(timeout: 2))
        //        backButton.tap()
        
    }

    func tapSplitButton() {
        if XCUIDevice.shared.iosVersion >= 16.0 {
            app.tapButton(id: "ToggleSidebar")
        }
        else {
            tapBackButton()
        }
    }




}


extension XCTestCase {

    func tapElementAndWaitForKeyboardToAppear(element: XCUIElement) {
        let keyboard = XCUIApplication().keyboards.element
        while (true) {
            element.tap()
            if keyboard.exists {
                break;
            }
            RunLoop.current.run(until: NSDate(timeIntervalSinceNow: 0.5) as Date)
        }
    }
}
