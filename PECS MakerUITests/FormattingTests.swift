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
        
        selectPhotosFromMainMenu(count: 9, snapshotID: nil, recheckSelections: false)
        
        //Layout: Select A4 page size - any layout
        selectLayout(pageSize: .a4, orientation: .portrait, layout: PageLayout(width: 2, height: 3))
        
        //Preview and Print screen
        //We have set the autofill launch argument, so we already have some photos & titles
        let previewAndPrintButton = app.buttons[AccessibilityIdentifiers.MainMenu.previewAndPrintButton]
        XCTAssertTrue(previewAndPrintButton.waitForExistence(timeout: 2))
        previewAndPrintButton.tap()
        
        //Formatting screen
        let formattingButton = app.buttons[AccessibilityIdentifiers.PreviewScreen.formattingButton]
        XCTAssertTrue(formattingButton.waitForExistence(timeout: 2))
        formattingButton.tap()
        
        //Reset everything to a known state
        setFormatting( formatting )
        
        //Go back to the preview screen
        app.navigationBars.buttons.element(boundBy: 0).tap()
        
        //Wait for the preview to update.
        sleep(1)

        let screenshot = XCUIScreen.main.screenshot().image
        assertSnapshot(matching: screenshot, as: .image(precision: 0.95), testName: testName)
        
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
        
        if formatting.titles.positionTextAtTop {
            app.buttons[identifiers.Titles.TextPosition.top].tap()
        }
        else {
            app.buttons[identifiers.Titles.TextPosition.bottom].tap()
        }
        
            
        //XCTAssertTrue(app.buttons[identifiers.Titles.TextPosition.bottom].exists)
        app.sliders[identifiers.Titles.sizeSlider].adjust(toNormalizedSliderPosition: formatting.titles.sizePercent)

        app.otherElements[identifiers.Titles.textColor].setColorPicker(colorName: formatting.titles.textColor)


        //Margins section
        //XCTAssertTrue(app.staticTexts[identifiers.Margins.sectionTitle].exists)
        app.sliders[identifiers.Margins.sizeSlider].adjust(toNormalizedSliderPosition: formatting.margins.sizePercent)

        //Gridlines section
        //XCTAssertTrue(app.staticTexts[identifiers.Gridlines.sectionTitle].exists)
        app.otherElements[identifiers.Gridlines.colour].setColorPicker(colorName: formatting.gridlines.color)
        app.switches[identifiers.Gridlines.thicker].setSwitch(on: formatting.gridlines.thick)

    }
    



}
