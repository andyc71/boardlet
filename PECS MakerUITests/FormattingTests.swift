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
        runFormattingTests( with: defaultFormatting )
    }
    
    func testFormattingWithBlueAndYellow() throws {
        
        var formatting = Formatting()
        formatting.titles.textColor = "dark cyan blue 30"
        formatting.gridlines.color = "light yellow 93"
        
        runFormattingTests( with: formatting )

    }
    
    func testFormattingWithBoldTextAndThickGridlines() throws {
        
        var formatting = Formatting()
        formatting.titles.bold = true
        formatting.gridlines.thick = true
        
        runFormattingTests( with: formatting )

    }

    func testFormattingWithSmallText() throws {
        
        var formatting = Formatting()
        formatting.titles.sizePercent = 0
        
        runFormattingTests( with: formatting )

    }

    func testFormattingWithLargeText() throws {
        
        var formatting = Formatting()
        formatting.titles.sizePercent = 1
        
        runFormattingTests( with: formatting )

    }
    
    func testFormattingWithSmallMargins() throws {
        
        var formatting = Formatting()
        formatting.margins.sizePercent = 0
        
        runFormattingTests( with: formatting )

    }


    func testFormattingWithLargeMargins() throws {
        
        var formatting = Formatting()
        formatting.margins.sizePercent = 1
        
        runFormattingTests( with: formatting )

    }

    
    
    func testFormattingTitlesBelow() throws {
        
        var formatting = Formatting()
        formatting.titles.positionTextAtTop = false
        
        runFormattingTests( with: formatting )

    }



    func runFormattingTests(with formatting: Formatting, testName: String = #function) {
        
        //We have set the autofill launch argument, so we already have some photos & titles
        //selectPhotosFromMainMenu(count: 9, snapshotID: nil, recheckSelections: false)
        
        //Layout: Select A4 page size - any layout
        selectLayout(pageSize: .a4, orientation: .portrait, layout: PageLayout(width: 2, height: 3))
        
        navigateToFormattingScreen()
        
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
        
        //Go back to main menu
        returnToMainMenu()

    }
}
