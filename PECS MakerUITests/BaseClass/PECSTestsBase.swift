//
//  DarkModeTests.swift
//  PECS MakerUITests
//
//  Created by Andy on 09/04/2022.
//

import XCTest
import MediaCore
import Photos
import SnapshotTesting

@MainActor
class PECSTestsBase: XCTestCase {
    
    var app = XCUIApplication()
    
    let tempDirName = "FormattingTests"
    var tempDir: URL!
    
    let appCreatesTopicAtStartup: Bool = true
    
    enum EasyPECSAppType: String {
        case standard, plus
    }
    
    //var appVersionSupportsTopics: Bool { easyPECSAppType != .standard }
    var appVersionSupportsTopics: Bool = true
    
    var locale = ""
    
    @MainActor override func setUpWithError() throws {
        
        /*
         let pi = ProcessInfo()
         for item in pi.environment {
         print(item.key)
         }
         print(pi.environment["SIMULATOR_RUNTIME_VERSION"])
         */
        
//        if let appTypeString = ProcessInfo.processInfo.environment["Easy_PECS_App_Type"] {
//            if let appType = EasyPECSAppType(rawValue: appTypeString) {
//                self.easyPECSAppType = appType
//            }
//        }
        
        // Stop pending app writes before replacing this test's repository.
        app.terminate()
        self.tempDir = FileManager.default.temporaryDirectory
        self.tempDir = self.tempDir.appendingPathComponent(tempDirName, isDirectory: true)
        try? FileManager.default.removeItem(at: tempDir)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        print("Doc dir: \(tempDir.path)")
        
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        XCUIDevice.shared.orientation = requiredOrientation

        /*
         /Users/andy/Library/Developer/CoreSimulator/Devices/983F1EE6-FA7B-4568-B11D-5ADB805B0AC6/data/Containers/Bundle/Application/97B33868-0ED2-492E-952F-837921A17008/PECS MakerUITests-Runner.app/PlugIns/PECS MakerUITests.xctest
         */
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        
        setLaunchArguments()
        
        //For now we need to call setupSnapshot always because we are using it's locale function.
        //if Snapshots.takeSnapshots {
            setupSnapshot(app)
            locale = Snapshot.currentLocale

        //}
        app.launch()
        XCUIDevice.shared.orientation = requiredOrientation
        assertRequiredOrientation()
        
        //print(app.debugDescription)
        
        createInitialTopic()
        // Board mode is persisted outside the per-test repository.
        let designBoard = app.buttons[AccessibilityIdentifiers.TopicTitleView.pecsMakerButton]
        if designBoard.exists {
            designBoard.tap()
        }
        addTeardownBlock { @MainActor [self] in
            assertRequiredOrientation()
        }

    }
    
    var suppressFeatureVoting: Bool { true }
    var suppressWhatsNewScreen: Bool { true }
    
    func setLaunchArguments() {
        app.launchArguments = [LaunchArguments.keepPDFs, LaunchArguments.noAnalytics, LaunchArguments.noRatings,
                               LaunchArgumentsSSUI.longerAutoDismissTimeout
        ]
        
        if suppressFeatureVoting {
            app.launchArguments.append(LaunchArguments.noFeatureVoting)
        }
        if suppressWhatsNewScreen {
            app.launchArguments.append(LaunchArguments.noWhatsNew)
        }

        //app.launchArguments += ["-AppleLocale", "es_ES"]
        //app.launchArguments += ["-AppleLanguages", "(es)"]
        
        if useDarkMode {
            app.launchArguments.append(LaunchArguments.darkMode)
        }
        else {
            app.launchArguments.append(LaunchArguments.lightMode)
        }
        
        let docDirArgument = "\(LaunchArguments.docDir):\(self.tempDir!.path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!)"
        app.launchArguments.append(docDirArgument)
        
        print("Is Spanish? \(isSpanish)")
        
    }
    
    var useDarkMode: Bool {
        get { return false }
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        try FileManager.default.removeItem(at: self.tempDir)
    }
    
    var requiredOrientation: UIDeviceOrientation {
        ProcessInfo.processInfo.environment["BOARDLET_TEST_ORIENTATION"] == "landscape" ? .landscapeLeft : .portrait
    }

    @MainActor func assertRequiredOrientation() {
        XCTAssertEqual(XCUIDevice.shared.orientation, requiredOrientation)
        if requiredOrientation.isLandscape {
            XCTAssertGreaterThan(app.frame.width, app.frame.height, "App must render in landscape")
        } else {
            XCTAssertGreaterThan(app.frame.height, app.frame.width, "App must render in portrait")
        }
    }

    var isSplitView: Bool {
        if XCUIDevice.shared.iosVersion >= 16.0 {
            if app.windows.firstMatch.frame.size.width > 1024 {
                return true
            }
        }
        return false
    }
    
    func returnToMainMenu() {
        if appScreenIsVisible(.mainMenu, assertType: .noAssert) { return }
        if app.buttons[AccessibilityIdentifiers.PhotoSelectionView.closeSelectionButton].exists {
            app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.closeSelectionButton)
        }
        tapBackButton()
        XCTAssertTrue(appScreenIsVisible(.mainMenu), "Back must return to the main menu")
    }
    
    @MainActor func selectPhotosFromMainMenu(count: Int, snapshotID: String? = nil, recheckSelections: Bool = true) {
        selectPhotos(startScreen: .mainMenu, itemsToSelect: count, firstItem: 0, expectedCount: count, snapshotID: snapshotID, recheckSelections: recheckSelections)

        //Return to main menu.
        returnToMainMenu()

    }
    
    func checkChangeSelectionButtonExistence(_ exists: Bool) {
        let menuButton = app.buttons[AccessibilityIdentifiers.MainMenu.changeSelectionsButton]
        if exists {
            XCTAssertTrue(menuButton.waitForExistence(timeout: 2))
        }
        else {
            XCTAssertFalse(menuButton.exists)
        }
    }
    
    //When we go into the photo selection screen we will either land on the add photos screen aka Photo Picker (if there
    //are currently no photos selected) or the selected photos screen (if there are some photos selected).
    enum PhotoScreen { case selections, picker }
    /*
    func checkExpectedPhotoScreen(_ expectedScreen: PhotoScreen) -> Bool {
        switch expectedScreen {
        case .selections:
            return app.selectButton(AccessibilityIdentifiers.PhotoSelectionView.addMorePhotosButton) != nil
        case .picker:
            //Check that the photo picker is displayed. Current implementation is through ZLPhotoPicker.
            return app.selectButton("zl btn unselected") != nil
        }
    }
    */
    
    //Go to the Titles screen.
    func navigateToTitlesScreen() -> Bool {
        guard appScreenIsVisible(.mainMenu) else { return false }
        app.tapButton(id: AccessibilityIdentifiers.MainMenu.selectTitlesButton)
        return true
    }

    func navigateToLayoutScreen() -> Bool {
        guard appScreenIsVisible(.mainMenu) else { return false }
        app.tapButton(id: AccessibilityIdentifiers.MainMenu.selectLayoutButton)
        return true
    }
    
    func navigateToPreviewScreen() {
        //Preview and Print screen
        app.tapButton(id: AccessibilityIdentifiers.MainMenu.previewAndPrintButton)
    }
    
    func navigateToFormattingScreen() {
        //Preview and Print screen
        /*
        let previewAndPrintButton = app.buttons[AccessibilityIdentifiers.MainMenu.previewAndPrintButton]
        XCTAssertTrue(previewAndPrintButton.waitForExistence(timeout: 2))
        previewAndPrintButton.tap()
         */
        app.tapButton(id: AccessibilityIdentifiers.MainMenu.previewAndPrintButton)
        
        //Formatting screen
        app.tapButton(id: AccessibilityIdentifiers.PreviewScreen.formattingButton)

    }
    
    func navigateToPhotoPicker(from startScreen: ApplicationScreen) -> Bool {
        guard appScreenIsVisible(startScreen) else { return false }

        //Navigate to the photo picker screen
        switch(startScreen) {
        case .mainMenu:
            let selectPhotos = app.buttons[AccessibilityIdentifiers.MainMenu.selectPhotoButton]
            if selectPhotos.exists {
                selectPhotos.tap()
                if isSplitView {
                    guard navigateToPhotoPicker(from: .changeSelections) else { return false }
                }
            } else {
                // Populated boards open their photo list before adding more.
                guard navigateToPhotoSelectionScreen() else { return false }
                guard navigateToPhotoPicker(from: .changeSelections) else { return false }
            }
            /*
            if let addButton = app.selectFirstButton([AccessibilityIdentifiers.PhotoSelectionView.addMorePhotosButton, AccessibilityIdentifiers.NoPhotosView.addPhotosButton]) {
                addButton.tap()
            }*/
            
        case .changeSelections:
            
            if let menuButton = app.selectButton(AccessibilityIdentifiers.PhotoSelectionView.menuButton, assertType: .noAssert) {
                    
                menuButton.tap()

                app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.addMorePhotosButton)
                
            }
            else {
                app.tapButton(id: AccessibilityIdentifiers.NoPhotosView.addPhotosButton)
            }

            
        case .photoPicker:
            return true //Nothing to do, we're already on that screen.
        }
        
        guard appScreenIsVisible(.photoPicker) else { return false }
        
        return true
    }
    
    
    ///Use the photo picker to select some photos, including navigation to the screen from startScreen
    ///This function is overly complicated, but necessary because we have to cater for the situation
    ///where we want to select one item, return to the screen and then sleect another, but IOS gives
    ///us no way of knowing which items are already selected.
    ///It will often fail if there are too many photos and the top row has partially scrolled off screen. Fix
    ///is to remove some photos from the Photos app.
    @MainActor func selectPhotos(startScreen: ApplicationScreen, itemsToSelect: Int, firstItem: Int, expectedCount: Int, snapshotID: String? = nil, recheckSelections: Bool = true) {
        
        guard navigateToPhotoPicker(from: startScreen) else { return }

        //Take a screenshot
        snapshotIfNeeded(snapshotID)

        //Make the selections and close the picker.
        selectPhotosFromPicker(itemsToSelect: itemsToSelect, firstItem: firstItem)        
        
        //checkChangeSelectionButtonExistence(expectedCount > 0)
        
        if recheckSelections {
            //Go off to any another screen and return to the photo picker.
            if isSplitView {
                app.tapButton(id: AccessibilityIdentifiers.MainMenu.previewAndPrintButton)
                guard navigateToPhotoSelectionScreen() else { return }
            }
            else {
                //On regular view (non-split)
                //tapBackButton()
                //app.tapButton(id: AccessibilityIdentifiers.MainMenu.selectPhotoButton)
                //guard navigateToPhotoPicker(from: startScreen) else { return }
                guard navigateToPhotoSelectionScreen() else { return }
            }
            
            checkPhotoCountUsingPhotoSelectionScreen(expectedCount)

            //We aren't checking the count using the picker any more because
            //we no longer pre-select items in the picker. This is becaise the Photo
            //Selection screen shows our selections, so it's not ncessary to show
            //them in the picker. In fact it's better not to show them in the picker
            //because we can then use it to select duplicate items.
            //guard navigateToPhotoPicker(from: .selectPhotos) else { return }
            //checkPhotoCountUsingPicker(expectedCount, startScreen: .selectPhotos)
        }
        
    }
    
    func navigateToTopicScreen() {
        tapBackButton()        
    }
    
    func navigateToPhotoSelectionScreen() -> Bool {
        //Go to photo selection screen. Note that we might already be on that screen
        //if we're on the splitter view, but that doesn't matter.
        if !appScreenIsVisible(.changeSelections, assertType: .noAssert) {
            guard appScreenIsVisible(.mainMenu) else { return false }
            //app.tapButton(id: AccessibilityIdentifiers.MainMenu.selectPhotoButton)
            app.tapButton(id: isSplitView
                ? AccessibilityIdentifiers.MainMenu.selectPhotoButton
                : AccessibilityIdentifiers.MainMenu.changeSelectionsButton)
        }
        return true
    }
    
    @MainActor func selectPhotosFromPicker(itemsToSelect: Int, firstItem: Int = 0) {
        let picker = SystemPhotoPickerDriver(app: app)
        picker.assertOpen()
        for index in firstItem..<(firstItem + itemsToSelect) {
            let day = index + 1
            picker.selectPhoto(matching: NSPredicate(
                format: "label CONTAINS %@ OR label CONTAINS %@ OR label CONTAINS %@ OR label CONTAINS %@",
                String(format: "February %02d, 2020", day), "February \(day), 2020",
                String(format: "%02d February 2020", day), "Photo, \(day) February 2020"))
        }
        picker.confirm()
        picker.assertDismissed()
    }

    func checkPhotoCountUsingPhotoSelectionScreen(_ expectedCount: Int) {
        
        guard appScreenIsVisible(.changeSelections) else { return }
        
        let grid = app.scrollViews[AccessibilityIdentifiers.PhotoSelectionView.collectionView]
        XCTAssertTrue(grid.waitForExistence(timeout: 10))
        XCTAssertEqual(grid.value as? String, "\(expectedCount)")
        // LazyVGrid only exposes materialized cells. Visit each expected item.
        if expectedCount > 0 {
            let first = app.buttons[A12SSUI.PhotoCell.image(for: 0)]
            for _ in 0..<12 {
                if first.exists { break }
                XCTAssertTrue(grid.exists)
                grid.swipeDown(velocity: .slow)
            }
        }
        for i in 0..<expectedCount {
            let photo = app.buttons[A12SSUI.PhotoCell.image(for: i)]
            for _ in 0..<12 {
                if photo.exists { break }
                XCTAssertTrue(grid.exists)
                grid.swipeUp(velocity: .slow)
            }
            app.checkElementExistence(.button, id: A12SSUI.PhotoCell.image(for: i))
        }
        
        //Make sure there are no extra items
        app.checkElementNonExistence(.button, id: A12SSUI.PhotoCell.image(for: expectedCount))
        
        if expectedCount > 0 {
            let first = app.buttons[A12SSUI.PhotoCell.image(for: 0)]
            for _ in 0..<12 {
                if first.exists && first.isHittable { break }
                grid.swipeDown(velocity: .slow)
            }
        }

    }

    
    var backButtonName: String {
        isSpanish ? "Atrás" : "Back"
    }
    
    @MainActor func tapPhotoNavBarCancelButton() {
        let picker = SystemPhotoPickerDriver(app: app)
        picker.cancel()
        picker.assertDismissed()
    }

    @MainActor func selectLayout(pageSize: PageSize, orientation: PageOrientation, layout: PageLayout, snapshotID: String? = nil) {
        
        app.tapButton(id: AccessibilityIdentifiers.MainMenu.selectLayoutButton)
        
        let identfiers = AccessibilityIdentifiers.LayoutScreen.self
        
        app.tapButton(id: identfiers.pageSizeButton(for: pageSize))
        app.tapButton(id: identfiers.orientationButton(for: orientation))
        app.tapButton(id: identfiers.layoutButton(for: layout))
        
        snapshotIfNeeded(snapshotID)
        
        //app.buttons[identfiers.doneButton].tap()
        //tapBackButton()
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

    func checkLayoutOptions(minimumCount: Int, orientation: PageOrientation) {
        let ids = AccessibilityIdentifiers.LayoutScreen.self
        let prefix = ids.layoutButtonPrefix
        // In split view the first scroll view can belong to the board sidebar
        // or main menu. Scroll the pane that actually owns the layout controls.
        let scroll = app.scrollViews.containing(.button, identifier: ids.orientationButton(for: .portrait)).firstMatch
        XCTAssertTrue(scroll.waitForExistence(timeout: 5))
        let selectedOrientation = app.buttons[ids.orientationButton(for: orientation)]
        let selected = XCTNSPredicateExpectation(predicate: NSPredicate(format: "selected == true"), object: selectedOrientation)
        XCTAssertEqual(XCTWaiter.wait(for: [selected], timeout: 5), .completed,
                       "Requested page orientation must be selected before checking layouts")
        var identifiers = Set<String>()

        for _ in 0..<4 {
            let buttons = getButtonsWithPrefix(prefix)
            for button in buttons {
                identifiers.insert(button.identifier)
            }

            if let visibleButton = buttons.first(where: { $0.isHittable }) {
                if orientation == .portrait {
                    XCTAssertLessThan(visibleButton.frame.size.width, visibleButton.frame.size.height)
                } else {
                    XCTAssertGreaterThan(visibleButton.frame.size.width, visibleButton.frame.size.height)
                }
            }
            scroll.swipeUp()
        }

        XCTAssertGreaterThanOrEqual(identifiers.count, minimumCount)

        let pageSize = app.buttons[ids.pageSizeButton(for: .a4)]
        let portrait = app.buttons[ids.orientationButton(for: .portrait)]
        for _ in 0..<8 {
            if pageSize.isHittable && portrait.isHittable { break }
            scroll.swipeDown()
        }
        XCTAssertTrue(pageSize.isHittable && portrait.isHittable,
                      "Restore visible page-size and orientation controls for the next selection")
    }
    
    func getButtonsWithPrefix(_ prefix: String) -> [XCUIElement] {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix)).allElementsBoundByIndex
    }
    
    func tapButtonAndItBecomesSelected(id: String) -> Bool {
        app.tapButton(id: id)
        guard let button = app.selectButton(id) else { return false }
        let isSelected = button.isSelected
        return isSelected
    }
    
    func makePhotoTitle(for index: Int) -> String {
        return "Photo Item \(index)"
    }
    
    @MainActor func completeTitles(count: Int, snapshotID: String? = nil, isAutoFilled: Bool = false) {
        //Go to the Titles screen.
        app.tapButton(id: AccessibilityIdentifiers.MainMenu.selectTitlesButton)
        
        if !isAutoFilled {
            //Fill in the titles.
            for i in 0..<count {
                let textBox = app.textFields[AccessibilityIdentifiers.TitlesScreen.titleText(for: i)]
                XCTAssertTrue(textBox.waitForExistence(timeout: 2))
                if !isAutoFilled {
                    let title = makePhotoTitle(for: i)
                    textBox.typeText(title, retries: 3)
                }
            }
        }
        
        snapshotIfNeeded(snapshotID)
        
        if isAutoFilled {
            app.scrollDown()
        }
        
        //Return to the main screen if we're on iPhone
        returnToMainMenu()
    }
    
    func getButtonCount(prefix: String) -> Int {
        getButtonsWithPrefix(prefix).count
    }
    
    func checkButtonCount(prefix: String, expectedCount: Int) {
        for i in 0..<expectedCount {
            let buttonName = "\(prefix)\(i)"
            let button = app.images[buttonName]
            XCTAssertTrue(button.exists, "Button with ID \(buttonName) does not exist")
        }
        
        let buttonName = "\(prefix)\(expectedCount)"
        let button = app.buttons[buttonName]
        XCTAssertFalse(button.exists)
        
    }
    
    
    func getLabelCount(prefix: String) -> Int {
        app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix)).count
    }
    
    func getTextBoxCount(prefix: String) -> Int {
        app.textFields.matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix)).count
    }
    
    
    func getImageCount(prefix: String) -> Int {
        app.images.matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix)).count
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
    
    
    @MainActor func completePreviewAndPrintBySaving(repeatSingleImage: Bool = false, snapshotID: String? = nil) {
        
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
            XCTAssertTrue(repeatButton.waitForExistence(timeout: 1))
            //repeatButton.forceTap()
            repeatButton.setSwitch(on: true)
        }
        
        snapshotIfNeeded(snapshotID)
        
        //Tap the Save and Print button so we can save a PDF
        app.tapButton(id: AccessibilityIdentifiers.PreviewScreen.saveAndPrintButton)
        //app.tapButton(id: AccessibilityIdentifiers.PreviewScreen.saveAndPrintImageButton)
        //app.tapButton(id: AccessibilityIdentifiers.PreviewScreen.saveAndPrintPDFButton)
        
        //In the Activity Controller (share screen), tap the Save to Files button
        //which has the wierd label XCElementSnapshotPrivilegedValuePlaceholder
        //Activity inspector says this is called "Activity" even though it says "Save to Files"
        
        let fileBrowserApp: XCUIApplication
        let sharingUIServiceApp = XCUIApplication(bundleIdentifier: "com.apple.SharingUIService")
        let saveLabels = isSpanish ? ["Guardar en Archivos", "Save to Files"] : ["Save to Files"]
        let savePredicate = NSPredicate(format: "label IN %@ OR identifier IN %@", saveLabels, saveLabels)
        let remoteSaveCell = sharingUIServiceApp.cells.matching(savePredicate).firstMatch
        let localSaveCell = app.cells.matching(savePredicate).firstMatch
        if remoteSaveCell.waitForExistence(timeout: 5) {
            remoteSaveCell.tap()
            fileBrowserApp = XCUIApplication(bundleIdentifier: "com.apple.DocumentManagerUICore.SaveToFiles")
        } else if localSaveCell.waitForExistence(timeout: 5) {
            localSaveCell.tap()
            fileBrowserApp = app
        } else {
            //let saveToFilesButton = app.otherElements["ActivityListView"].cells.containing(.other, identifier: "Save").firstMatch
            var saveToFilesButton: XCUIElement!
            if XCUIDevice.shared.iosVersion < 15.0 {
                saveToFilesButton = app.buttons["Save to Files"]
                XCTAssert(saveToFilesButton.waitForExistence(timeout: 1))
            } else {
                saveToFilesButton = app/*@START_MENU_TOKEN@*/.collectionViews/*[[".otherElements[\"ActivityListView\"].collectionViews",".collectionViews"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.buttons["XCElementSnapshotPrivilegedValuePlaceholder"].children(matching: .other).element(boundBy: 1).children(matching: .other).element(boundBy: 2)
                if !saveToFilesButton.waitForExistence(timeout: 1) {
                    //Needed on iPhone 14 (IOS 16.4)
                    saveToFilesButton = app/*@START_MENU_TOKEN@*/.collectionViews/*[[".otherElements[\"ActivityListView\"].collectionViews",".collectionViews"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.children(matching: .cell)["XCElementSnapshotPrivilegedValuePlaceholder"].children(matching: .other).element(boundBy: 1).children(matching: .other).element(boundBy: 1)
                    //Needed on iPad (IOS 17)
                    if !saveToFilesButton.waitForExistence(timeout: 1) {
                        let saveToFilesButtonName = isSpanish ? "Guardar en Archivos" : "Save to Files"
                        saveToFilesButton = app.collectionViews.cells[saveToFilesButtonName].children(matching: .other).element(boundBy: 1).children(matching: .other).element(boundBy: 2)
                        //Needed on iPhone 16 with ios18 (any maybe others) because it always displays
                        //the English translation.
                        if !saveToFilesButton.waitForExistence(timeout: 1) {
                            let saveToFilesButtonName = "Save to Files"
                            saveToFilesButton = app.collectionViews.cells[saveToFilesButtonName].children(matching: .other).element(boundBy: 1).children(matching: .other).element(boundBy: 2)
                            //let predicate = NSPredicate(format: "label BEGINSWITH %@", saveToFilesButtonName)
                            //saveToFilesButton = app.otherElements.containing(predicate).element(boundBy: 0)
                            XCTAssertTrue(saveToFilesButton.waitForExistence(timeout: 1))
                        }
                    }
                }
            }
            saveToFilesButton.tap()
            fileBrowserApp = app
        }
        
        if XCUIDevice.isiPad {
            //In the Files Controller, tap the save location.
            let buttonName = isSpanish ? "En mi iPad" : "On My iPad"
            let iPadButton = fileBrowserApp.cells[buttonName]
            let iPadButton2 = isSpanish ? fileBrowserApp.staticTexts["DOC.sidebar.item.En Mi iPad"] :
            fileBrowserApp.staticTexts["DOC.sidebar.item.On My iPad"]
            //iPad (IOS17). Needs to come before the IOS15.5 check because that will match multiple elements on IOS17
            let iPadButton3 = fileBrowserApp.collectionViews["Browse View"].staticTexts[buttonName]
            //iPad Air 5th Gen (IOS 15.5)
            let iPadButton4 = fileBrowserApp.staticTexts[buttonName]

            //app/*@START_MENU_TOKEN@*/.navigationBars["FullDocumentManagerViewControllerNavigationBar"]/*[[".otherElements[\"Browse View (Picker)\"]",".otherElements[\"DOC.browsingRoot Source: com.apple.FileProvider.LocalStorage, Title: On My iPad\"].navigationBars[\"FullDocumentManagerViewControllerNavigationBar\"]",".navigationBars[\"FullDocumentManagerViewControllerNavigationBar\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.buttons["Save"].tap()
            
            if iPadButton.waitForExistence(timeout: 1) {
                iPadButton.tap()
            }
            else if iPadButton2.waitForExistence(timeout: 1) {
                iPadButton2.tap()
            }
            else if iPadButton3.waitForExistence(timeout: 1) {
                iPadButton3.tap()
            }
            else if iPadButton4.waitForExistence(timeout: 1) {
                iPadButton4.tap()
            }
            else {
                XCTFail("Unable to find My iPad save location")
            }
        }
        else {
            
            let saveLocationName = isSpanish ? "En mi iPhone" : "On My iPhone"
            let onMyPhoneTitleInNavBar = fileBrowserApp.navigationBars["FullDocumentManagerViewControllerNavigationBar"].staticTexts[saveLocationName]
            if onMyPhoneTitleInNavBar.waitForExistence(timeout: 1) {
                //We've been automatically navigated to the On My iPhone folder
            }
            else {
                //We need to navigate to the On My iPhone folder
                let iPhoneButton = fileBrowserApp.staticTexts[saveLocationName]
                if iPhoneButton.waitForExistence(timeout: 1) {
                    iPhoneButton.tap()
                }
                else {
                    //Seems to happen a lot on IOS16 where the Share Sheet appears and
                    //immediately disappears.
                    XCTFail("Unable to find My iPhone as a file save location")
                }
            }
        }
        
        //Tap save.
        //app/*@START_MENU_TOKEN@*/.navigationBars["SaveToFiles.DOCServiceTargetSelectionBrowserView"]/*[[".otherElements[\"Target View\"].navigationBars[\"SaveToFiles.DOCServiceTargetSelectionBrowserView\"]",".navigationBars[\"SaveToFiles.DOCServiceTargetSelectionBrowserView\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*///.buttons[fileBrowserSaveButtonName].tap()
        fileBrowserApp.tapButton(id: fileBrowserSaveButtonName)
        
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
        let replaceButton = fileBrowserApp.buttons[fileBrowserReplaceButtonName]
        if replaceButton.waitForExistence(timeout: 1) {
            //Sometimes we get an error here saying we can't replace the file.
            replaceButton.tap()
        }
        
        //Dismiss the success notification.
        //        let successAlert = app.alerts["Success"]
        //        XCTAssertTrue(successAlert.waitForExistence(timeout: 2))
        //        successAlert.buttons["OK"].tap()
        
        //Increased timeout to 10s. Seems to take a while for save to complete ion IOS17.
        let successAlert = app.images[AccessibilityIdentifiersSSUI.Animations.doneAnimation]
        XCTAssertTrue(successAlert.waitForExistence(timeout: 10))
        
        //Dismiss the prompt to rate.
        //dismissRatingAlert()
        
    }
    
    /*
     func testRatingRateAndNotNow() {
     
     app/*@START_MENU_TOKEN@*/.buttons["RatingAlerts.AskInitialQuestion.rateButton"]/*[[".buttons[\"Love It\"]",".buttons[\"RatingAlerts.AskInitialQuestion.rateButton\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
     
     let elementsQuery = app.scrollViews.otherElements
     elementsQuery.buttons["Not Now"].tap()
     
     }
     
     func testRatingRateNeedsWorkSendFeedback() {
     
     app/*@START_MENU_TOKEN@*/.buttons["RatingAlerts.AskInitialQuestion.needsWorkButton"]/*[[".buttons[\"Needs Work\"]",".buttons[\"RatingAlerts.AskInitialQuestion.needsWorkButton\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
     app/*@START_MENU_TOKEN@*/.buttons["RatingAlerts.SelectFeedbackCategory.button.0"]/*[[".buttons[\"Add a new feature\"]",".buttons[\"RatingAlerts.SelectFeedbackCategory.button.0\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
     app/*@START_MENU_TOKEN@*/.buttons["RatingAlerts.RequestMoreFeedback.yesButton"]/*[[".buttons[\"Yes\"]",".buttons[\"RatingAlerts.RequestMoreFeedback.yesButton\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
     app.collectionViews/*@START_MENU_TOKEN@*/.buttons["Send"]/*[[".cells.buttons[\"Send\"]",".buttons[\"Send\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
     
     }
     */
    
    
    @MainActor func snapshotIfNeeded(_ snapshotID: String?) {
        if let snapshotID = snapshotID {
            Snapshot.snapshot(snapshotID)
        }
    }
    
    func createInitialTopic() {
        if appCreatesTopicAtStartup {
            
            return
        }
        
        //let title = isSpanish ? "Mis Diseños" : "My Designs"
        //app.navigationBars[title].buttons[AccessibilityIdentifiers.TopicSelectionView.createDesignButton].tap()
        
        createTopic()
    }
    
    func createTopic() {
        app.tapButton(id: AccessibilityIdentifiers.TopicSelectionView.createDesignButton1)
    }
    
    func checkTopicTitleOnMainMenu(topicName: String) {
        let title = app.navigationBars.staticTexts[topicName]
        //app.checkElementExistence(.staticText, id: topicName)
        XCTAssertTrue(title.waitForExistence(timeout: 2))
    }
    
    var isTopicViewVisible: Bool {
        let button = app.buttons[AccessibilityIdentifiers.TopicSelectionView.createDesignButton1]
        if  button.exists {
            return true
        }
        else {
            if button.waitForExistence(timeout: 2) {
                return true
            }
            else {
                return false
            }
        }
    }
    func tapSidebarButton() {
        let toggle = app.navigationBars.buttons.matching(NSPredicate(
            format: "identifier == 'ToggleSidebar' OR label == 'Show Sidebar' OR label == 'Mostrar barra lateral'"
        )).firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 10), app.debugDescription)
        toggle.tap()
    }
    
    func tapBackButton() {
        let button = app.navigationBars.buttons.element(boundBy: 0)
        guard button.waitForExistence(timeout: 10) else {
            XCTFail("Back button does not exist")
            return
        }
        button.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        
        //        let backButton = app.navigationBars.firstMatch.buttons[backButtonName]
        //        XCTAssertTrue(backButton.waitForExistence(timeout: 2))
        //        backButton.tap()
        
    }
    
    enum ApplicationScreen { case mainMenu, changeSelections, photoPicker }
    enum MainMenuScreen { case selectPhotos, changeSelections, layout, titles, preview, settings }

    func appScreenIsVisible(_ screen: ApplicationScreen, assertType: UIElementExistsAssert = .exists) -> Bool {
        switch screen {
        case .mainMenu:
            guard let button = app.selectButton(
                AccessibilityIdentifiers.MainMenu.selectLayoutButton,
                assertType: assertType
            ) else {
                return false
            }
            // During iOS 27 navigation transitions, querying isHittable can
            // raise an XCTest activation-point error before it can retry.
            // Screen detection needs an on-screen frame; the next real tap
            // and destination assertion still verify interaction.
            let visible = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                guard button.exists else { return false }
                let frame = button.frame
                return frame.width > 0 && frame.height > 0 && self.app.frame.intersects(frame)
            }, object: nil)
            let isVisible = XCTWaiter.wait(for: [visible], timeout: 10) == .completed
            if case .exists = assertType {
                XCTAssertTrue(isVisible, "Main menu must have an on-screen layout button")
            }
            return isVisible
        case .changeSelections:
            return app.selectFirstButton([AccessibilityIdentifiers.PhotoSelectionView.menuButton,
                                          AccessibilityIdentifiers.PhotoSelectionView.closeSelectionButton,
                                          AccessibilityIdentifiers.NoPhotosView.addPhotosButton], assertType: assertType) != nil
        case .photoPicker:
            // The out-of-process picker can expose a visible Cancel control
            // without an accessibility hit point. The shared driver verifies
            // the native grid and Search before performing real selections.
            let cancel = app.buttons[isSpanish ? "Cancelar" : "Cancel"].firstMatch
            switch assertType {
            case .exists:
                let appeared = cancel.waitForExistence(timeout: 15)
                XCTAssertTrue(appeared, "System Photos picker must finish presenting. \(app.debugDescription)")
                return appeared
            case .noAssert:
                return cancel.waitForExistence(timeout: 2)
            case .doesNotExist:
                XCTAssertTrue(cancel.waitForNonExistence(timeout: 5))
                return cancel.exists
            }
        }
    }
    
    func mainMenuScreenIsVisible(_ screen: MainMenuScreen, assertType: UIElementExistsAssert = .exists) -> Bool {
        switch screen {
        case .selectPhotos:
            return appScreenIsVisible(.photoPicker, assertType: assertType)
        case .changeSelections:
            return app.selectFirstButton([AccessibilityIdentifiers.PhotoSelectionView.menuButton,
                                          AccessibilityIdentifiers.PhotoSelectionView.closeSelectionButton,
                                          AccessibilityIdentifiers.NoPhotosView.addPhotosButton], assertType: assertType) != nil
        case .layout:
            return app.selectStaticText(AccessibilityIdentifiers.LayoutScreen.layoutHeading, assertType: assertType) != nil
        case .titles:
            //TODO: Need a check for when there are some photos.
            return app.selectStaticText(AccessibilityIdentifiers.NoPhotosView.tipView, assertType: assertType) != nil
        case .preview:
            return app.selectButton(AccessibilityIdentifiers.PreviewScreen.formattingButton, assertType: assertType) != nil
        case .settings:
            return app.selectStaticText(AccessibilityIdentifiersSettings.SettingsScreen.AboutCard.appVersion, assertType: assertType) != nil
        }
    }
    
    func navigateToTopicScreenFromMainMenu() {
        if isSplitView {
            //We might have the main menu and the topic screen on
            //screen, so we need to check, otherwise we will end
            //up hiding the topic view which is in the sidebar.
            if isTopicViewVisible {
                return
            }
            tapSidebarButton()
        }
        else {
            //At present the base class creates a new topic and sends us there. So this
            //function just needs to tap the back button.
            //Might be more useful in future if we
            //decide to move the topic screen elsewhere.
            if appScreenIsVisible(.mainMenu) {
                tapBackButton()
            }
        }
        
    }
    
    func tapSplitButton() {
        if XCUIDevice.shared.iosVersion >= 16.0 {
            if !isTopicViewVisible { tapSidebarButton() }
        }
        else {
            tapBackButton()
        }
    }
    
    func returnToTopicScreen(from startScreen: ApplicationScreen) {
        guard appScreenIsVisible(startScreen) else { return }
                
        if isSplitView {
            if !isTopicViewVisible { tapSplitButton() }
        }
        else {
            switch startScreen {
            case .mainMenu:
                tapBackButton()
            case .changeSelections:
                if app.buttons[AccessibilityIdentifiers.PhotoSelectionView.closeSelectionButton].exists {
                    app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.closeSelectionButton)
                }
                tapBackButton()
                returnToTopicScreen(from: .mainMenu)
            case .photoPicker:
                tapPhotoNavBarCancelButton()
                if appScreenIsVisible(.changeSelections, assertType: .noAssert) {
                    returnToTopicScreen(from: .changeSelections)
                }
                else {
                    returnToTopicScreen(from: .mainMenu)
                }
            }
        }
        
    }
    
    func dismissRatingAlert() {
        //Use the extension from SharedSwiftUI
        app.submitRating(rate: false)
    }
    
    func checkTopicCount(_ expectedCount: Int) {
        //Make sure we now have all the expected topics
        for index in 0..<expectedCount {
            app.selectButton(AccessibilityIdentifiers.TopicSelectionView.topicButton(for: index))
        }
        //Make sure we DON'T have any unexpected topics
        let missingTopic = app.buttons[AccessibilityIdentifiers.TopicSelectionView.topicButton(for: expectedCount)]
        XCTAssertFalse(missingTopic.waitForExistence(timeout: 1))

    }
    
    func selectTopic(index: Int) {
        app.tapButton(id: AccessibilityIdentifiers.TopicSelectionView.topicButton(for: index))
    }
    
    func completeEditPopupWithRandomText(prefix: String, initialValue: String? = nil) -> String {
        
        //Get the existing text from the edit field.
        let titleEditField = app.textFields[A12SSUI.Alert.textField]
        XCTAssert(titleEditField.waitForExistence(timeout: 2))
        guard let existingText = titleEditField.value as? String else {
            XCTFail("Could not get text from title field")
            return ""
        }
        
        if let initialValue {
            XCTAssertEqual(existingText, initialValue)
        }
        
        // The alert focuses its text field automatically. In landscape the
        // keyboard can cover the clear button, so edit through the keyboard.
        if !app.keyboards.firstMatch.exists {
            tapElementAndWaitForKeyboardToAppear(element: titleEditField)
        }
        let deleteKeys = existingText == titleEditField.placeholderValue ? ""
            : String(repeating: XCUIKeyboardKey.delete.rawValue, count: existingText.count)
        let title = "\(prefix)\(Int.random(in: 1...10000))"
        // One sequence avoids repeated XCTest keyboard-animation waits.
        titleEditField.typeText(deleteKeys + title + "\n")
        XCTAssertEqual(titleEditField.value as? String, title)
        
        //Press confirm
        let titleConfirmButton = app.buttons[A12SSUI.Alert.saveButton]
        XCTAssert(titleConfirmButton.waitForExistence(timeout: 2))
        titleConfirmButton.tap()
        
        return title
    }
    
    func checkEditPopupText(prefix: String, expectedValue: String? = nil) {
        
        //Get the existing text from the edit field.
        let titleEditField = app.textFields[A12SSUI.Alert.textField]
        XCTAssert(titleEditField.waitForExistence(timeout: 2))
        guard let existingText = titleEditField.value as? String else {
            XCTFail("Could not get text from title field")
            return
        }
        
        XCTAssertEqual(existingText, expectedValue, "Rename popup does not contain the right text.")
    }

    func respondYesToAlert() {
        app.tapButton(id: AccessibilityIdentifiersSSUI.Alert.yesButton)
    }
    
    struct Formatting {
        var titles: TitleFormatting = TitleFormatting()
        var margins: MarginFormatting = MarginFormatting()
        var gridlines: GridlineFormatting = GridlineFormatting()
        var cellBackground: CellBackgroundFormatting = CellBackgroundFormatting()
        
        struct TitleFormatting {
            var textColor: String = " 0" //"black 0"
            var bold: Bool = false
            var positionTextAtTop: Bool = true
            var sizePercent: CGFloat = 0.5
        }
        
        struct MarginFormatting {
            var sizePercent: CGFloat = 0.5
        }
        
        struct GridlineFormatting {
            var color: String = " 0" //"black 0"
            var thick: Bool = false
        }
        
        struct CellBackgroundFormatting {
            var color: String = " 93" //light yellow 93"
        }
    }
    
    func setFormatting(_ formatting: Formatting) {
        
        let identifiers = AccessibilityIdentifiers.FormattingView.self
        
        //Titles section
        //XCTAssertTrue(app.staticTexts[identifiers.Titles.sectionTitle].exists)
        
        app.switches[identifiers.CardSection.Font.bold].setSwitch(on: formatting.titles.bold)
        
        if XCUIDevice.shared.iosVersion < 15.0 {
            //Workaround for a bug in IOS14 that causes all of the accessibility identifiers not
            //to work on a Segmented Picker control so we have to use hard-coded labels.
            //https://stackoverflow.com/questions/60894793/segmented-picker-removes-accessibility
            if formatting.titles.positionTextAtTop {
                app.scrollViews.otherElements.segmentedControls.buttons["Top"].tap()
                
            }
            else {
                app.scrollViews.otherElements.segmentedControls.buttons["Bottom"].tap()
            }
        }
        else {
            if formatting.titles.positionTextAtTop {
                app.tapButton(id: identifiers.CardSection.TextPosition.top)
            }
            else {
                app.tapButton(id: identifiers.CardSection.TextPosition.bottom)
            }
        }
            
        //XCTAssertTrue(app.buttons[identifiers.Titles.TextPosition.bottom].exists)
        app.sliders[identifiers.CardSection.Font.Size.slider].adjust(toNormalizedSliderPosition: formatting.titles.sizePercent)

        app.setColorPicker(id: identifiers.CardSection.Font.color, colorName: formatting.titles.textColor, isSpanish: isSpanish)


        app.scrollFormatting(towardTop: false)
        
        //Margins section
        //XCTAssertTrue(app.staticTexts[identifiers.Margins.sectionTitle].exists)
        app.sliders[identifiers.Margins.sizeSlider].adjust(toNormalizedSliderPosition: formatting.margins.sizePercent)

        //Gridlines section
        //XCTAssertTrue(app.staticTexts[identifiers.Gridlines.sectionTitle].exists)
        app.setColorPicker(id: identifiers.Gridlines.colour, colorName: formatting.gridlines.color, isSpanish: isSpanish)

        let thickGridlines = app.switches[identifiers.Gridlines.thicker]
        let formattingScroll = app.formattingContent
        for _ in 0..<8 {
            if thickGridlines.isHittable && formattingScroll.frame.contains(thickGridlines.frame) { break }
            app.scrollFormatting(towardTop: thickGridlines.frame.midY < formattingScroll.frame.midY)
        }
        thickGridlines.setSwitch(on: formatting.gridlines.thick)
        XCTAssertEqual(thickGridlines.isSwitchOn(), formatting.gridlines.thick)
        
        //Background colour section
        //XCTAssertTrue(app.staticTexts[identifiers.Gridlines.sectionTitle].exists)
        app.setColorPicker(id: identifiers.CellBackground.colour, colorName: formatting.cellBackground.color, isSpanish: isSpanish)



    }
    
    func closeFormattingScreen() {
        let close = app.buttons[AccessibilityIdentifiersSSUI.PopupHeader.closeButton]
        for _ in 0..<8 {
            if close.exists && close.isHittable { break }
            app.scrollFormatting(towardTop: true)
        }
        guard close.exists && close.isHittable else {
            XCTFail("Formatting Close button must be visible before dismissing")
            return
        }
        close.tap()
        XCTAssertTrue(close.waitForNonExistence(timeout: 5), "Formatting sheet must close before preview validation")
        XCTAssertTrue(app.buttons[AccessibilityIdentifiers.PreviewScreen.formattingButton].waitForExistence(timeout: 5))
    }

    func setFormatting(_ formatting: Formatting, snapshot: Bool, testName: String = #function) {
        
        navigateToFormattingScreen()
        
        //Reset everything to a known state
        setFormatting( formatting )
        
        //Go back to the preview screen
        //app.navigationBars.buttons.element(boundBy: 0).tap()
        closeFormattingScreen()
        
        if snapshot {
            //Wait for the preview to update.
            sleep(1)
            assertSnapshot(testName: testName)
        }
        
        //Go back to main menu
        returnToMainMenu()

    }
        
    func assertSnapshot(testName: String) {
        // iPadOS 27 lays out three columns and its references include the board
        // sidebar. On iPadOS 18 that sidebar overlays and clips the preview, so
        // retain the unobscured two-column layout used while editing formatting.
        if isSplitView && XCUIDevice.shared.iosVersion >= 27 && !isTopicViewVisible {
            tapSidebarButton()
            XCTAssertTrue(app.buttons[AccessibilityIdentifiers.TopicSelectionView.createDesignButton1]
                .waitForExistence(timeout: 10), "Snapshot requires the board sidebar")
        }
        let screenshot = XCUIScreen.main.screenshot().image
        // Disposable simulator names contain UUIDs; references must be stable
        // for the same device geometry and OS, and distinct across the matrix.
        let model = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"]
            ?? (XCUIDevice.isiPad ? "iPad" : "iPhone")
        let device = "\(model)-iOS-\(UIDevice.current.systemVersion)-\(Int(app.frame.width))x\(Int(app.frame.height))"
        let orientation = XCUIDevice.shared.orientation.isPortrait ? "Portrait" : "Landscape"
        let deviceAndOrientation = "\(device)-\(orientation)"
        let name = easyPECSAppType == .plus ? "Plus-\(deviceAndOrientation)" : deviceAndOrientation
        SnapshotTesting.assertSnapshot(matching: screenshot, as: .image(precision: 0.90), named: name, testName: testName)
        
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
/*
extension XCUIApplication {
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
    
}
*/
