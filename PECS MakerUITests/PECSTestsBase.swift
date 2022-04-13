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

        setupSnapshot(app)
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
    
    
    func selectPhotosFromMainMenu(count: Int, snapshotID: String? = nil, recheckSelections: Bool = true) {

        let selectPhotoButton = app.buttons[AccessibilityIdentifiers.MainMenu.selectPhotoButton]
        XCTAssertTrue(selectPhotoButton.waitForExistence(timeout: 2))
        selectPhotoButton.tap()

        //Select the first count images
        //let phot = app.otherElements["Photos"]
        //let photosContainer = app/*@START_MENU_TOKEN@*/.otherElements["Photos"].scrollViews/*[[".otherElements[\"Photos\"].scrollViews",".scrollViews"],[[[-1,1],[-1,0]]],[1]]@END_MENU_TOKEN@*/.otherElements.otherElements
        //XCTAssertTrue(photosContainer.element.waitForExistence(timeout: 2))
        let images = app.scrollViews.images
        XCTAssertTrue(images.firstMatch.waitForExistence(timeout: 2))
        //let images = photosContainer.children(matching: .image)
        //let count = images.count
        //let count = 8
        for i in 0..<count {
            let image = images.element(boundBy: i)
            if image.isSelected == false {
                image.tap()
            }
        }

        /*
        XCUIApplication()/*@START_MENU_TOKEN@*/.otherElements["Photos"].scrollViews/*[[".otherElements[\"Photos\"].scrollViews",".scrollViews"],[[[-1,1],[-1,0]]],[1]]@END_MENU_TOKEN@*/.otherElements.otherElements["Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07, Foto, 02 de noviembre de 2018, 7:07"].children(matching: .image).matching(identifier: "Foto, 02 de noviembre de 2018, 7:07").element(boundBy: 0).tap()
                
        */
        
        
        //Verify that we have 8 items by checking the text on the button... not ideal
        let selectedItemsButtonLabel = "Show Selected (\(count))"
        XCTAssertTrue(app.buttons[selectedItemsButtonLabel].exists)
        
        snapshotIfNeeded(snapshotID)

        //Confirm selection and go back to main menu
        tapPhotoNavBarAddorDoneButton()

        if recheckSelections {
            //Go back into photos screen and verify that we still have 8 items
            let selectPhotoButton = app.buttons[AccessibilityIdentifiers.MainMenu.selectPhotoButton]
            XCTAssert(selectPhotoButton.waitForExistence(timeout: 2))
            selectPhotoButton.tap()
            
            let selectedItemsButton = app.buttons[selectedItemsButtonLabel]
            XCTAssertTrue(selectedItemsButton.waitForExistence(timeout: 2))
            
            //Exit the photos screen (Add button is not called Done).
            tapPhotoNavBarAddorDoneButton()
        }
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
        let addButton = app.navigationBars.firstMatch.buttons[photoBrowserAddButtonName]
        if addButton.exists {
            addButton.tap()
        }
        else {
            app.navigationBars.firstMatch.buttons[photoBrowserDoneButtonName].tap()
        }

    }
    
    func selectLayout(pageSize: PageSize, orientation: PageOrientation, layout: PageLayout, snapshotID: String? = nil) {
        
        //Go to the layout selection screen.
        let layoutButton = app.buttons[AccessibilityIdentifiers.MainMenu.selectLayoutButton]
        XCTAssertTrue(layoutButton.waitForExistence(timeout: 2))
        layoutButton.tap()

        let identfiers = AccessibilityIdentifiers.LayoutScreen.self

        app.buttons[identfiers.pageSizeButton(for: pageSize)].tap()
        app.buttons[identfiers.orientationButton(for: orientation)].tap()
        app.buttons[identfiers.layoutButton(for: layout)].tap()
        
        snapshotIfNeeded(snapshotID)
        
        app.buttons[identfiers.doneButton].tap()
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
        button.tap()
        let isSelected = button.isSelected
        return isSelected
    }
    
    func completeTitles(count: Int, snapshotID: String? = nil, isAutoFilled: Bool = false) {
        //Go to the Titles screen.
        app.buttons[AccessibilityIdentifiers.MainMenu.selectTitlesButton].tap()

        if !isAutoFilled {
            //Fill in the titles
            for i in 0..<count {
                let textBox = app.textFields[AccessibilityIdentifiers.TitlesScreen.titleText(for: i)]
                textBox.tap()
                textBox.typeText("Photo Item \(i)")
                //Dismiss the keyboard
                textBox.typeText("\n")
            }
        }
        
        snapshotIfNeeded(snapshotID)
                
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
            
            if locale.uppercased().prefix(2) == "ES" {
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
        app.buttons[AccessibilityIdentifiers.MainMenu.previewAndPrintButton].tap()
        
        if repeatSingleImage {
            let repeatButton = app.switches[AccessibilityIdentifiers.PreviewScreen.repeatImageButton]
            XCTAssertTrue(repeatButton.waitForExistence(timeout: 2))
            repeatButton.tap()
        }
        
        snapshotIfNeeded(snapshotID)
        
        //Tap the Save button()
        app.buttons[AccessibilityIdentifiers.PreviewScreen.saveAndPrintButton].tap()
        
        
        //In the Activity Controller (share screen), tap the Save to Files button
        //which has the wierd label XCElementSnapshotPrivilegedValuePlaceholder
        app.buttons["XCElementSnapshotPrivilegedValuePlaceholder"].tap()
        
        
        //In the Files Controller, tap the save location for iPad.
        
        let iPadButton = app/*@START_MENU_TOKEN@*/.tables.cells.containing(.image, identifier:"ipad")/*[[".otherElements[\"Target View\"].tables",".cells.containing(.staticText, identifier:\"On My iPad\")",".cells.containing(.image, identifier:\"ipad\")",".tables"],[[[-1,3,1],[-1,0,1]],[[-1,2],[-1,1]]],[0,0]]@END_MENU_TOKEN@*/.firstMatch
        if iPadButton.waitForExistence(timeout: 2) {
            iPadButton.tap()
        }
        else {
            let iPhoneButton = app.tables.cells.containing(.image, identifier:"iphone").firstMatch
            if iPhoneButton.waitForExistence(timeout: 2) {
                iPhoneButton.tap()
            }
            else {
                let iPhoneButton = app.tables.cells.containing(.image, identifier:"iphone.homebutton").firstMatch
                if iPhoneButton.waitForExistence(timeout: 2) {
                    iPhoneButton.tap()
                }
                else {
                    XCTFail("Unable to find My iPad or My iPhone as a file save location")
                }
            }
        }
            
        
        //Tap save.
        app/*@START_MENU_TOKEN@*/.navigationBars["SaveToFiles.DOCServiceTargetSelectionBrowserView"]/*[[".otherElements[\"Target View\"].navigationBars[\"SaveToFiles.DOCServiceTargetSelectionBrowserView\"]",".navigationBars[\"SaveToFiles.DOCServiceTargetSelectionBrowserView\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.buttons[fileBrowserSaveButtonName].tap()
        
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
        let successAlert = app.staticTexts[AccessibilityIdentifiers.PreviewScreen.doneAnimation]
        XCTAssertTrue(successAlert.waitForExistence(timeout: 2))
        
        //Dismiss the prompt to rate.
        //let rateAlert = app.alerts[A12.RatingAlert.window]
        //let rateAlert = app.alerts["Please Rate Easy PECS"]
        //XCTAssertTrue(rateAlert.waitForExistence(timeout: 2))
        //rateAlert.buttons[A12.RatingAlert.noButton].tap()
        let rateAlertButton = app.buttons[A12.RatingAlert.noButton]
        XCTAssertTrue(rateAlertButton.waitForExistence(timeout: 2))
        //print(rateAlertButton)
        rateAlertButton.tap()
        

        //XCUIApplication().scrollViews.otherElements/*@START_MENU_TOKEN@*/.buttons["PreviewScreen.saveAndPrintButton"]/*[[".buttons[\"Save or Print\"]",".buttons[\"PreviewScreen.saveAndPrintButton\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
                        
        //print(XCUIApplication().debugDescription)
        
    }

    func snapshotIfNeeded(_ snapshotID: String?) {
        if let snapshotID = snapshotID {
            Snapshot.snapshot(snapshotID)
        }
    }



}
