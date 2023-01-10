//
//  FormattingTests.swift
//  PECS MakerUITests
//
//  Created by Andy on 01/11/2022.
//

import XCTest
import SnapshotTesting


final class FormattingTests: PECSTestsBase {
    

    override func setLaunchArguments() {
        super.setLaunchArguments()
        app.launchArguments.append(LaunchArguments.autoFill)
        
    }
    
    func testFormattingWithDefaults() throws {
        let defaultFormatting = Formatting()
        runTests( with: defaultFormatting )
    }
    
    func testFormattingWithBlueAndYellow() throws {
        
        var formatting = Formatting()
        formatting.titles.textColor = "dark cyan blue 30"
        formatting.gridlines.color = "light yellow 93"
        
        runTests( with: formatting )

    }
    
    func testFormattingWithBoldTextAndThickGridlines() throws {
        
        var formatting = Formatting()
        formatting.titles.bold = true
        formatting.gridlines.thick = true
        
        runTests( with: formatting )

    }

    func testFormattingWithSmallText() throws {
        
        var formatting = Formatting()
        formatting.titles.sizePercent = 0
        
        runTests( with: formatting )

    }

    func testFormattingWithLargeText() throws {
        
        var formatting = Formatting()
        formatting.titles.sizePercent = 1
        
        runTests( with: formatting )

    }
    
    func testFormattingWithSmallMargins() throws {
        
        var formatting = Formatting()
        formatting.margins.sizePercent = 0
        
        runTests( with: formatting )

    }


    func testFormattingWithLargeMargins() throws {
        
        var formatting = Formatting()
        formatting.margins.sizePercent = 1
        
        runTests( with: formatting )
        
    }

    
    
    func testFormattingTitlesBelow() throws {
        
        var formatting = Formatting()
        formatting.titles.positionTextAtTop = false
        
        runTests( with: formatting )

    }



    func runTests(with formatting: Formatting, testName: String = #function) {
        
        //We have set the autofill launch argument, so we already have some photos & titles
        //selectPhotosFromMainMenu(count: 9, snapshotID: nil, recheckSelections: false)
        
        //Layout: Select A4 page size - any layout
        selectLayout(pageSize: .a4, orientation: .portrait, layout: PageLayout(width: 2, height: 3))
        
        //Preview and Print screen
        /*
        let previewAndPrintButton = app.buttons[AccessibilityIdentifiers.MainMenu.previewAndPrintButton]
        XCTAssertTrue(previewAndPrintButton.waitForExistence(timeout: 2))
        previewAndPrintButton.tap()
         */
        app.tapButton(id: AccessibilityIdentifiers.MainMenu.previewAndPrintButton)
        
        //Formatting screen
        app.tapButton(id: AccessibilityIdentifiers.PreviewScreen.formattingButton)
        
        //Reset everything to a known state
        setFormatting( formatting )
        
        //Go back to the preview screen
        //app.navigationBars.buttons.element(boundBy: 0).tap()
        app.tapButton(id: AccessibilityIdentifiersSSUI.PopupHeader.closeButton)
        
        //Wait for the preview to update.
        sleep(1)

//        let screenshot = XCUIScreen.main.screenshot().image
//        assertSnapshot(matching: screenshot, as: .image(precision: 0.90), testName: testName)
        assertSnapshot(testName: testName)

    }
        
    func assertSnapshot(testName: String) {
        let screenshot = XCUIScreen.main.screenshot().image
        let device = XCUIDevice.deviceName
        let orientation = XCUIDevice.shared.orientation.isPortrait ? "Portrait" : "Landscape"
        let name = "\(device)-\(orientation)"
        SnapshotTesting.assertSnapshot(matching: screenshot, as: .image(precision: 0.90), named: name, testName: testName)
        
    }
    
    
    struct Formatting {
        var titles: TitleFormatting = TitleFormatting()
        var margins: MarginFormatting = MarginFormatting()
        var gridlines: GridlineFormatting = GridlineFormatting()
        
        struct TitleFormatting {
            var textColor: String = "black 0"
            var bold: Bool = false
            var positionTextAtTop: Bool = true
            var sizePercent: CGFloat = 0.5
        }
        
        struct MarginFormatting {
            var sizePercent: CGFloat = 0.5
        }
        
        struct GridlineFormatting {
            var color: String = "black 0"
            var thick: Bool = false
        }
    }
    
    func setFormatting(_ formatting: Formatting) {
        
        let identifiers = AccessibilityIdentifiers.FormattingView.self
        
        //Titles section
        //XCTAssertTrue(app.staticTexts[identifiers.Titles.sectionTitle].exists)
        
        app.switches[identifiers.Titles.boldFontOption].setSwitch(on: formatting.titles.bold)
        
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
                app.tapButton(id: identifiers.Titles.TextPosition.top)
            }
            else {
                app.tapButton(id: identifiers.Titles.TextPosition.bottom)
            }
        }
            
        //XCTAssertTrue(app.buttons[identifiers.Titles.TextPosition.bottom].exists)
        app.sliders[identifiers.Titles.sizeSlider].adjust(toNormalizedSliderPosition: formatting.titles.sizePercent)

        app.setColorPicker(id: identifiers.Titles.textColor, colorName: formatting.titles.textColor)


        //Margins section
        //XCTAssertTrue(app.staticTexts[identifiers.Margins.sectionTitle].exists)
        app.sliders[identifiers.Margins.sizeSlider].adjust(toNormalizedSliderPosition: formatting.margins.sizePercent)

        //Gridlines section
        //XCTAssertTrue(app.staticTexts[identifiers.Gridlines.sectionTitle].exists)
        app.setColorPicker(id: identifiers.Gridlines.colour, colorName: formatting.gridlines.color)

        app.switches[identifiers.Gridlines.thicker].setSwitch(on: formatting.gridlines.thick)

    }
    



}
