//
//  PECS_MakerUITests.swift
//  PECS MakerUITests
//
//  Created by Andy on 24/09/2021.
//

import XCTest

class ScreenshotSingleImageTests: PECSTestsBase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    override func setLaunchArguments() {
        super.setLaunchArguments()
        app.launchArguments.append(LaunchArguments.autoFillSingle)
    }
    
    @MainActor func testEndToEndSingleImage() throws {

        //print("Is Spanish? \(isSpanish)")
        
        let photoCount = 1
        
        //Photos: Select images. This is just for the purposes of
        //the screenshot. In actuality, this will be overwritten
        //because we have passed the autofill Launch argument.
        //selectPhotosFromMainMenu(count: photoCount, recheckSelections: false)
        
        //Layout: Select A4 page size - any layout
        selectLayout(pageSize: .a4, orientation: XCUIDevice.isiPad ? .landscape : .portrait, layout: PageLayout(width: 3, height: 3), snapshotID: ScreenshotNames.layoutScreen)
        
        //Titles: We have set the autofill launch argument, so in reality
        //these will be auto-filled, and we don't want the titles to be
        //typed in, but we need to go into the screen so that the tickbox is there
        completeTitles(count: photoCount, snapshotID: nil, isAutoFilled: true)
        
        //Preview and Print, selecting the option to repeat a single image.
        //This is the only step where we want a screenshot (the others come
        //from testEndToEndMultipleImages
        completePreviewAndPrintBySaving(repeatSingleImage: true, snapshotID: ScreenshotNames.previewScreenRepeatImage)
        
        
                        
    }

    
}
